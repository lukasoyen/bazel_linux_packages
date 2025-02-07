#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Arguments provided by workflow caller, see ci.yaml
# step: Build release artifacts and prepare release notes
readonly TAG="$1"
readonly PREFIX="${2//[\/]/-}" # in case of a merge this contains merge/XX, so replace / with -
readonly RELEASE_NOTES="$3"

# NB: configuration for 'git archive' is in /.gitattributes
git archive --format=tar --prefix="${PREFIX}/" HEAD | zstd --compress -15 -f -q -o "${PREFIX}.tar.zst"

ls -l "${PREFIX}.tar.zst"

cat > "${RELEASE_NOTES}" << EOF
## Using with Bzlmod with Bazel 8 or greater

2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "linux_packages", version = "${TAG}")
\`\`\`
EOF

tar xvf "${PREFIX}.tar.zst"

(
    pushd e2e/smoke
    bazel test "--override_module=linux_packages=../../${PREFIX}" //...
    popd
)
