"apt extensions"

load("//apt/private:create_sysroot.bzl", "create_sysroot")
load("//apt/private:deb_download.bzl", "deb_download")
load("//apt/private:deb_repository.bzl", "deb_repository")

def _collect_architectures(mapping, repos):
    result = list()
    for repo in repos:
        result.extend(mapping.get(repo, ()))
    return result

def _linux_toolchains_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []

    arch_by_source = dict()
    arch_by_download = dict()

    for mod in module_ctx.modules:
        for source in mod.tags.source:
            arch_by_source[source.name] = list(source.architectures)

            deb_repository.fetch(
                name = source.name,
                suites = source.suites,
                architectures = source.architectures,
                components = source.components,
                uri = source.uri,
            )
        for download in mod.tags.download:
            architectures = (
                download.architectures if download.architectures else _collect_architectures(arch_by_source, download.sources)
            )
            arch_by_download[download.name] = architectures

            deb_download(
                name = download.name,
                install_name = download.name,
                sources = download.sources,
                architectures = architectures,
                packages = download.packages,
                lockfile = download.lockfile,
                resolve_transitive = download.resolve_transitive,
            )

        for sysroot in mod.tags.sysroot:
            architectures = (
                [sysroot.architecture] if sysroot.architecture else _collect_architectures(arch_by_download, [sysroot.source])
            )
            if len(architectures) > 1:
                fail("Please set a `architecture` attribute for {}".format(sysroot.name))

            create_sysroot(
                name = sysroot.name,
                install_name = sysroot.name,
                architecture = architectures[0],
                source = sysroot.source,
            )

            if mod.is_root:
                if module_ctx.is_dev_dependency(sysroot):
                    root_direct_dev_deps.append(sysroot.name)
                else:
                    root_direct_deps.append(sysroot.name)

    return module_ctx.extension_metadata(
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

source = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            default = "source",
        ),
        "suites": attr.string_list(
            doc = "Deb suites to download the packages from (see DEB822)",
            mandatory = True,
        ),
        "architectures": attr.string_list(
            doc = "Architectures for which to download the package lists (see DEB822)",
            mandatory = True,
        ),
        "components": attr.string_list(
            doc = "Deb components to download the packages from (see DEB822)",
            mandatory = True,
        ),
        "uri": attr.string(
            doc = "Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)",
            mandatory = True,
        ),
    },
)

download = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            default = "download",
        ),
        "sources": attr.string_list(
            doc = "source() repositories to download packages from",
            default = ["source"],
        ),
        "architectures": attr.string_list(
            doc = "Architectures for which to download packages (defaults to architectures from `sources` if not given",
        ),
        "packages": attr.string_list(
            doc = "Packages to download",
            mandatory = True,
        ),
        "lockfile": attr.label(
            doc = "The lock file to use for the index.",
        ),
        "resolve_transitive": attr.bool(
            doc = "Whether dependencies of dependencies should be " +
                  "resolved and added to the lockfile.",
            default = True,
        ),
    },
)
sysroot = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            mandatory = True,
        ),
        "architecture": attr.string(
            doc = "Architectures for which to create the sysroot (defaults to single value architecture from `source` if not given",
        ),
        "source": attr.string(
            doc = "download() repositorie to unpack packages from",
            default = "download",
        ),
    },
)

apt = module_extension(
    implementation = _linux_toolchains_extension,
    tag_classes = {
        "source": source,
        "download": download,
        "sysroot": sysroot,
    },
)
