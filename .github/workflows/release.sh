#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Arguments provided by workflow caller, see ci.yaml
# step: Build release artifacts and prepare release notes
readonly TAG="$1"
readonly PREFIX="$2"
readonly RELEASE_NOTES="$3"

# NB: configuration for 'git archive' is in /.gitattributes
git archive --prefix="${PREFIX}/" ${TAG} -o "${PREFIX}.tar.zst"

cat > "${RELEASE_NOTES}" << EOF
## Using Bzlmod with Bazel 8 or greater

2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "linux_packages", version = "${TAG}")
\`\`\`
EOF

tar xf "${PREFIX}.tar.zst"

(
    pushd e2e/smoke
    bazel test "--override_module=linux_packages=../../${PREFIX}" //...
    popd
)
