{
  buildGerritBazelPlugin,
  fetchgit,
}:
buildGerritBazelPlugin rec {
  name = "avatars-gravatar";
  version = "b687eb0";
  src = fetchgit {
    url = "https://gerrit.googlesource.com/plugins/avatars-gravatar";
    rev = "b687eb0b55d464fea200b88059db1c393a1ad1ae";
    hash = "sha256-iQF/2Z5HtzVJPyyHUiN1AIRvv1fWa1XnR3uUgwa8TFg=";
  };
  depsHash = "sha256-pcjAqkdHN/WDtv6D7GhZWeTG+1btDmMWu3to9BVMjAA=";
}
