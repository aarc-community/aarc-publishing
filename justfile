# Build and test the AARC guideline extension. Run `just` for the list.
#
# The extension is in _extensions/aarc/. This repository renders the example
# guideline in example/ with it, which is the test that the extension works.
# Guidelines are written in their own repository, which takes the toolchain and
# the extension from this one.

set shell := ["bash", "-euo", "pipefail", "-c"]

# List the recipes
default:
    @just --list --unsorted

# Render the example guideline
build: _writable
    quarto render

# Render the example and fail on any warning or unresolved reference (for CI)
ci: _writable
    #!/usr/bin/env bash
    set -uo pipefail
    # A reproducible build: the PDF carries the time of the last commit.
    # A repository with no commit yet has no time to give, and the PDF takes
    # the time of the build.
    if epoch=$(git log -1 --format=%ct 2>/dev/null) && [ -n "$epoch" ]; then
        export SOURCE_DATE_EPOCH=$epoch
    fi
    output=$(quarto render 2>&1)
    status=$?
    echo "$output"
    if [ $status -ne 0 ]; then
        echo "ci: quarto render failed" >&2
        exit $status
    fi
    if grep -qiE 'unable to resolve|WARN|ERROR|\?@' <<< "$output"; then
        echo "ci: unresolved references or warnings above" >&2
        exit 1
    fi
    aarc-check 'example/*/*.qmd'

# Format the sources. The settings are in .prettierrc.yaml
fmt:
    prettier --write 'example/**/*.qmd' '*.md'

# Remove the build output and the Quarto cache
clean:
    rm -rf .quarto generated

# Quarto copies the typst packages it bundles into .quarto/ on every render.
# Under Nix the originals are read-only, the copies keep that mode, and the next
# render cannot overwrite them. Making the copies writable first avoids that.
_writable:
    @if [ -d .quarto ]; then chmod -R u+w .quarto; fi
