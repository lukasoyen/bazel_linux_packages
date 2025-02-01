"""
Internal helper to download host tooling from debian archives.
These tools are used for the repository setup of the use requested
repositories.
"""

def _deb_archive_impl(rctx):
    rctx.download_and_extract(
        url = rctx.attr.urls,
        integrity = rctx.attr.integrity,
    )
    rctx.extract("data.tar.xz")

    rctx.file("BUILD.bazel", "exports_files(['usr/bin/busybox'])")

deb_archive = repository_rule(
    implementation = _deb_archive_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "integrity": attr.string(mandatory = True),
    },
)
