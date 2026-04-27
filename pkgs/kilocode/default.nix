{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "7.2.25";
  targets = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };
  target =
    targets.${stdenv.hostPlatform.system}
      or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kilo";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Kilo-Org/kilocode/releases/download/v${version}/kilo-${target}.tar.gz";
    hash = "sha256-hP0Pcf8mgNZHfFu3aNwQl6/s/rEpjBtDkqNtwtNcFgI=";
  };

  sourceRoot = ".";

  # Bun SEA binary — patchelf corrupts the appended payload.
  # Requires programs.nix-ld.enable = true on NixOS (already set on lenovo).
  dontPatchELF = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 kilo $out/bin/kilo
    runHook postInstall
  '';

  meta = {
    description = "AI-powered development tool (pre-built binary)";
    homepage = "https://kilo.ai/";
    license = lib.licenses.mit;
    mainProgram = "kilo";
    platforms = builtins.attrNames targets;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
