"Unit tests for package download scheduling and extraction."

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:deb_download.bzl", deb_download = "DO_NOT_DEPEND_ON_THIS_TEST_ONLY")
load("//apt/private:lockfile.bzl", "lockfile")

def _package(name, arch = "amd64"):
    return {
        "name": name,
        "version": "1.0+test",
        "arch": arch,
        "url": "https://example.invalid/{}.deb".format(name),
        "sha256": "a" * 64,
    }

def _extract(env, packages, compressed = False):
    selected = [package for package in packages if package["arch"] == "amd64"]
    downloads = []
    ready = []
    extracted = []
    deleted = []
    commands = []

    def download(url, sha256, output, block = True):
        asserts.false(env, block, "Package downloads must be nonblocking")
        downloads.append((url, sha256, output))

        def wait():
            asserts.equals(env, len(selected), len(downloads), "Queue every package before waiting")
            ready.append(output)

        return struct(wait = wait)

    def extract(archive, output):
        asserts.true(env, archive in ready, "Wait for the archive before extracting it")
        extracted.append(output)

    def delete(archive):
        asserts.true(env, archive[:-4] in extracted, "Extract the archive before deleting it")
        deleted.append(archive)

    def path(value):
        if type(value) == "Label":
            return "/zstd"
        suffix = "/data.tar.gz" if compressed else "/data.tar"
        return struct(exists = value.endswith(suffix))

    def execute(command):
        if command == ["uname", "-m"]:
            return struct(stdout = "x86_64\n")
        commands.append(command)
        return struct(return_code = 0)

    rctx = struct(
        name = "download_test",
        attr = struct(architecture = "amd64"),
        os = struct(name = "linux", arch = "amd64"),
        download = download,
        extract = extract,
        delete = delete,
        path = path,
        execute = execute,
        report_progress = lambda message: None,
    )
    actual = deb_download.extract_packages(rctx, struct(packages = lambda: packages))
    expected_downloads = []
    expected_outputs = []
    expected_commands = []
    expected_labels = []
    for package in selected:
        output = "packages/{}".format(lockfile.make_package_key(package["name"], package["version"], package["arch"]))
        expected_downloads.append((package["url"], package["sha256"], output + ".deb"))
        expected_outputs.append(output)
        expected_commands.append(["/zstd", "--decompress", "--force", "-o", output + "/data.tar", output + "/data.tar.gz"])

        # buildifier: disable=canonical-repository
        expected_labels.append("@@download_test//:{}/data.tar".format(output))

    asserts.equals(env, expected_downloads, downloads)
    asserts.equals(env, expected_outputs, extracted)
    asserts.equals(env, [output + ".deb" for output in expected_outputs], deleted)
    asserts.equals(env, expected_commands if compressed else [], commands)
    asserts.equals(env, {"amd64": expected_labels} if selected else {}, actual)

def _parallel_downloads_test(ctx):
    env = unittest.begin(ctx)
    packages = [_package("z-first"), _package("skip", "arm64"), _package("a-last")]
    _extract(env, packages)
    _extract(env, packages, compressed = True)
    return unittest.end(env)

parallel_downloads_test = unittest.make(_parallel_downloads_test)

def _other_architecture_test(ctx):
    env = unittest.begin(ctx)
    _extract(env, [_package("skip", "arm64")])
    return unittest.end(env)

other_architecture_test = unittest.make(_other_architecture_test)

def download_tests():
    parallel_downloads_test(name = "package_download/parallel_downloads")
    other_architecture_test(name = "package_download/other_architecture")
