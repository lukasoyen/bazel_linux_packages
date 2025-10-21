"lock"

load(":util.bzl", "util")

def _make_package_key(name, version, arch):
    return "%s_%s_%s" % (
        util.sanitize(name),
        util.sanitize(version),
        arch,
    )

def _package_key(package, arch):
    return _make_package_key(package["Package"], package["Version"], arch)

def _add_package(lock, package, arch):
    k = _package_key(package, arch)
    if k in lock.fast_package_lookup:
        return
    lock.packages.append({
        "key": k,
        "name": package["Package"],
        "version": package["Version"],
        "url": "%s/%s" % (package["Root"], package["Filename"]),
        "sha256": package["SHA256"],
        "arch": arch,
        "dependencies": [],
    })
    lock.fast_package_lookup[k] = len(lock.packages) - 1

def _add_package_dependency(lock, package, dependency, arch):
    k = _package_key(package, arch)
    if k not in lock.fast_package_lookup:
        fail("Broken state: %s is not in the lockfile." % package["Package"])
    i = lock.fast_package_lookup[k]
    lock.packages[i]["dependencies"].append(dict(
        key = _package_key(dependency, arch),
        name = dependency["Package"],
        version = dependency["Version"],
    ))

def _has_package(lock, name, version, arch):
    key = "%s_%s_%s" % (util.sanitize(name), util.sanitize(version), arch)
    return key in lock.fast_package_lookup

def _sort_sources(sources):
    new_sources = {}
    for key in sources:
        if type(sources[key]) == type([]):
            new_sources[key] = sorted(sources[key])
        else:
            new_sources[key] = sources[key]
    return new_sources

def _sort_input_data(input_data):
    new_input_data = {}
    for key in input_data:
        if key == "sources":
            new_sources = []
            for source in input_data[key]:
                new_sources.append(_sort_sources(source))
            new_sources = sorted(new_sources, key = lambda x: x["uri"])
            new_input_data[key] = new_sources
        elif type(input_data[key]) == type([]):
            new_input_data[key] = sorted(input_data[key])
        else:
            new_input_data[key] = input_data[key]
    return new_input_data

def _sort_packages(packages):
    for p in packages:
        p["dependencies"] = sorted(p["dependencies"], key = lambda x: x["key"])
    return sorted(packages, key = lambda x: x["key"])

def _create(rctx, lock):
    return struct(
        has_package = lambda *args, **kwargs: _has_package(lock, *args, **kwargs),
        add_package = lambda *args, **kwargs: _add_package(lock, *args, **kwargs),
        add_package_dependency = lambda *args, **kwargs: _add_package_dependency(lock, *args, **kwargs),
        packages = lambda: lock.packages,
        input_data_equals = lambda new_input_data: lock.input_data == _sort_input_data(new_input_data),
        write = lambda out: rctx.file(
            out,
            json.encode_indent(struct(
                version = lock.version,
                input_data = _sort_input_data(lock.input_data),
                packages = _sort_packages(lock.packages),
            )),
            executable = False,
        ),
        as_json = lambda: json.encode_indent(struct(
            version = lock.version,
            input_data = _sort_input_data(lock.input_data),
            packages = _sort_packages(lock.packages),
        )),
    )

def _empty(rctx, input_data):
    lock = struct(
        version = 2,
        input_data = _sort_input_data(input_data),
        packages = list(),
        fast_package_lookup = dict(),
    )
    return _create(rctx, lock)

def _from_json(rctx, content):
    lock = json.decode(content)
    if lock["version"] != 2:
        fail("Invalid lockfile version. Delete the lockfile and recreate.")

    lock = struct(
        version = lock["version"],
        input_data = _sort_input_data(lock.get("input_data", {})),
        packages = _sort_packages(lock["packages"]),
        fast_package_lookup = dict(),
    )
    for (i, package) in enumerate(lock.packages):
        lock.packages[i] = package
        lock.fast_package_lookup[package["key"]] = i
    return _create(rctx, lock)

lockfile = struct(
    empty = _empty,
    from_json = _from_json,
    make_package_key = _make_package_key,
)
