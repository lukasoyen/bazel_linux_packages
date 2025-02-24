"""
# Extension for downloading and extracting Debian/Ubuntu packages.

## Usage
Place the following in your `MODULE.bazel`. Then:
- run `bazel run @busybox//:lock` to create a lockfile and
- run `bazel run @busybox//:bin/busybox` to download/extract the package and run the binary.

```py
apt = use_extension("@linux_packages//apt:extensions.bzl", "apt")
apt.source(
    architectures = ["amd64"],
    components = ["main"],
    suites = ["focal"],
    uri = "https://snapshot.ubuntu.com/ubuntu/20250219T154000Z",
)
apt.download(
    lockfile = "//:focal.lock.json",
    packages = ["busybox"],
)
apt.install(name = "busybox")
use_repo(apt, "busybox")
```
"""

load("//apt/private:deb_download.bzl", "deb_download")
load("//apt/private:deb_install.bzl", "deb_install")
load("//apt/private:deb_repository.bzl", "deb_repository")

def _hash_inputs(tag):
    values = dict()
    for attr in dir(tag):
        values[attr] = str(getattr(tag, attr))
    return "inputs-{}".format(hash(json.encode(values)))

def _collect_architectures(mapping, repos):
    result = list()
    for repo in repos:
        if repo not in mapping:
            fail("Source {} not found. Available: {}".format(repo, ", ".join(mapping.keys())))
        result.extend(mapping[repo])
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
            architectures = (
                download.architectures if download.architectures else _collect_architectures(arch_by_source, download.sources)
            )
            arch_by_download[download.name] = architectures

            input_hash = "inputs-{}-{}".format(
                hash("-".join([hash_by_source[s] for s in download.sources])),
                _hash_inputs(download),
            )

            deb_download.index(
                name = download.name + "_index",
                sources = download.sources,
                architectures = architectures,
                packages = download.packages,
                lockfile = download.lockfile,
                resolve_transitive = download.resolve_transitive,
                input_hash = input_hash,
            )
            deb_download.download(
                name = download.name,
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
                architecture = architectures[0],
                source = install.source,
                fix_with_patchelf = install.fix_with_patchelf,
                patchelf_dirs = install.patchelf_dirs + install.extra_patchelf_dirs,
                build_file = install.build_file,
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
    doc = """
    Set the Debian/Ubuntu repository to download from.

    This will create an internal repository that contains the extracted
    Ubuntu/Debian package index files.

    Parameters roughly follow the
    [DEB822](https://manpages.debian.org/unstable/apt/sources.list.5.en.html#DEB822-STYLE_FORMAT).
    This allows you copy and adapt from the sources.list.

    For example
    ```
    Types: deb
    URIs: http://deb.debian.org/debian
    Suites: trixie
    Components: main
    Architectures: amd64 armel
    ```

    would be translated into
    ```
    apt.source(
        architectures = ["amd64", "armel"],
        components = ["main"],
        suites = ["trixie"],
        uri = "http://deb.debian.org/debian",
    )
    ```

    It is strogly advised to use archive URLs to ensure stability of the
    retrieved package index files to be able to re-generate the same lockfiles.
    - Ubuntu: https://snapshot.ubuntu.com/ubuntu/20250115T150000Z
    - Debian: https://snapshot.debian.org/archive/debian/20250115T150000Z

    Multiple `source()` tags are allowed but need unique names. The
    corresponding `download()` tags need to then refer to them by the `sources`
    attribute.
    """,
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
    doc = """
    Download a set of `packages` from specified `sources`.

    This will create two internal repositories. One will contain a generated
    lockfile, the other will contain the downloaded `*.deb` archives and their
    extracted files.

    The `lockfile` attribute is mandatory, but does not need to exist during the
    initial setup. If the attribute is set to a non-existing file a mostly empty
    repository that only exposes the target to copy the lockfile into the
    workspace is created.

    Multiple `download()` tags are allowed but need unique names. The
    corresponding `source()` tag needs to be specified by the `sources`
    attribute. The corresponding `install()` tags need to then refer to them by
    the `source` attribute.
    """,
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
            doc = "Architectures for which to download packages (defaults to architectures from `sources` if not given)",
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
    doc = """
    Install the contents of the downloaded `*.deb` data archives.

    This will create the user facing repository containing the files from
    "installing" the `*.deb` packages. The packages are only extracted, no
    install hooks will be executed.

    In most cases you need to consider how to handle library paths. See the
    [Handle Library Paths](../README.md#handle-library-paths) for details.

    Multiple `install()` tags are allowed but need unique names. The
    corresponding `download()` tag needs to be specified by the `source`
    attribute.
    """,
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            mandatory = True,
        ),
        "architecture": attr.string(
            doc = "Architectures for which to create the install (defaults to single value architecture from `source` if not given)",
        ),
        "source": attr.string(
            doc = "download() repositories to unpack packages from",
            default = "download",
        ),
        "fix_with_patchelf": attr.bool(
            doc = "Whether to fix the RPATH/interpreter of executables/libraries using `patchelf`",
            default = False,
        ),
        "patchelf_dirs": attr.string_list(
            doc = """
            Paths to inspect for executable/library files to fix with `patchelf`

            Note that this will not recursively inspect subdirectories.
            "{arch}" will be replaced by the value as returned by `uname -m`).
            """,
            default = [
                "lib/{arch}-linux-gnu",
                "usr/lib/{arch}-linux-gnu",
                "usr/bin",
            ],
        ),
        "extra_patchelf_dirs": attr.string_list(
            doc = """
            Additional paths to inspect for executable/library files to fix with `patchelf`

            Note that this will not recursively inspect subdirectories.
            "{arch}" will be replaced by the value as returned by `uname -m`).
            """,
            default = [],
        ),
        "build_file": attr.label(
            doc = "Experimental: BUILD.bazel template for the generated install dir.",
            default = "//apt:install.BUILD.bazel.tmpl",
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
