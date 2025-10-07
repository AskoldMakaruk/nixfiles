{

  description = "Askold's main flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nixvim.url = "github:nix-community/nixvim";
    jbr-overlay.url = "github:AskoldMakaruk/jbr-wayland-nix";
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
      home-manager,
      agenix,
      nixvim,
      jbr-overlay,
      dohla,
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
          specialArgs = { inherit inputs system; };
          modules = [
            ./hosts/lenovo/configuration.nix
            agenix.nixosModules.default
            dohla.nixosModules.dohly-services
          ];
        };
        # pc
        pc = lib.nixosSystem {
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
