"repository rule for downloading and uncompressing debian archive files"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//apt/private:deb_repository.bzl", "deb_repository")
load("//apt/private:deb_resolver.bzl", "dependency_resolver")
load("//apt/private:lockfile.bzl", "lockfile")
load("//apt/private:util.bzl", "util")
load("//apt/private:version_constraint.bzl", "version_constraint")

def _resolve(rctx, input_hash, resolver, architectures, packages, include_transitive):
    lockf = lockfile.empty(rctx, input_hash)
    for arch in architectures:
        rctx.report_progress("Resolving package constraints for {}".format(arch))
        dep_constraint_set = {}
        for dep_constraint in packages:
            if dep_constraint in dep_constraint_set:
                fail("Duplicate package, {}. Please remove it from your packages".format(dep_constraint))
            dep_constraint_set[dep_constraint] = True

            constraint = version_constraint.parse_depends(dep_constraint).pop()

            rctx.report_progress("Resolving %s" % dep_constraint)
            (package, dependencies, unmet_dependencies) = resolver.resolve_all(
                name = constraint["name"],
                version = constraint["version"],
                arch = arch,
                include_transitive = include_transitive,
            )

            if not package:
                fail("Unable to locate package `%s`" % dep_constraint)

            if len(unmet_dependencies):
                # buildifier: disable=print
                util.warning(rctx, "Following dependencies could not be resolved for %s: %s" % (constraint["name"], ",".join([up[0] for up in unmet_dependencies])))

            lockf.add_package(package, arch)

            for dep in dependencies:
                lockf.add_package(dep, arch)
                lockf.add_package_dependency(package, dep, arch)
    return lockf

_INDEX_BUILD_TMPL = """
filegroup(
    name = "lockfile",
    srcs = ["lock.json"],
    tags = ["manual"],
)

sh_binary(
    name = "lock",
    srcs = ["copy.sh"],
    data = ["lock.json"],
    tags = ["manual"],
    args = ["$(location :lock.json)"],
    visibility = ["//visibility:public"]
)
"""

def _deb_index_impl(rctx):
    workspace_relative_path = "{}{}".format(
        "{}/".format(rctx.attr.lockfile.package) if rctx.attr.lockfile.package else "",
        rctx.attr.lockfile.name,
    )

    rctx.file(
        "copy.sh",
        rctx.read(rctx.attr._copy_sh_tmpl).format(
            repo_name = rctx.attr.apparent_name.removesuffix("_index"),
            lock_label = rctx.attr.lockfile or workspace_relative_path,
            workspace_relative_path = workspace_relative_path,
        ),
        executable = True,
    )

    indices = [util.get_repo_path(rctx, s, "index.json") for s in rctx.attr.sources]
    repository = deb_repository.new(rctx, indices)
    resolver = dependency_resolver.new(repository)

    lockf = _resolve(
        rctx,
        rctx.attr.input_hash,
        resolver,
        rctx.attr.architectures,
        rctx.attr.packages,
        rctx.attr.resolve_transitive,
    )
    lockf.write("lock.json")

    rctx.file(
        "BUILD.bazel",
        _INDEX_BUILD_TMPL,
        executable = False,
    )

_BUILD_TMPL = """
alias(
    name="lock",
    actual="@@{}_index//:lock",
    visibility = ["//visibility:public"]
)
"""

def _find_data_file(rctx, folder, package_key):
    # Debian data.tar files can be:
    #  - .tar uncompressed, supported since dpkg 1.10.24
    #  - .tar compressed with
    #    *  gzip: .gz
    #    * bzip2: .bz2, supported since dpkg 1.10.24
    #    *  lzma: .lzma, supported since dpkg 1.13.25
    #    *    xz: .xz, supported since dpkg 1.15.6
    #    *  zstd: .zst, supported since dpkg 1.21.18
    for ext in (".zst", ".xz", ".lzma", ".bz2", ".gz", ""):
        path = "{}/{}/data.tar{}".format(folder, package_key, ext)
        if rctx.path(path).exists:
            return path
    fail("{}: unable to find data file for {}".format(rctx.name, package_key))

def _decompress_data_file(rctx, host_zstd, path):
    (output, ext) = paths.split_extension(path)
    if ext == ".bzip2":
        fail("{}: unsupported bzip2 compression for {}".format(rctx.name, path))

    cmd = [host_zstd, "--decompress", "--force", "-o", output, path]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to decompress data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))
    return path

def _extract_packages(rctx, lockf):
    host_zstd = util.get_host_tool(rctx, "zstd", "zstd")
    data_files = dict()

    package_folder = "packages"
    for (package) in lockf.packages():
        package_key = lockfile.make_package_key(
            package["name"],
            package["version"],
            package["arch"],
        )
        rctx.report_progress("Downloading package {}".format(package["name"]))
        rctx.download_and_extract(
            package["url"],
            sha256 = package["sha256"],
            output = "{}/{}".format(package_folder, package_key),
        )

        path = _find_data_file(rctx, package_folder, package_key)
        if not path.endswith(".tar"):
            path = _decompress_data_file(rctx, host_zstd, path)

        arch = package["arch"]
        if arch not in data_files:
            data_files[arch] = []

        data_files[arch].append("@@{}//:{}".format(rctx.name, path))
    return data_files

def _deb_download_impl(rctx):
    data_files = []

    # Ensure the repository gets restarted once the lockfile exists.
    rctx.watch(rctx.attr.lockfile)

    lock_cmds = (
        ["bazel run @{}//:lock".format(n) for n in rctx.attr.install_names] if rctx.attr.install_names else ["@{}//:lock".format(rctx.attr.apparent_name)]
    )
    if not rctx.path(rctx.attr.lockfile).exists:
        util.warning(
            rctx,
            "\n".join(["Lockfiles need to be created. Please run:"] + lock_cmds),
        )
    else:
        lockf = lockfile.from_json(rctx, rctx.read(rctx.attr.lockfile))
        if lockf.input_hash() != rctx.attr.input_hash:
            util.warning(
                rctx,
                "\n".join(["Lockfiles need to be recreated. Please run:"] + lock_cmds),
            )
        else:
            data_files = _extract_packages(rctx, lockf)

    rctx.file(
        "index.json",
        json.encode_indent(data_files),
        executable = False,
    )
    rctx.file(
        "BUILD.bazel",
        _BUILD_TMPL.format(rctx.attr.name),
        executable = False,
    )

_deb_index = repository_rule(
    implementation = _deb_index_impl,
    attrs = {
        "apparent_name": attr.string(mandatory = True),
        "sources": attr.string_list(mandatory = True),
        "architectures": attr.string_list(mandatory = True),
        "packages": attr.string_list(mandatory = True),
        "lockfile": attr.label(mandatory = True),
        "resolve_transitive": attr.bool(default = True),
        "input_hash": attr.string(mandatory = True),
        "_copy_sh_tmpl": attr.label(
            default = "//apt/private:copy.sh.tmpl",
            doc = "INTERNAL, DO NOT USE",
        ),
    },
)
_deb_download = repository_rule(
    implementation = _deb_download_impl,
    attrs = {
        "apparent_name": attr.string(mandatory = True),
        "lockfile": attr.label(mandatory = True),
        "input_hash": attr.string(mandatory = True),
        "install_names": attr.string_list(mandatory = True),
    },
)

deb_download = struct(
    index = _deb_index,
    download = _deb_download,
)
