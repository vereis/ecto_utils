let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.elixir_1_12
    pkgs.inotify-tools
  ];
}
