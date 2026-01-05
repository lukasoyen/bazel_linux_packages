#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Arguments provided by workflow caller, see ci.yaml
# step: Build release artifacts and prepare release notes
readonly TAG="$1"
readonly PREFIX="${2//[\/]/-}" # in case of a merge this contains merge/XX, so replace / with -
readonly RELEASE_NOTES="$3"

# NB: configuration for 'git archive' is in /.gitattributes
git archive --format=tar.gz --prefix="${PREFIX}/" HEAD > "${PREFIX}.tar.gz"

cat > "${RELEASE_NOTES}" << EOF
## Using with Bazel 8.1 or greater

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "bazel_linux_packages", version = "${TAG}")
\`\`\`
EOF

docs="$(mktemp -d)"
targets="$(mktemp)"
bazel --output_base="$docs" query --output=label --output_file="$targets" 'kind("starlark_doc_extract rule", //...)'
bazel --output_base="$docs" build --target_pattern_file="$targets"
tar --create --auto-compress \
    --directory "$(bazel --output_base="$docs" info bazel-bin)" \
    --file "${PREFIX}.docs.tar.gz" .

ls -l "${PREFIX}.tar.gz" "${PREFIX}.docs.tar.gz"
tar tf "${PREFIX}.tar.gz"
tar tf "${PREFIX}.docs.tar.gz"

tar xf "${PREFIX}.tar.gz"

(
    pushd "${PREFIX}/e2e/smoke"
    bazel test "--override_module=bazel_linux_packages=." //...
    popd
)
