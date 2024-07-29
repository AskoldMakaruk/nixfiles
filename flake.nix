{

  description = "Askold's initial flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, home-manager, ...}@inputs:
 let 
    lib = nixpkgs.lib;
    system = "x86_64-linux";
 in  
 {
   nixosConfigurations = {
      nixos= lib.nixosSystem {
	 specialArgs = { inherit inputs system; };
         modules = [ ./configuration.nix ];
       };
    }; 
  };

}
