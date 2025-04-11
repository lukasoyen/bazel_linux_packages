"""
# Extension for downloading and extracting Debian/Ubuntu packages.

## Usage
Place the following in your `MODULE.bazel`. Then:
- run `bazel run @busybox//:lock` to create a lockfile and
- run `bazel run @busybox//:bin/busybox` to download/extract the package and run the binary.

```py
apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")
apt.ubuntu(
    name = "busybox",
    lockfile = "//:focal.lock.json",
    packages = ["busybox"],
    suites = ["focal"],
)
use_repo(apt, "busybox")
```
"""

load("//apt/private:deb_download.bzl", "deb_download")
load("//apt/private:deb_install.bzl", "deb_install")
load("//apt/private:deb_repository.bzl", "deb_repository")

def _hash_inputs(tag):
    values = dict()
    for attr in ("suites", "architectures", "components", "uri", "packages"):
        values[attr] = str(getattr(tag, attr))
    return "inputs-{}".format(hash(json.encode(values)))

def _apt_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []

    for mod in module_ctx.modules:
        for tag in ("download", "ubuntu", "debian"):
            for cfg in getattr(mod.tags, tag):
                if cfg.fix_relative_interpreter_with_patchelf and cfg.fix_absolute_interpreter_with_patchelf:
                    fail("Can not set both `fix_relative_interpreter_with_patchelf = True` and `fix_absolute_interpreter_with_patchelf = True` for {}".format(cfg.name))

                input_hash = _hash_inputs(cfg)

                deb_repository.fetch(
                    name = cfg.name + "_repository",
                    suites = cfg.suites,
                    architectures = cfg.architectures,
                    components = cfg.components,
                    uri = cfg.uri,
                )

                deb_download.index(
                    name = cfg.name + "_index",
                    source = cfg.name + "_repository",
                    architectures = cfg.architectures,
                    packages = cfg.packages,
                    lockfile = cfg.lockfile,
                    resolve_transitive = cfg.resolve_transitive,
                    input_hash = input_hash,
                )

                for arch in cfg.architectures:
                    if len(cfg.architectures) > 1:
                        name = "{}_{}".format(cfg.name, arch)
                    else:
                        name = cfg.name

                    deb_download.download(
                        name = name + "_download",
                        index = cfg.name + "_index",
                        architecture = arch,
                        lockfile = cfg.lockfile,
                        input_hash = input_hash,
                        install_name = name,
                    )

                    deb_install(
                        name = name,
                        architecture = arch,
                        source = name + "_download",
                        fix_rpath_with_patchelf = cfg.fix_rpath_with_patchelf,
                        fix_relative_interpreter_with_patchelf = cfg.fix_relative_interpreter_with_patchelf,
                        fix_absolute_interpreter_with_patchelf = cfg.fix_absolute_interpreter_with_patchelf,
                        patchelf_dirs = cfg.patchelf_dirs + cfg.extra_patchelf_dirs,
                        add_files = cfg.add_files,
                        build_file = cfg.build_file,
                    )

                    if mod.is_root:
                        if module_ctx.is_dev_dependency(cfg):
                            root_direct_dev_deps.append(name)
                        else:
                            root_direct_deps.append(name)

    return module_ctx.extension_metadata(
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

ATTR = {
    "name": attr.string(
        doc = "Base name of the generated repository",
        mandatory = True,
    ),
    "suites": attr.string_list(
        doc = "Deb suites to download the packages from (see DEB822)",
        mandatory = True,
    ),
    "architectures": attr.string_list(
        doc = "Architectures for which to download the package lists (see DEB822)",
        default = ["amd64"],
    ),
    "components": attr.string_list(
        doc = "Deb components to download the packages from (see DEB822)",
        default = ["main"],
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
        doc = "Whether dependencies of dependencies should be resolved and added to the lockfile.",
        default = True,
    ),
    "fix_rpath_with_patchelf": attr.bool(
        doc = "Whether to fix the RPATH of executables/libraries using `patchelf`",
        default = False,
    ),
    "fix_relative_interpreter_with_patchelf": attr.bool(
        doc = """
            Whether to fix the interpreter of executables using `patchelf`

            Only has an effect if `fix_rpath_with_patchelf` is set to `True`.
            Mutually exclusive with `fix_absolute_interpreter_with_patchelf`.
            """,
        default = False,
    ),
    "fix_absolute_interpreter_with_patchelf": attr.bool(
        doc = """
            Whether to absolutize the interpreter while fixing executables/libraries using `patchelf`

            Only has an effect if `fix_rpath_with_patchelf` is set to `True`.
            Mutually exclusive with `fix_relative_interpreter_with_patchelf`.

            Note that this will destroy remote-executability and cache-reuse across different systems
            if the path to the source/build directory is not exactly the same.
            """,
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
    "add_files": attr.string_keyed_label_dict(
        doc = """
            Experimental: add files to the install dir.

            The keys are paths into the install dir. The label may
            only refer to a single file.
            "{arch}" in keys will be replaced by the value as returned by `uname -m`).
            """,
        allow_files = True,
        default = {},
    ),
    "build_file": attr.label(
        doc = "Experimental: BUILD.bazel template for the generated install dir.",
        default = "//apt:install.BUILD.bazel.tmpl",
    ),
}

DOC = """
Download/extract a set of `packages` from the Ubuntu/Debian repositories.

The packages are only extracted, no install hooks will be executed.
In most cases you need to consider how to handle library paths. See the
[Handle Library Paths](../README.md#handle-library-paths) for details.

The `lockfile` attribute is mandatory, but does not need to exist during the
initial setup. If the attribute is set to a non-existing file a mostly empty
repository that only exposes the target to copy the lockfile into the
workspace is created.

The `suites`, `architectures`, `components`, `uri` parameters roughly follow
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
apt.{tag}(
    ...
    architectures = ["amd64", "armel"],
    components = ["main"],
    suites = ["trixie"],
    uri = "http://deb.debian.org/debian",
    ...
)
```

It is strogly advised to use archive URLs to ensure stability of the
retrieved package index files to be able to re-generate the same lockfiles.
- Ubuntu: https://snapshot.ubuntu.com/ubuntu/20250115T150000Z
- Debian: https://snapshot.debian.org/archive/debian/20250115T150000Z


Multiple `{tag}()` tags are allowed but need unique names.
"""

download = tag_class(
    doc = DOC.format(tag = "download"),
    attrs = ATTR | {
        "uri": attr.string(
            doc = "Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)",
            mandatory = True,
        ),
    },
)
ubuntu = tag_class(
    doc = DOC.format(tag = "ubuntu"),
    attrs = ATTR | {
        "uri": attr.string(
            doc = "Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)",
            default = "https://snapshot.ubuntu.com/ubuntu/20250219T154000Z",
        ),
    },
)
debian = tag_class(
    doc = DOC.format(tag = "debian"),
    attrs = ATTR | {
        "uri": attr.string(
            doc = "Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)",
            default = "https://snapshot.debian.org/archive/debian/20250201T023325Z",
        ),
    },
)

apt = module_extension(
    implementation = _apt_extension,
    tag_classes = {
        "download": download,
        "ubuntu": ubuntu,
        "debian": debian,
    },
)
