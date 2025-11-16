{

  description = "Askold's main flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-askold.url = "github:AskoldMakaruk/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    espanso-fix.url = "github:pitkling/nixpkgs/espanso-fix-capabilities-export";
    telegram-cli = {
      url = "github:AskoldMakaruk/telegram-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nixvim.url = "github:nix-community/nixvim";
    #jbr-overlay.url = "github:AskoldMakaruk/jbr-wayland-nix";
    dohla.url = "git+file:///home/askold/src/DohlaRusnya/";
    mysecrets = {
      url = "git+file:///home/askold/secrets/";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      nixpkgs-askold,
      home-manager,
      agenix,
      nixvim,
      # jbr-overlay,
      dohla,
      espanso-fix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        # laptop
        lenovo = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs system;
            pkgs-master = import nixpkgs-master {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-askold = import nixpkgs-master {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = [
            ./hosts/lenovo/configuration.nix
            agenix.nixosModules.default
            dohla.nixosModules.dohly-services
            espanso-fix.nixosModules.espanso-capdacoverride
          ];
        };
        # pc
        pc = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = [
            ./hosts/pc/configuration.nix
            agenix.nixosModules.default
            dohla.nixosModules.dohly-services
          ];
        };
      };
    };

}
