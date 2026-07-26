{
  pkgs,
  ...
}:

{
  packages = [
    pkgs.actionlint
    pkgs.shellcheck
    # For running versionary locally (npx versionary verify).
    pkgs.nodejs
  ];

  git-hooks.hooks = {
    actionlint.enable = true;
    shellcheck.enable = true;
  };
}
