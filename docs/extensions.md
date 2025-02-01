<!-- Generated with Stardoc: http://skydoc.bazel.build -->

apt extensions

<a id="apt"></a>

## apt

<pre>
apt = use_extension("@debian_packages//apt:extensions.bzl", "apt")
apt.source(<a href="#apt.source-name">name</a>, <a href="#apt.source-architectures">architectures</a>, <a href="#apt.source-components">components</a>, <a href="#apt.source-suites">suites</a>, <a href="#apt.source-uri">uri</a>)
apt.download(<a href="#apt.download-name">name</a>, <a href="#apt.download-architectures">architectures</a>, <a href="#apt.download-lockfile">lockfile</a>, <a href="#apt.download-packages">packages</a>, <a href="#apt.download-resolve_transitive">resolve_transitive</a>, <a href="#apt.download-sources">sources</a>)
apt.install(<a href="#apt.install-name">name</a>, <a href="#apt.install-architecture">architecture</a>, <a href="#apt.install-build_file">build_file</a>, <a href="#apt.install-fix_with_patchelf">fix_with_patchelf</a>, <a href="#apt.install-source">source</a>)
</pre>


**TAG CLASSES**

<a id="apt.source"></a>

### source

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

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.download-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"download"`  |
| <a id="apt.download-architectures"></a>architectures |  Architectures for which to download packages (defaults to architectures from `sources` if not given   | List of strings | optional |  `[]`  |
| <a id="apt.download-lockfile"></a>lockfile |  The lock file to use for the index (it is fine for the file to not exist yet)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apt.download-packages"></a>packages |  Packages to download   | List of strings | required |  |
| <a id="apt.download-resolve_transitive"></a>resolve_transitive |  Whether dependencies of dependencies should be resolved and added to the lockfile.   | Boolean | optional |  `True`  |
| <a id="apt.download-sources"></a>sources |  source() repositories to download packages from   | List of strings | optional |  `["source"]`  |

<a id="apt.install"></a>

### install

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apt.install-name"></a>name |  Name of the generated repository   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apt.install-architecture"></a>architecture |  Architectures for which to create the install (defaults to single value architecture from `source` if not given)   | String | optional |  `""`  |
| <a id="apt.install-build_file"></a>build_file |  Experimental: BUILD.bazel template for the generated install dir.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@debian_packages//apt:install.BUILD.bazel.tmpl"`  |
| <a id="apt.install-fix_with_patchelf"></a>fix_with_patchelf |  Whether to fix the RPATH/interpreter of executables/libraries using `patchelf`   | Boolean | optional |  `False`  |
| <a id="apt.install-source"></a>source |  download() repositories to unpack packages from   | String | optional |  `"download"`  |


