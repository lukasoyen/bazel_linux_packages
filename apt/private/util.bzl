"utilities"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")

def _set_dict(struct, value = None, keys = []):
    klen = len(keys)
    for i in range(klen - 1):
        k = keys[i]
        if not k in struct:
            struct[k] = {}
        struct = struct[k]

    struct[keys[-1]] = value

def _get_dict(struct, keys = [], default_value = None):
    value = struct
    for k in keys:
        if k in value:
            value = value[k]
        else:
            value = default_value
            break
    return value

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

def _warning(rctx, message):
    rctx.execute([
        "echo",
        "\033[0;33mWARNING:\033[0m {}".format(message),
    ], quiet = False)

def _info(rctx, message):
    rctx.execute(["echo", message], quiet = False)

def _get_repo_path(rctx, source, path):
    # If a value the user supplied in `sources` starts with a `@`
    # we assume this to be a visible repo name (made visible via
    # `use_repo()`).
    if source.startswith("@"):
        repo = source
        # If not this is a reference to a repository in the context of
        # this extension module and we can use `rctx.attr.name` to get
        # the correct prefix to append to.

    else:
        repo = "@@" + rctx.attr.name.replace(rctx.attr.install_name, source)
    return Label("{}//:{}".format(repo, path))

def _get_host_tool(rctx, repo, name):
    return str(rctx.path(Label("@{}_{}//:{}".format(
        repo,
        repo_utils.platform(rctx),
        name,
    ))))

util = struct(
    sanitize = _sanitize,
    set_dict = _set_dict,
    get_dict = _get_dict,
    warning = _warning,
    info = _info,
    get_repo_path = _get_repo_path,
    get_host_tool = _get_host_tool,
)
