{
  lib,
  python3Packages,
  fetchFromGitHub,
# TODO: remove fetchFromGitHub when switching back from local src
}:

let
  pymssql = python3Packages.pymssql.overridePythonAttrs (old: {
    postPatch = ''
      sed -i '/standard-distutils/d' pyproject.toml
      substituteInPlace pyproject.toml \
        --replace-fail '"setuptools>80.0"' '"setuptools"'
    '';
  });
in
python3Packages.buildPythonPackage rec {
  pname = "microsoft-sql-server-mcp";
  version = "0.1.0";

  # src = fetchFromGitHub {
  #   owner = "RichardHan";
  #   repo = "mssql_mcp_server";
  #   rev = "v${version}";
  #   hash = "sha256-5W6Y0hbKwaYtBXH5kt6VcmkYlg/iI7kAxrUPMlzaqQc=";
  # };

  src = /home/askold/src/mssql_mcp_server;

  pyproject = true;

  nativeBuildInputs = with python3Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python3Packages; [
    mcp
    pymssql
  ];

  meta = {
    description = "A Model Context Protocol (MCP) server for Microsoft SQL Server";
    homepage = "https://github.com/RichardHan/mssql_mcp_server";
    license = lib.licenses.mit;
    mainProgram = "mssql_mcp_server";
    platforms = lib.platforms.linux;
  };
}
