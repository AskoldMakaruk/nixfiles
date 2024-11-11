{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.ncurses}/lib:$LD_LIBRARY_PATH"
'';
   packages = [
      pkgs.dotnet-sdk_8 # or:
      pkgs.ncurses # or:
    ];
}

