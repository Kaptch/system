{ config, pkgs, ... }: with pkgs;
{
  users.groups.plugdev = {};
  
  users.users.kaptch = {
    isNormalUser = true;
    home = "/home/kaptch";
    extraGroups = [ "wheel" "networkmanager" "audio" "libvirtd" "plugdev" ];
  };
}
