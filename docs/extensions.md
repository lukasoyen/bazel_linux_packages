<!-- Generated with Stardoc: http://skydoc.bazel.build -->

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

<a id="apt"></a>

## apt

<pre>
apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")
apt.index_integrity(<a href="#apt.index_integrity-integrities">integrities</a>)
apt.source(<a href="#apt.source-name">name</a>, <a href="#apt.source-architectures">architectures</a>, <a href="#apt.source-components">components</a>, <a href="#apt.source-suites">suites</a>, <a href="#apt.source-uri">uri</a>)
apt.download(<a href="#apt.download-name">name</a>, <a href="#apt.download-add_files">add_files</a>, <a href="#apt.download-architectures">architectures</a>, <a href="#apt.download-build_file">build_file</a>, <a href="#apt.download-extra_patchelf_dirs">extra_patchelf_dirs</a>,
             <a href="#apt.download-fix_absolute_interpreter_with_patchelf">fix_absolute_interpreter_with_patchelf</a>, <a href="#apt.download-fix_relative_interpreter_with_patchelf">fix_relative_interpreter_with_patchelf</a>,
             <a href="#apt.download-fix_rpath_with_patchelf">fix_rpath_with_patchelf</a>, <a href="#apt.download-glob_excludes">glob_excludes</a>, <a href="#apt.download-glob_pattern">glob_pattern</a>, <a href="#apt.download-lockfile">lockfile</a>, <a href="#apt.download-packages">packages</a>, <a href="#apt.download-patchelf_dirs">patchelf_dirs</a>,
             <a href="#apt.download-post_install_cmd">post_install_cmd</a>, <a href="#apt.download-resolve_transitive">resolve_transitive</a>, <a href="#apt.download-sources">sources</a>)
apt.ubuntu(<a href="#apt.ubuntu-name">name</a>, <a href="#apt.ubuntu-add_files">add_files</a>, <a href="#apt.ubuntu-architectures">architectures</a>, <a href="#apt.ubuntu-build_file">build_file</a>, <a href="#apt.ubuntu-components">components</a>, <a href="#apt.ubuntu-extra_patchelf_dirs">extra_patchelf_dirs</a>,
           <a href="#apt.ubuntu-fix_absolute_interpreter_with_patchelf">fix_absolute_interpreter_with_patchelf</a>, <a href="#apt.ubuntu-fix_relative_interpreter_with_patchelf">fix_relative_interpreter_with_patchelf</a>,
           <a href="#apt.ubuntu-fix_rpath_with_patchelf">fix_rpath_with_patchelf</a>, <a href="#apt.ubuntu-glob_excludes">glob_excludes</a>, <a href="#apt.ubuntu-glob_pattern">glob_pattern</a>, <a href="#apt.ubuntu-lockfile">lockfile</a>, <a href="#apt.ubuntu-packages">packages</a>, <a href="#apt.ubuntu-patchelf_dirs">patchelf_dirs</a>,
           <a href="#apt.ubuntu-post_install_cmd">post_install_cmd</a>, <a href="#apt.ubuntu-resolve_transitive">resolve_transitive</a>, <a href="#apt.ubuntu-suites">suites</a>, <a href="#apt.ubuntu-uri">uri</a>)
apt.debian(<a href="#apt.debian-name">name</a>, <a href="#apt.debian-add_files">add_files</a>, <a href="#apt.debian-architectures">architectures</a>, <a href="#apt.debian-build_file">build_file</a>, <a href="#apt.debian-components">components</a>, <a href="#apt.debian-extra_patchelf_dirs">extra_patchelf_dirs</a>,
           <a href="#apt.debian-fix_absolute_interpreter_with_patchelf">fix_absolute_interpreter_with_patchelf</a>, <a href="#apt.debian-fix_relative_interpreter_with_patchelf">fix_relative_interpreter_with_patchelf</a>,
           <a href="#apt.debian-fix_rpath_with_patchelf">fix_rpath_with_patchelf</a>, <a href="#apt.debian-glob_excludes">glob_excludes</a>, <a href="#apt.debian-glob_pattern">glob_pattern</a>, <a href="#apt.debian-lockfile">lockfile</a>, <a href="#apt.debian-packages">packages</a>, <a href="#apt.debian-patchelf_dirs">patchelf_dirs</a>,
           <a href="#apt.debian-post_install_cmd">post_install_cmd</a>, <a href="#apt.debian-resolve_transitive">resolve_transitive</a>, <a href="#apt.debian-suites">suites</a>, <a href="#apt.debian-uri">uri</a>)
</pre>


**TAG CLASSES**

<a id="apt.index_integrity"></a>

### index_integrity

Optional tag to extend the list of integrity hashes for the package index URLs.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.index_integrity-integrities"></a>integrities |  URL -> integrity mapping for the package index URLs   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |

<a id="apt.source"></a>

### source

Define a Debian/Ubuntu repository to download from.

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
apt.source(
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


Multiple `source()` tags are allowed but need unique names.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.source-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.source-architectures"></a>architectures |  Architectures for which to download the package lists (see DEB822)   | List of strings | optional |  `["amd64"]`  |
| <a id="apt.source-components"></a>components |  Deb components to download the packages from (see DEB822)   | List of strings | optional |  `["main"]`  |
| <a id="apt.source-suites"></a>suites |  Deb suites to download the packages from (see DEB822)   | List of strings | required |  |
| <a id="apt.source-uri"></a>uri |  Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)   | String | required |  |

<a id="apt.download"></a>

### download

Download/extract a set of `packages` from the Ubuntu/Debian repositories.

The packages are only extracted, no install hooks will be executed.
In most cases you need to consider how to handle library paths. See the
[Handle Library Paths](../README.md#handle-library-paths) for details.

The `lockfile` attribute is mandatory, but does not need to exist during the
initial setup. If the attribute is set to a non-existing file a mostly empty
repository that only exposes the target to copy the lockfile into the
workspace is created.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.download-name"></a>name |  Base name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.download-add_files"></a>add_files |  Experimental: add files to the install dir.<br><br>The keys are paths into the install dir. The label may only refer to a single file. "{arch}" in keys will be replaced by the value as returned by `uname -m`).   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="apt.download-architectures"></a>architectures |  Architectures for which to create the install (defaults to architectures from `sources` if not given)   | List of strings | optional |  `[]`  |
| <a id="apt.download-build_file"></a>build_file |  Experimental: BUILD.bazel template for the generated install dir.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_linux_packages//apt:install.BUILD.bazel.tmpl"`  |
| <a id="apt.download-extra_patchelf_dirs"></a>extra_patchelf_dirs |  Additional paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `[]`  |
| <a id="apt.download-fix_absolute_interpreter_with_patchelf"></a>fix_absolute_interpreter_with_patchelf |  Whether to absolutize the interpreter while fixing executables/libraries using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_relative_interpreter_with_patchelf`.<br><br>Note that this will destroy remote-executability and cache-reuse across different systems if the path to the source/build directory is not exactly the same.   | Boolean | optional |  `False`  |
| <a id="apt.download-fix_relative_interpreter_with_patchelf"></a>fix_relative_interpreter_with_patchelf |  Whether to fix the interpreter of executables using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_absolute_interpreter_with_patchelf`.   | Boolean | optional |  `False`  |
| <a id="apt.download-fix_rpath_with_patchelf"></a>fix_rpath_with_patchelf |  Whether to fix the RPATH of executables/libraries using `patchelf`   | Boolean | optional |  `False`  |
| <a id="apt.download-glob_excludes"></a>glob_excludes |  Experimental: `glob()` pattern excludes for the default `build_file` template.   | List of strings | optional |  `["usr/share/man/**"]`  |
| <a id="apt.download-glob_pattern"></a>glob_pattern |  Experimental: `glob()` pattern for the default `build_file` template.   | List of strings | optional |  `["**"]`  |
| <a id="apt.download-lockfile"></a>lockfile |  The lock file to use for the index (it is fine for the file to not exist yet)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apt.download-packages"></a>packages |  Packages to download   | List of strings | required |  |
| <a id="apt.download-patchelf_dirs"></a>patchelf_dirs |  Paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `["lib/{arch}-linux-gnu", "usr/lib/{arch}-linux-gnu", "usr/bin"]`  |
| <a id="apt.download-post_install_cmd"></a>post_install_cmd |  Experimental: run a command after the install.<br><br>The keys are the unused, the values the command to run as given to `rctx.execute()`.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="apt.download-resolve_transitive"></a>resolve_transitive |  Whether dependencies of dependencies should be resolved and added to the lockfile.   | Boolean | optional |  `True`  |
| <a id="apt.download-sources"></a>sources |  Names of source() repositories to download packages from   | List of strings | required |  |

<a id="apt.ubuntu"></a>

### ubuntu

Download/extract a set of `packages` from the Ubuntu/Debian repositories.

The packages are only extracted, no install hooks will be executed.
In most cases you need to consider how to handle library paths. See the
[Handle Library Paths](../README.md#handle-library-paths) for details.

The `lockfile` attribute is mandatory, but does not need to exist during the
initial setup. If the attribute is set to a non-existing file a mostly empty
repository that only exposes the target to copy the lockfile into the
workspace is created.

Define a Debian/Ubuntu repository to download from.

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
apt.ubuntu(
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


Multiple `ubuntu()` tags are allowed but need unique names.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.ubuntu-name"></a>name |  Base name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.ubuntu-add_files"></a>add_files |  Experimental: add files to the install dir.<br><br>The keys are paths into the install dir. The label may only refer to a single file. "{arch}" in keys will be replaced by the value as returned by `uname -m`).   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="apt.ubuntu-architectures"></a>architectures |  Architectures for which to download the package lists (see DEB822)   | List of strings | optional |  `["amd64"]`  |
| <a id="apt.ubuntu-build_file"></a>build_file |  Experimental: BUILD.bazel template for the generated install dir.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_linux_packages//apt:install.BUILD.bazel.tmpl"`  |
| <a id="apt.ubuntu-components"></a>components |  Deb components to download the packages from (see DEB822)   | List of strings | optional |  `["main"]`  |
| <a id="apt.ubuntu-extra_patchelf_dirs"></a>extra_patchelf_dirs |  Additional paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `[]`  |
| <a id="apt.ubuntu-fix_absolute_interpreter_with_patchelf"></a>fix_absolute_interpreter_with_patchelf |  Whether to absolutize the interpreter while fixing executables/libraries using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_relative_interpreter_with_patchelf`.<br><br>Note that this will destroy remote-executability and cache-reuse across different systems if the path to the source/build directory is not exactly the same.   | Boolean | optional |  `False`  |
| <a id="apt.ubuntu-fix_relative_interpreter_with_patchelf"></a>fix_relative_interpreter_with_patchelf |  Whether to fix the interpreter of executables using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_absolute_interpreter_with_patchelf`.   | Boolean | optional |  `False`  |
| <a id="apt.ubuntu-fix_rpath_with_patchelf"></a>fix_rpath_with_patchelf |  Whether to fix the RPATH of executables/libraries using `patchelf`   | Boolean | optional |  `False`  |
| <a id="apt.ubuntu-glob_excludes"></a>glob_excludes |  Experimental: `glob()` pattern excludes for the default `build_file` template.   | List of strings | optional |  `["usr/share/man/**"]`  |
| <a id="apt.ubuntu-glob_pattern"></a>glob_pattern |  Experimental: `glob()` pattern for the default `build_file` template.   | List of strings | optional |  `["**"]`  |
| <a id="apt.ubuntu-lockfile"></a>lockfile |  The lock file to use for the index (it is fine for the file to not exist yet)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apt.ubuntu-packages"></a>packages |  Packages to download   | List of strings | required |  |
| <a id="apt.ubuntu-patchelf_dirs"></a>patchelf_dirs |  Paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `["lib/{arch}-linux-gnu", "usr/lib/{arch}-linux-gnu", "usr/bin"]`  |
| <a id="apt.ubuntu-post_install_cmd"></a>post_install_cmd |  Experimental: run a command after the install.<br><br>The keys are the unused, the values the command to run as given to `rctx.execute()`.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="apt.ubuntu-resolve_transitive"></a>resolve_transitive |  Whether dependencies of dependencies should be resolved and added to the lockfile.   | Boolean | optional |  `True`  |
| <a id="apt.ubuntu-suites"></a>suites |  Deb suites to download the packages from (see DEB822)   | List of strings | required |  |
| <a id="apt.ubuntu-uri"></a>uri |  Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)   | String | optional |  `"https://snapshot.ubuntu.com/ubuntu/20250219T154000Z"`  |

<a id="apt.debian"></a>

### debian

Download/extract a set of `packages` from the Ubuntu/Debian repositories.

The packages are only extracted, no install hooks will be executed.
In most cases you need to consider how to handle library paths. See the
[Handle Library Paths](../README.md#handle-library-paths) for details.

The `lockfile` attribute is mandatory, but does not need to exist during the
initial setup. If the attribute is set to a non-existing file a mostly empty
repository that only exposes the target to copy the lockfile into the
workspace is created.

Define a Debian/Ubuntu repository to download from.

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
apt.debian(
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


Multiple `debian()` tags are allowed but need unique names.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.debian-name"></a>name |  Base name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.debian-add_files"></a>add_files |  Experimental: add files to the install dir.<br><br>The keys are paths into the install dir. The label may only refer to a single file. "{arch}" in keys will be replaced by the value as returned by `uname -m`).   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="apt.debian-architectures"></a>architectures |  Architectures for which to download the package lists (see DEB822)   | List of strings | optional |  `["amd64"]`  |
| <a id="apt.debian-build_file"></a>build_file |  Experimental: BUILD.bazel template for the generated install dir.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_linux_packages//apt:install.BUILD.bazel.tmpl"`  |
| <a id="apt.debian-components"></a>components |  Deb components to download the packages from (see DEB822)   | List of strings | optional |  `["main"]`  |
| <a id="apt.debian-extra_patchelf_dirs"></a>extra_patchelf_dirs |  Additional paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `[]`  |
| <a id="apt.debian-fix_absolute_interpreter_with_patchelf"></a>fix_absolute_interpreter_with_patchelf |  Whether to absolutize the interpreter while fixing executables/libraries using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_relative_interpreter_with_patchelf`.<br><br>Note that this will destroy remote-executability and cache-reuse across different systems if the path to the source/build directory is not exactly the same.   | Boolean | optional |  `False`  |
| <a id="apt.debian-fix_relative_interpreter_with_patchelf"></a>fix_relative_interpreter_with_patchelf |  Whether to fix the interpreter of executables using `patchelf`<br><br>Only has an effect if `fix_rpath_with_patchelf` is set to `True`. Mutually exclusive with `fix_absolute_interpreter_with_patchelf`.   | Boolean | optional |  `False`  |
| <a id="apt.debian-fix_rpath_with_patchelf"></a>fix_rpath_with_patchelf |  Whether to fix the RPATH of executables/libraries using `patchelf`   | Boolean | optional |  `False`  |
| <a id="apt.debian-glob_excludes"></a>glob_excludes |  Experimental: `glob()` pattern excludes for the default `build_file` template.   | List of strings | optional |  `["usr/share/man/**"]`  |
| <a id="apt.debian-glob_pattern"></a>glob_pattern |  Experimental: `glob()` pattern for the default `build_file` template.   | List of strings | optional |  `["**"]`  |
| <a id="apt.debian-lockfile"></a>lockfile |  The lock file to use for the index (it is fine for the file to not exist yet)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apt.debian-packages"></a>packages |  Packages to download   | List of strings | required |  |
| <a id="apt.debian-patchelf_dirs"></a>patchelf_dirs |  Paths to inspect for executable/library files to fix with `patchelf`<br><br>Note that this will not recursively inspect subdirectories. "{arch}" will be replaced by the value as returned by `uname -m`).   | List of strings | optional |  `["lib/{arch}-linux-gnu", "usr/lib/{arch}-linux-gnu", "usr/bin"]`  |
| <a id="apt.debian-post_install_cmd"></a>post_install_cmd |  Experimental: run a command after the install.<br><br>The keys are the unused, the values the command to run as given to `rctx.execute()`.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="apt.debian-resolve_transitive"></a>resolve_transitive |  Whether dependencies of dependencies should be resolved and added to the lockfile.   | Boolean | optional |  `True`  |
| <a id="apt.debian-suites"></a>suites |  Deb suites to download the packages from (see DEB822)   | List of strings | required |  |
| <a id="apt.debian-uri"></a>uri |  Deb mirror to download the packages from (see URIs in DEB822 but only allows what basel supports)   | String | optional |  `"https://snapshot.debian.org/archive/debian/20250201T023325Z"`  |


