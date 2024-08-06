{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  # nativeBuildInputs = with pkgs; [  ];

  # rust telegram token
  TELOXIDE_TOKEN = "823973981:AAHEBgfxE8juepArApUGZtmD4QVbJ8ZIJEY";
}
