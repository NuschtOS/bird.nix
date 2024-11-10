{ self, pkgs }:

{
  bird = import ./bird.nix { inherit self pkgs; };
}
