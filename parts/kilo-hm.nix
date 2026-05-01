{ config, ... }: {
  home.file = {
    ".kilo/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.dotfiles/config/kilo/skills";
    };
  };
}
