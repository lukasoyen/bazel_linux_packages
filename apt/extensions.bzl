"apt extensions"

load("//apt/private:deb_create_sysroot.bzl", "deb_create_sysroot")
load("//apt/private:deb_resolve.bzl", "deb_resolve", "internal_resolve")
load("//apt/private:lockfile.bzl", "lockfile")

def _resolve_lockfile(module_ctx, tag):
    lockf = None
    if not tag.lock:
        lockf = internal_resolve(
            module_ctx,
            "yq",
            tag.manifest,
            tag.resolve_transitive,
        )

        if not tag.nolock:
            # buildifier: disable=print
            print("\nNo lockfile was given, please run `bazel run @%s//:lock` to create the lockfile." % tag.name)
    else:
        lockf = lockfile.from_json(module_ctx, module_ctx.read(tag.lock))
    return lockf

def _distroless_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []

    for mod in module_ctx.modules:
        for sysroot in mod.tags.sysroot:
            lockf = _resolve_lockfile(module_ctx, sysroot)

            deb_resolve(
                name = sysroot.name + "_resolve",
                manifest = sysroot.manifest,
                resolve_transitive = sysroot.resolve_transitive,
            )

            deb_create_sysroot(
                name = sysroot.name,
                arch = sysroot.arch,
                lock = sysroot.lock,
                lock_content = lockf.as_json(),
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

sysroot = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the generated repository",
            mandatory = True,
        ),
        "arch": attr.string(
            doc = "Architecture for which to genererate the sysroot repository",
            mandatory = True,
        ),
        "manifest": attr.label(
            doc = "The file used to generate the lock file",
            mandatory = True,
        ),
        "lock": attr.label(
            doc = "The lock file to use for the index.",
        ),
        "nolock": attr.bool(
            doc = "If you explicitly want to run without a lock, set it " +
                  "to `True` to avoid the DEBUG messages.",
            default = False,
        ),
        "resolve_transitive": attr.bool(
            doc = "Whether dependencies of dependencies should be " +
                  "resolved and added to the lockfile.",
            default = True,
        ),
    },
)

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "sysroot": sysroot,
    },
)
