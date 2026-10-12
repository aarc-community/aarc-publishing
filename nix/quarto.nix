# Quarto as upstream releases it, with the pandoc, typst, deno and dart-sass it
# bundles. nixpkgs packages Quarto against its own pandoc, and a version skew
# between the two breaks rendering, so the release tarball is used as it stands.
# On Linux the bundled binaries are patched to run from the Nix store. On macOS
# they are code-signed and left untouched.
#
# To move to a new release, change the version and set each hash from
#   nix store prefetch-file --json <url> | jq -r .hash
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "1.10.18";

  sources = {
    x86_64-linux = {
      asset = "linux-amd64";
      hash = "sha256-r60HG1vSLALy0wBpV0MYnTZQ4FN6Uwc+ZUtjDP8rDHM=";
    };
    aarch64-linux = {
      asset = "linux-arm64";
      hash = "sha256-9qB99o4lMwtd809l099mvKYFrM47gwxZOljpGITUz2w=";
    };
    x86_64-darwin = {
      asset = "macos";
      hash = "sha256-3danGp4ESKsV+2VbxYnhHLZYmiSOw1zNf39EE3UxaI4=";
    };
    aarch64-darwin = {
      asset = "macos";
      hash = "sha256-3danGp4ESKsV+2VbxYnhHLZYmiSOw1zNf39EE3UxaI4=";
    };
  };

  system = stdenv.hostPlatform.system;
  source = sources.${system} or (throw "quarto: no release for ${system}");

  # The directory under bin/tools that holds the binaries for this machine.
  toolsArch = if stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
in
stdenv.mkDerivation {
  pname = "quarto";
  inherit version;

  src = fetchurl {
    url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-${source.asset}.tar.gz";
    inherit (source) hash;
  };

  # The Linux tarball has a top-level directory and the macOS tarball does not.
  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Stripping corrupts the deno executable, and any fixup invalidates the code
  # signatures of the macOS binaries.
  dontStrip = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall

    root=.
    if [ -d quarto-${version} ]; then root=quarto-${version}; fi

    mkdir -p $out/lib/quarto $out/bin
    cp -r $root/bin $root/share $out/lib/quarto/

    # The launcher resolves its own symlink, so a link into bin/ works. typst is
    # exposed as well, because the scripts that draw the figures call it, and
    # the bundled one is the version Quarto renders with.
    ln -s $out/lib/quarto/bin/quarto $out/bin/quarto
    ln -s $out/lib/quarto/bin/tools/${toolsArch}/typst $out/bin/typst

    runHook postInstall
  '';

  meta = {
    description = "Quarto ${version}, as released upstream with its bundled tools";
    homepage = "https://quarto.org";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "quarto";
  };
}
