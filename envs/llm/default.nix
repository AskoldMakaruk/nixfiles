{ stdenv }:

stdenv.mkDerivation rec { config = { services.ollama.enable = true; }; }
