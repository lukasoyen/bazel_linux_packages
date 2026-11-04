"""Check repository contents cache reuse across independent Bazel output bases.

Run with Python 3 on Linux and Bazel 9 or newer. The first query downloads the
fixture packages; subsequent queries must reuse fetched repositories offline.
"""

import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile


REPO = Path(__file__).resolve().parents[1]


def run_bazel(workspace, output_base, downloads, contents, expression, offline=False):
    command = [
        "bazel",
        "--batch",
        "--nosystem_rc",
        "--nohome_rc",
        "--noworkspace_rc",
        f"--output_base={output_base}",
        "query",
        f"--repository_cache={downloads}",
        f"--repo_contents_cache={contents}",
        expression,
    ]
    if offline:
        command.append("--repository_disable_download")
    return subprocess.run(
        command,
        cwd=workspace,
        env=os.environ.copy(),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=600,
    )


def repository(output_base, suffix):
    matches = [
        path
        for path in (output_base / "external").iterdir()
        if path.name.endswith("+" + suffix) and path.is_dir()
    ]
    assert len(matches) == 1, (suffix, matches)
    return matches[0].resolve()


def main():
    assert platform.system() == "Linux", "This integration test requires Linux"
    arch = {"x86_64": "amd64", "aarch64": "arm64"}[platform.machine()]
    with tempfile.TemporaryDirectory(prefix="apt-repo-contents-cache-") as directory:
        root = Path(directory)
        workspace = root / "workspace"
        workspace.mkdir()
        downloads = root / "downloads"
        contents = root / "contents"
        first = root / "first"
        second = root / "second"
        lockfile = workspace / "focal.lock.json"
        shutil.copyfile(REPO / "e2e/smoke/focal.lock.json", lockfile)
        shutil.copyfile(REPO / ".bazelversion", workspace / ".bazelversion")
        (workspace / "BUILD.bazel").write_text('exports_files(["extra.txt"])\n')
        (workspace / "extra.txt").write_text("extra file\n")
        unverified = json.loads(lockfile.read_text())
        for package in unverified["packages"]:
            package["sha256"] = ""
        (workspace / "unverified.lock.json").write_text(json.dumps(unverified))

        module = [
            'bazel_dep(name = "bazel_linux_packages", version = "0.0.0")',
            'local_path_override(module_name = "bazel_linux_packages", path = '
            + json.dumps(str(REPO))
            + ")",
            'apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")',
        ]
        configurations = {
            "cached": "",
            "post_install": 'post_install_cmd = {"location": ["sh", "-c", "pwd > location.txt"]},',
            "rpath": "fix_rpath_with_patchelf = True, fix_absolute_interpreter_with_patchelf = True,",
            "add_files": 'add_files = {"host_{arch}.txt": "//:extra.txt"},',
            "unverified": "",
        }
        for name, options in configurations.items():
            lock = "unverified.lock.json" if name == "unverified" else "focal.lock.json"
            module.append(
                f'apt.ubuntu(name = "{name}", architectures = ["amd64", "arm64"], '
                f'lockfile = "//:{lock}", packages = ["busybox"], suites = ["focal"], {options})'
            )
            module.append(f'use_repo(apt, "{name}_{arch}")')
        (workspace / "MODULE.bazel").write_text("\n".join(module) + "\n")

        expression = " + ".join(
            [f"deps(@cached_{arch}//:lock)"]
            + [f"@{name}_{arch}//:manifest" for name in configurations if name != "cached"]
        )
        result = run_bazel(workspace, first, downloads, contents, expression)
        assert result.returncode == 0, result.stdout

        cached_names = ["cached_repository", "cached_index", f"cached_{arch}"]
        cached_names += [f"{name}_{arch}_download" for name in configurations if name != "unverified"]
        original_paths = {name: repository(first, name) for name in cached_names}
        for name, path in original_paths.items():
            assert path.is_relative_to(contents), (name, path)
        for name in ["post_install", "rpath", "add_files"]:
            assert not repository(first, f"{name}_{arch}").is_relative_to(contents)
        assert not repository(first, f"unverified_{arch}_download").is_relative_to(contents)

        # Keep registry/module/tool downloads, but remove the fixture's package
        # archives. An ordinary download-cache hit must not hide a cache miss.
        removed = 0
        for package in json.loads(lockfile.read_text())["packages"]:
            archive = downloads / "content_addressable/sha256" / package["sha256"]
            if archive.exists():
                shutil.rmtree(archive)
                removed += 1
        assert removed > 0, "No fixture archives found in the download cache"
        expression = " + ".join(
            [f"deps(@cached_{arch}//:lock)"]
            + [f"@{name}_{arch}//:manifest" for name in ["post_install", "rpath", "add_files"]]
        )
        result = run_bazel(workspace, second, downloads, contents, expression, offline=True)
        assert result.returncode == 0, result.stdout
        for name, path in original_paths.items():
            assert repository(second, name) == path, name
        post_install = repository(second, f"post_install_{arch}")
        assert (post_install / "location.txt").read_text().strip() == str(post_install)
        assert post_install != repository(first, f"post_install_{arch}")

        # A watched lockfile must invalidate cached repositories even when its
        # attributes are unchanged. The removed package archives now prevent a
        # refetch, so this query must fail instead of using the previous result.
        lockfile.write_text(lockfile.read_text() + "\n")
        result = run_bazel(
            workspace,
            root / "changed-lockfile",
            downloads,
            contents,
            f"@cached_{arch}//:manifest",
            offline=True,
        )
        assert result.returncode != 0, "Lockfile change did not invalidate the cache"
        assert "download is disabled" in result.stdout.lower(), result.stdout
        print("Repository cache reuse, unsafe configurations, and lockfile invalidation passed.")


if __name__ == "__main__":
    main()
