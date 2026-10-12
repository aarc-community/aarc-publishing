# The toolchain that builds AARC guidelines.
#
# In this repository, `devenv shell` enters it. A repository of guidelines
# imports it as a devenv input, and gets the same tools, the AARC extension and
# the commands below. devenv.lock in that repository pins the commit of this
# one, so the tools and the design a guideline is built with move together.
{ pkgs, ... }:

let
  quarto = pkgs.callPackage ./nix/quarto.nix { };

  # The scripts use the standard library only.
  python = pkgs.python313;
in
{
  packages = [
    quarto # quarto and the typst it bundles
    python
    pkgs.just
    pkgs.prettier
    pkgs.poppler-utils # pdffonts and pdftotext, for aarc-check
  ];

  # The extension, and the guideline a new one starts from, as this commit of
  # the repository holds them.
  env.AARC_EXTENSION = "${./_extensions/aarc}";
  env.AARC_STARTER = "${./example/aarc-gxxx-example}";

  # Install the extension into the project in the current directory. Quarto
  # reads an extension only from _extensions/ in the project, so the copy is
  # made there. The files come out of the Nix store read-only, and are made
  # writable so that the next install can replace them.
  scripts.aarc-install.exec = ''
    set -euo pipefail
    rm -rf _extensions/aarc
    mkdir -p _extensions
    cp -r "$AARC_EXTENSION" _extensions/aarc
    chmod -R u+w _extensions/aarc
  '';
  scripts.aarc-install.description = "Install the AARC extension into _extensions/aarc";

  # Read each PDF back and report what a render can get wrong.
  scripts.aarc-check.exec = ''
    exec ${python}/bin/python3 ${./scripts/check-output.py} "$@"
  '';
  scripts.aarc-check.description = "Check the rendered PDFs of the guidelines";

  enterTest = ''
    quarto --version | grep -Fx "${quarto.version}"
    typst --version
    just --version
    pdfinfo -v
    test -f "$AARC_EXTENSION/_extension.yml"
  '';
}
