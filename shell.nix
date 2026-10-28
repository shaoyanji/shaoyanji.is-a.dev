# let
#   nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
#   pkgs = import nixpkgs { config = {}; overlays = []; };
# in
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell
# pkgs.mkShellNoCC
{
  nativeBuildInputs = with pkgs; [
  ];
  packages = with pkgs; [
    cowsay
    lolcat
    jekyll
    bundler
    gum
    fzf
    tgpt
  ];
  shellHook =
    /*
    bash
    */
    ''
      eval "$(fzf --bash)"
      0file() { curl -F"file=@$1" https://envs.sh ; }
      0pb() { curl -F"file=@-;" https://envs.sh ; }
      0url() { curl -F"url=$1" https://envs.sh ; }
      0short() { curl -F"shorten=$1" https://envs.sh ; }
    '';
}
