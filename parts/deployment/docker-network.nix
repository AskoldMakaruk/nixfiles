{
  networkName,
  root,
  pkgs,
}:
{

  path = [ pkgs.docker ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStop = "docker network rm -f ${networkName}";
  };
  script = ''
    docker network inspect ${networkName}|| docker network create ${networkName}
  '';
  partOf = [ root ];
  wantedBy = [ root ];
}
