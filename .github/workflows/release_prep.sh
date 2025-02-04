#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Argument provided by reusable workflow caller, see
# https://github.com/bazel-contrib/.github/blob/d197a6427c5435ac22e56e33340dff912bc9334e/.github/workflows/release_ruleset.yaml#L72
TAG=$1

cat << EOF
## Using Bzlmod with Bazel 8 or greater

2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "linux_packages", version = "${TAG:1}")
\`\`\`
EOF
