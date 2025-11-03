{
  pkgs,
  packageName,
  projectPath,
  envName,
  root,
  port,
}:
{
  path = [
    pkgs.docker
    pkgs.nix
  ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    TimeOutSec = 300;
  };
  script = ''
    docker load < $(nix-build -I nixpkgs=${pkgs.path} ${projectPath} -A ${packageName} \
    --no-out-link --arg imagePostfix '"${envName}"' --arg hostPort '"${port}"')
  '';

  partOf = [ root ];
  wantedBy = [ root ];
}
