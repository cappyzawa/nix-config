{
  config,
  pkgs,
  lib,
  ...
}:
let
  crequaGitRepositories = [
    "prods"
    "hololive-knowledge"
  ];
  crequaGitTokenFile = "${config.xdg.dataHome}/git/crequa-token";
  crequaGitCredential = pkgs.writeShellApplication {
    name = "git-credential-crequa";
    text = ''
      token_file=$1
      if [[ ''${2:-} != get ]]; then
        exit 0
      fi

      protocol="" host="" path=""
      while IFS= read -r line && [[ -n "$line" ]]; do
        case "$line" in
          protocol=*) protocol=''${line#*=} ;;
          host=*) host=''${line#*=} ;;
          path=*) path=''${line#*=} ;;
        esac
      done

      if [[ "$protocol" != https || "$host" != github.com ]]; then
        printf 'quit=true\n'
        exit 0
      fi
      case "$path" in
        ${
          lib.concatMapStringsSep "|" (repo: "crequa/${repo}|crequa/${repo}.git") crequaGitRepositories
        }) ;;
        *) printf 'quit=true\n'; exit 0 ;;
      esac

      token=
      if [[ -r "$token_file" ]]; then
        IFS= read -r token < "$token_file" || true
      fi
      if [[ -z "$token" ]]; then
        printf 'Crequa PAT is missing: %s\n' "$token_file" >&2
        printf 'quit=true\n'
        exit 0
      fi
      printf 'username=x-access-token\npassword=%s\n' "$token"
    '';
  };
  crequaGh = pkgs.writeShellApplication {
    name = "crequa-gh";
    runtimeInputs = [ pkgs.gh ];
    text = ''
      GH_TOKEN=
      if [[ -r ${lib.escapeShellArg crequaGitTokenFile} ]]; then
        IFS= read -r GH_TOKEN < ${lib.escapeShellArg crequaGitTokenFile} || true
      fi
      if [[ -z "$GH_TOKEN" ]]; then
        printf 'Crequa PAT is missing: %s\n' ${lib.escapeShellArg crequaGitTokenFile} >&2
        exit 1
      fi
      export GH_TOKEN
      export GH_HOST=github.com
      exec gh "$@"
    '';
  };
in
{
  home.packages = [ crequaGh ];
  programs.git = {
    includes =
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents = {
            user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_crequa_signing";
            gpg.ssh.program = "/usr/bin/ssh-keygen";
            url."https://github.com/crequa/".insteadOf = [
              "git@github.com:crequa/"
              "ssh://git@github.com/crequa/"
              "https://github.com/crequa/"
            ];
            credential."https://github.com/crequa" = {
              useHttpPath = true;
              helper = [
                ""
                "${crequaGitCredential}/bin/git-credential-crequa ${lib.escapeShellArg crequaGitTokenFile}"
              ];
            };
          };
        })
        (
          lib.concatMap (
            repo:
            lib.concatMap
              (prefix: [
                "${prefix}${repo}"
                "${prefix}${repo}.git"
              ])
              [
                "git@github.com:crequa/"
                "ssh://git@github.com/crequa/"
                "https://github.com/crequa/"
              ]
          ) crequaGitRepositories
        );
  };
  xdg.configFile."git/allowed_signers".source = lib.mkForce (
    pkgs.writeText "git-allowed-signers" (
      builtins.readFile ../../config/git/allowed_signers + builtins.readFile ./git-allowed-signers
    )
  );
}
