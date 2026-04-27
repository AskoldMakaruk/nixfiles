{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}:

let
  version = "1.7.1";
  pname = "another-redis-desktop-manager";
  systems = {
    "x86_64-linux" = "x86_64";
    "aarch64-linux" = "arm64";
  };
  arch =
    systems.${stdenv.hostPlatform.system}
      or (throw "unsupported system: ${stdenv.hostPlatform.system}");
  hashes = {
    "x86_64-linux" = "sha256-XuS4jsbhUproYUE2tncT43R6ErYB9WTg6d7s16OOxFQ=";
    "aarch64-linux" = "sha256-0WXWl0UAQBqJlvt2MNpNHuqmEAlIlvY0FfHXu4LKkcY=";
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/qishibo/AnotherRedisDesktopManager/releases/download/v${version}/Another-Redis-Desktop-Manager-linux-${version}-${arch}.AppImage";
    hash = hashes.${stdenv.hostPlatform.system};
  };

  extraPkgs = pkgs: with pkgs; [ libxshmfence ];

  meta = {
    description = "A faster, better and more stable redis desktop manager";
    homepage = "https://github.com/qishibo/AnotherRedisDesktopManager";
    license = lib.licenses.mit;
    platforms = builtins.attrNames systems;
    mainProgram = "another-redis-desktop-manager";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
