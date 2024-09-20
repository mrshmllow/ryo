{...}: {
  services.gitea-actions-runner.instances.one = {
    name = "outpost-3";
    enable = true;
    labels = [
      "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest"
    ];
    tokenFile = "/etc/keys/gitea-actions-runner.env";
    url = "https://git.althaea.zone";
  };
}
