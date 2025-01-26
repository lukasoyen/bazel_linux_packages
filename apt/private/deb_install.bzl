"repository rule for extracting debian archives into a install dir"

load("//apt/private:util.bzl", "util")

def _correct_symlinks(rctx, host_tar, path):
    cmd = [host_tar, "-tvf", str(path)]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to list data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))
    for line in result.stdout.splitlines():
        if line.startswith("l"):  # symbolic link
            (name, _, target) = line.split(" ")[-3:]
            if target.startswith("/"):  # symlinking into the host filesystem
                rctx.delete(name)

                # we get something like './some/path/lib.so` from `tar -tv`
                # so we subtract 2 for the leading `.` and the filename
                levels = [".." for _ in range(len(name.split("/")) - 2)]
                new_target = "/".join(levels) + target

                # preferably this would be a`rctx.symlink(new_target, name)`
                # but that normalizes `new_target`
                rctx.execute(["ln", "-s", new_target, name])

def _extract_data_file(rctx, host_tar, path):
    cmd = [host_tar, "-xf", str(path)]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to extract data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))
    _correct_symlinks(rctx, host_tar, path)

def _deb_install_impl(rctx):
    host_tar = util.get_host_tool(rctx, "bsd_tar", "tar")

    index = json.decode(rctx.read(util.get_repo_path(rctx, rctx.attr.source, "index.json")))

    # otherwise assume we are in the initial lockfile generation
    if index:
        if rctx.attr.architecture not in index:
            fail(
                "Misconfigured `sysroot()`. Can not find the provided architecture {} in packages from {}".format(rctx.attr.architecture, rctx.attr.source),
            )

        for package in index[rctx.attr.architecture]:
            path = rctx.path(Label(package))
            rctx.report_progress("Extracting data from package {}/{}".format(path.dirname.basename, path.basename))
            _extract_data_file(rctx, host_tar, path)

    rctx.template(
        "BUILD.bazel",
        rctx.attr.build_file,
        {"{target_name}": rctx.attr.source},
        executable = False,
    )

deb_install = repository_rule(
    implementation = _deb_install_impl,
    attrs = {
        "apparent_name": attr.string(mandatory = True),
        "architecture": attr.string(mandatory = True),
        "source": attr.string(mandatory = True),
        "build_file": attr.label(mandatory = True),
    },
)
