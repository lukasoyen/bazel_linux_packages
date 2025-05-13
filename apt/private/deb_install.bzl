"repository rule for extracting debian archives into a install dir"

load("//apt/private:util.bzl", "util")

def _correct_symlinks(rctx, busybox, path):
    cmd = [busybox, "tar", "-tvf", str(path)]
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
            if target == "." and name != "./":
                rctx.execute(["rm", "-f", name])

def _extract_data_file(rctx, busybox, path):
    cmd = [busybox, "tar", "-xf", str(path)]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to extract data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))
    _correct_symlinks(rctx, busybox, path)

def _list_for_manifest(rctx, busybox, path):
    cmd = [busybox, "tar", "-tf", str(path)]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to list data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

    paths = []
    for line in result.stdout.splitlines():
        if not line.endswith("/"):
            paths.append(line)
    return paths

def _list_files(rctx, busybox, directory = ".", *args):
    if not rctx.path(directory).exists:
        return []
    cmd = [busybox, "find", "-L", directory, "-type", "f"] + list(args)
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to list files {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))
    return result.stdout.splitlines()

def _read_ld_so_conf(rctx, path):
    result = []
    for line in rctx.read(path).splitlines():
        if not line.startswith("#"):
            result.append(line.strip())
    return result

def _fixup_rpath(rctx, patchelf, path, lib_paths):
    # The levels we need to travers up from $ORIGIN.
    levels = "/".join([".." for _ in range(len(path.split("/")) - 1)])
    rpath = ":".join(["$ORIGIN/{}{}".format(levels, lib) for lib in lib_paths])

    cmd = [patchelf, "--add-rpath", rpath, path]
    result = rctx.execute(cmd)
    if result.return_code:
        if "patchelf: not an ELF executable" in result.stderr:
            return
        if "patchelf: wrong ELF type" in result.stderr:
            return
        fail("Failed to add RPATH: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

def _fixup_interpreter(rctx, patchelf, path, interpreter):
    cmd = [patchelf, "--set-interpreter", interpreter, path]
    result = rctx.execute(cmd)
    if result.return_code:
        if "patchelf: not an ELF executable" in result.stderr:
            return
        if "patchelf: cannot find section '.interp'" in result.stderr:
            return
        if "patchelf: wrong ELF type" in result.stderr:
            return
        fail("Failed to set interpreter: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

def _find_interpreter(rctx, busybox, arch):
    candidates = _list_files(
        rctx,
        busybox,
        "lib64/",
        "-name",
        "ld-linux-{}.so*".format(arch.replace("_", "-")),
    )
    for path in sorted(candidates, reverse = True):
        return str(rctx.path(path).realpath)
    return None

def _fixup_executables(rctx, arch, busybox, patchelf, fix_relative_interpreter, fix_absolute_interpreter):
    rctx.report_progress("Fixing executable and libraries")
    pwd = str(rctx.path(".").realpath) + "/"

    lib_paths = []
    for path in sorted(_list_files(rctx, busybox, "etc/ld.so.conf.d/")):
        lib_paths.extend(_read_ld_so_conf(rctx, path))

    seen = set()

    interpreter_path = None
    interpreter = _find_interpreter(rctx, busybox, arch)
    if interpreter != None:
        # We don't want to rpath patch the ld*.so
        seen.add(interpreter.removeprefix(pwd))

        if fix_relative_interpreter:
            interpreter_path = "./external/{}/{}".format(rctx.attr.name, interpreter.removeprefix(pwd))
        if fix_absolute_interpreter:
            interpreter_path = interpreter

    for directory in rctx.attr.patchelf_dirs:
        for path in _list_files(rctx, busybox, directory.format(arch = arch), "-maxdepth", "1"):
            realpath = str(rctx.path(path).realpath).removeprefix(pwd)
            if realpath not in seen and not any([realpath.endswith(e) for e in (".o", ".a")]):
                _fixup_rpath(rctx, patchelf, realpath, lib_paths)
                if interpreter_path != None:
                    _fixup_interpreter(rctx, patchelf, realpath, interpreter_path)
                seen.add(realpath)

def _deb_install_impl(rctx):
    busybox = util.get_host_tool(rctx, "busybox", "bin/busybox")
    patchelf = util.get_host_tool(rctx, "patchelf", "bin/patchelf")
    index = json.decode(rctx.read(util.get_repo_path(rctx, rctx.attr.source, "index.json")))

    # otherwise assume we are in the initial lockfile generation
    if index:
        if rctx.attr.architecture not in index:
            fail(
                "Misconfigured `install()`. Can not find the provided architecture {} in packages from {}".format(rctx.attr.architecture, rctx.attr.source),
            )

        arch = rctx.execute([busybox, "uname", "-m"]).stdout.strip()

        manifest = dict()
        for package in index[rctx.attr.architecture]:
            label = Label(package)
            path = rctx.path(label)
            rctx.report_progress("Extracting data from package {}/{}".format(path.dirname.basename, path.basename))
            _extract_data_file(rctx, busybox, path)
            manifest["{}".format(label.name)] = _list_for_manifest(rctx, busybox, path)

        if rctx.attr.fix_rpath_with_patchelf:
            _fixup_executables(
                rctx,
                arch,
                busybox,
                patchelf,
                rctx.attr.fix_relative_interpreter_with_patchelf,
                rctx.attr.fix_absolute_interpreter_with_patchelf,
            )

        for (path, label) in rctx.attr.add_files.items():
            rctx.symlink(label, path.format(arch = arch))

        rctx.file(
            "install_manifest.json",
            json.encode_indent(manifest),
            executable = False,
        )

    rctx.file(
        "defs.bzl",
        'def with_repository_prefix(path): return "external/{}/{{}}".format(path)'.format(rctx.attr.name),
        executable = False,
    )

    rctx.template(
        "BUILD.bazel",
        rctx.attr.build_file,
        {"{target_name}": rctx.attr.source},
        executable = False,
    )

deb_install = repository_rule(
    implementation = _deb_install_impl,
    attrs = {
        "architecture": attr.string(mandatory = True),
        "source": attr.string(mandatory = True),
        "fix_rpath_with_patchelf": attr.bool(mandatory = True),
        "fix_relative_interpreter_with_patchelf": attr.bool(mandatory = True),
        "fix_absolute_interpreter_with_patchelf": attr.bool(mandatory = True),
        "patchelf_dirs": attr.string_list(mandatory = True),
        "add_files": attr.string_keyed_label_dict(mandatory = True),
        "build_file": attr.label(mandatory = True),
    },
)
