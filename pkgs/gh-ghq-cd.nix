{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "gh-ghq-cd";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "cappyzawa";
    repo = "gh-ghq-cd";
    rev = "v${version}";
    hash = "sha256-cuQi7JsWzgeWYdkk67ohaSDVkwnOuhgmnIJrJDpNphk=";
  };

  cargoHash = "sha256-sMsq6otcvTgWj6w+jJ738NG9j038/XnPcNg7aBxzIzo=";

  meta = {
    description = "GitHub CLI extension to fuzzy find and cd to a ghq managed repository";
    homepage = "https://github.com/cappyzawa/gh-ghq-cd";
    license = lib.licenses.mit;
    mainProgram = "gh-ghq-cd";
  };
}
