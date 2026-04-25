{

  description = "Askold's main flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-askold = {
      #     url = "github:AskoldMakaruk/nixpkgs";
      # for local development
      url = "git+file:///home/askold/src/nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      #inputs.nixpkgs.follows = "nixpkgs";
    };

    # global macro expander
    espanso-fix.url = "github:pitkling/nixpkgs/espanso-fix-capabilities-export";

    # cli tool to send telegram bot messages
    telegram-cli = {
      url = "github:AskoldMakaruk/telegram-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vim flake
    nixvim.url = "github:nix-community/nixvim";

    # secret manager
    agenix.url = "github:ryantm/agenix";

    # personal secrets
    mysecrets = {
      url = "git+file:///home/askold/secrets/";
      flake = false;
    };

    # iso generation
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # clean firefox alternative
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
        # to have it up-to-date or simply don't specify the nixpkgs input
        nixpkgs.follows = "nixpkgs-master";
        home-manager.follows = "home-manager";
      };
    };

    graphify.url = "git+file:///home/askold/src/graphify";

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dohla.url = "git+file:///home/askold/src/DohlaRusnya/";

    #unused
    # jbr-overlay.url = "github:AskoldMakaruk/jbr-wayland-nix";
    # tagstudio = {
    #   url = "github:TagStudioDev/TagStudio";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      nixpkgs-askold,
      nixos-generators,
      home-manager,
      agenix,
      nixvim,
      graphify,
      microvm,
      # jbr-overlay,
      # dohla,
      espanso-fix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-askold = import nixpkgs-askold {
        inherit system;
        config.allowUnfree = true;
      };

      kilocode-pkg = pkgs-master.callPackage ./pkgs/kilocode { };

      mkHost =
        {
          host,
          extraArgs ? { },
          extraModules ? [ ],
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs system self;
          }
          // extraArgs;
          modules = [
            ./hosts/${host}/configuration.nix
            agenix.nixosModules.default
          ]
          ++ extraModules;
        };

    in
    {
      nixosConfigurations = {
        lenovo = mkHost {
          host = "lenovo";
          extraArgs = {
            inherit
              pkgs-master
              pkgs-askold
              graphify
              kilocode-pkg
              ;
          };
          extraModules = [ espanso-fix.nixosModules.espanso-capdacoverride ];
        };

        pc = mkHost {
          host = "pc";
          extraArgs = { inherit pkgs-master; };
        };

        timba-1 = mkHost {
          host = "timba-1";
          extraArgs = { inherit pkgs-master pkgs-askold nixpkgs; };
        };

        timba-2 = mkHost {
          host = "timba-2";
          extraArgs = { inherit pkgs-master pkgs-askold nixpkgs; };
        };

        ai-sandbox = mkHost {
          host = "ai-sandbox";
          extraArgs = { inherit kilocode-pkg; };
          extraModules = [ microvm.nixosModules.microvm ];
        };
      };
    };
}
