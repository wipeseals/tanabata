{
    description = "A flake for building gleam projects";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: {
        packages.default = let
            pkgs = import nixpkgs { inherit system; };
        in pkgs.mkShell {
            buildInputs = [
                pkgs.gleam
                pkgs.erlang
            ];
        };
    });
}