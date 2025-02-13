{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          [ 
            pkgs.vim
            pkgs.git
            pkgs.curl
          ];

        users.users = {
          dorian = {
            description = "main"; # Opis użytkownika
            home = "/Users/dorian";  # Ścieżka do katalogu domowego
          };
        };

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        virtualisation.docker.enable = true;

        # Enable alternative shell support in nix-darwin.
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 6;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
      homeconfig = { pkgs, ... }: {
        # this is internal compatibility configuration 
        # for home-manager, don't change this!
        home.stateVersion = "24.11";
        # Let home-manager install and manage itself.
        programs.home-manager.enable = true;

        home.packages = with pkgs; [
          neovim
          nodejs_23
          nodejs_18
          deno
          docker
          colima
        ];

        programs.zsh = {
          enable = true;
          shellAliases = {
            nix-switch = "darwin-rebuild switch --flake ~/.config/nix";
          };
        };

        programs.home-manager.enable = true;
        programs.git.enable = true;
        programs.neovim = {
          enable = true;
          defaultEditor = true;
        };
      };
    in
      {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
        modules = [ 
          configuration 
          home-manager.darwinModules.home-manager  {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.dorian = homeconfig;
          }
        ];
      };
    };
}
