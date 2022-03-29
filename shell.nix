let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.elixir_1_10
    pkgs.inotify-tools
  ];
}
