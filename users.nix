{ config, pkgs, ... }: with pkgs;
{
  users.users.kaptch = {
    isNormalUser = true;
    home = "/home/kaptch";
    extraGroups = [ "wheel" "networkmanager" "audio" ];
  };
}
