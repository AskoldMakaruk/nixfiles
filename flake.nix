{

  description = "Askold's main flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    jbr-overlay.url = "github:AskoldMakaruk/jbr-wayland-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixvim,
      jbr-overlay,
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
          modules = [ ./hosts/lenovo/configuration.nix ];
        };
        # pc
        pc = lib.nixosSystem {
          specialArgs = { inherit inputs system; };
          modules = [ ./hosts/pc/configuration.nix ];
        };
      };
    };

}
