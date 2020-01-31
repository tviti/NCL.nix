/* A nix-shell for running a conda installed copy of NCL v6.6.2 on a Darwin system
   that is otherwise managed using nix/nix-darwin.

   Example usage (from within this dir):
     (base)$ conda activate ncl_stable # Source the conda env created by NCL
     (ncl_stable)$ nix-shell
     [nix-shell]$ ncl

   The main reason we need this is
   because X11 libs installed from nixpkgs are placed in the store, whereas the
   de-facto standard location for these things is supposed to be in /opt (i.e. if
   you had instead installed xquartz by downloading the .DMG from xquartz.org, the
   libs would be in there).

   NOTE: It might be a better idea to just load the derivation as the nix-shell
   source, in order to avoid maintaining two separate but similar sets of nix
   expressions, but for the time being I'm keeping this as a separate file from the
   main derivation.
*/

{ pkgs ? import <nixpkgs> { } }:

let NCL = pkgs.callPackage ./default.nix { };
in pkgs.mkShell {

  buildInputs = [ NCL ];

}
