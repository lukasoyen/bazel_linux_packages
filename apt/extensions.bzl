"apt extensions"

load("//apt/private:deb_download.bzl", "deb_download")
load("//apt/private:deb_install.bzl", "deb_install")
load("//apt/private:deb_repository.bzl", "deb_repository")

def _hash_inputs(tag):
    values = dict()
    for attr in dir(tag):
        values[attr] = getattr(tag, attr)
    return "inputs-{}".format(hash(json.encode(values)))

def _collect_architectures(mapping, repos):
    result = list()
    for repo in repos:
        result.extend(mapping.get(repo, ()))
    return result

def _linux_toolchains_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []

    hash_by_source = dict()
    arch_by_source = dict()
    arch_by_download = dict()

    for mod in module_ctx.modules:
        for source in mod.tags.source:
            hash_by_source[source.name] = _hash_inputs(source)
            arch_by_source[source.name] = list(source.architectures)

            deb_repository.fetch(
                name = source.name,
                suites = source.suites,
                architectures = source.architectures,
                components = source.components,
                uri = source.uri,
            )
        for download in mod.tags.download:
            input_hash = "inputs-{}".format(hash("-".join([hash_by_source[s] for s in download.sources])))
            architectures = (
                download.architectures if download.architectures else _collect_architectures(arch_by_source, download.sources)
            )
            arch_by_download[download.name] = architectures

            deb_download.index(
                name = download.name + "_index",
                apparent_name = download.name + "_index",
                sources = download.sources,
                architectures = architectures,
                packages = download.packages,
                lockfile = download.lockfile,
                resolve_transitive = download.resolve_transitive,
                input_hash = input_hash,
            )
            deb_download.download(
                name = download.name,
                apparent_name = download.name,
                lockfile = download.lockfile,
                input_hash = input_hash,
                install_names = [install.name for install in mod.tags.install],
            )

        for install in mod.tags.install:
            architectures = (
                [install.architecture] if install.architecture else _collect_architectures(arch_by_download, [install.source])
            )
            if len(architectures) > 1:
                fail("Please set a `architecture` attribute for {}".format(install.name))

            deb_install(
                name = install.name,
                apparent_name = install.name,
                architecture = architectures[0],
                source = install.source,
            )

            if mod.is_root:
                if module_ctx.is_dev_dependency(install):
                    root_direct_dev_deps.append(install.name)
                else:
                    root_direct_deps.append(install.name)

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
            doc = "The lock file to use for the index (it is fine for the file to not exist yet)",
            mandatory = True,
        ),
        "resolve_transitive": attr.bool(
            doc = "Whether dependencies of dependencies should be " +
                  "resolved and added to the lockfile.",
            default = True,
        ),
    },
)
install = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            mandatory = True,
        ),
        "architecture": attr.string(
            doc = "Architectures for which to create the install (defaults to single value architecture from `source` if not given",
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
        "install": install,
    },
)
