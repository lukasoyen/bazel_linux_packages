<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# Extension for downloading and extracting Debian/Ubuntu packages.

## Usage
Place the following in your `MODULE.bazel`. Then:
- run `bazel run @busybox//:lock` to create a lockfile and
- run `bazel run @busybox//:bin/busybox` to download/extract the package and run the binary.

```py
apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")
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

<a id="apt"></a>

## apt

<pre>
apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")
apt.source(<a href="#apt.source-name">name</a>, <a href="#apt.source-architectures">architectures</a>, <a href="#apt.source-components">components</a>, <a href="#apt.source-suites">suites</a>, <a href="#apt.source-uri">uri</a>)
apt.download(<a href="#apt.download-name">name</a>, <a href="#apt.download-architectures">architectures</a>, <a href="#apt.download-lockfile">lockfile</a>, <a href="#apt.download-packages">packages</a>, <a href="#apt.download-resolve_transitive">resolve_transitive</a>, <a href="#apt.download-sources">sources</a>)
apt.install(<a href="#apt.install-name">name</a>, <a href="#apt.install-add_files">add_files</a>, <a href="#apt.install-architecture">architecture</a>, <a href="#apt.install-build_file">build_file</a>, <a href="#apt.install-extra_patchelf_dirs">extra_patchelf_dirs</a>,
            <a href="#apt.install-fix_absolute_interpreter_with_patchelf">fix_absolute_interpreter_with_patchelf</a>, <a href="#apt.install-fix_relative_interpreter_with_patchelf">fix_relative_interpreter_with_patchelf</a>,
            <a href="#apt.install-fix_rpath_with_patchelf">fix_rpath_with_patchelf</a>, <a href="#apt.install-patchelf_dirs">patchelf_dirs</a>, <a href="#apt.install-source">source</a>)
</pre>


**TAG CLASSES**

<a id="apt.source"></a>

### source

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

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.source-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"source"`  |
| <a id="apt.source-architectures"></a>architectures |  Architectures for which to download the package lists (see DEB822)   | List of strings | required |  |
| <a id="apt.source-components"></a>components |  Deb components to download the packages from (see DEB822)   | List of strings | required |  |
| <a id="apt.source-suites"></a>suites |  Deb suites to download the packages from (see DEB822)   | List of strings | required |  |
| <a id="apt.source-uri"></a>uri |  Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)   | String | required |  |

<a id="apt.download"></a>

### download

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

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.download-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"download"`  |
| <a id="apt.download-architectures"></a>architectures |  Architectures for which to download packages (defaults to architectures from `sources` if not given)   | List of strings | optional |  `[]`  |
| <a id="apt.download-lockfile"></a>lockfile |  The lock file to use for the index (it is fine for the file to not exist yet)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apt.download-packages"></a>packages |  Packages to download   | List of strings | required |  |
| <a id="apt.download-resolve_transitive"></a>resolve_transitive |  Whether dependencies of dependencies should be resolved and added to the lockfile.   | Boolean | optional |  `True`  |
| <a id="apt.download-sources"></a>sources |  source() repositories to download packages from   | List of strings | optional |  `["source"]`  |

<a id="apt.install"></a>

### install

Install the contents of the downloaded `*.deb` data archives.

This will create the user facing repository containing the files from
"installing" the `*.deb` packages. The packages are only extracted, no
install hooks will be executed.

In most cases you need to consider how to handle library paths. See the
[Handle Library Paths](../README.md#handle-library-paths) for details.

Multiple `install()` tags are allowed but need unique names. The
corresponding `download()` tag needs to be specified by the `source`
attribute.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.install-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.install-add_files"></a>add_files |  Experimental: add files to the install dir.<br><br>The keys are paths into the install dir. The label may only refer to a single file.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="apt.install-architecture"></a>architecture |  Architectures for which to create the install (defaults to single value architecture from `source` if not given)   | String | optional |  `""`  |
| <a id="apt.install-build_file"></a>build_file |  Experimental: BUILD.bazel template for the generated install dir.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_linux_packages//apt:install.BUILD.bazel.tmpl"`  |
| <a id="apt.install-extra_patchelf_dirs"></a>extra_patchelf_dirs |  Additional paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `[]`  |
| <a id="apt.install-fix_absolute_interpreter_with_patchelf"></a>fix_absolute_interpreter_with_patchelf |  Whether to absolutize the interpreter while fixing executables/libraries using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_relative_interpreter_with_patchelf`.<br><br>Note that this will destroy remote-executability and cache-reuse across different systems if the path to the source/build directory is not exactly the same.   | Boolean | optional |  `False`  |
| <a id="apt.install-fix_relative_interpreter_with_patchelf"></a>fix_relative_interpreter_with_patchelf |  Whether to fix the interpreter of executables using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_absolute_interpreter_with_patchelf`.   | Boolean | optional |  `False`  |
| <a id="apt.install-fix_rpath_with_patchelf"></a>fix_rpath_with_patchelf |  Whether to fix the RPATH of executables/libraries using `patchelf`   | Boolean | optional |  `False`  |
| <a id="apt.install-patchelf_dirs"></a>patchelf_dirs |  Paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `["lib/{arch}-linux-gnu", "usr/lib/{arch}-linux-gnu", "usr/bin"]`  |
| <a id="apt.install-source"></a>source |  download() repositories to unpack packages from   | String | optional |  `"download"`  |


