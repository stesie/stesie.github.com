with import <nixpkgs> { };

let
  jekyll_env = bundlerEnv rec {
    name = "jekyll_env";
    inherit ruby;
    gemdir = ./.;
  };
in
  stdenv.mkDerivation rec {
    name = "jekyll_env";
    buildInputs = [ jekyll_env ];

    shellHook = ''
      exec ${jekyll_env}/bin/jekyll serve --watch
    '';
  }

