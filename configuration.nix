{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./users.nix
    ];

  boot.extraModulePackages = with config.boot.kernelPackages;
    [ v4l2loopback.out ];

  boot.loader = { 
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };  
  
  boot.kernelModules = [ "v4l2loopback" ];

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  fonts.fonts = [ pkgs.font-awesome ];

  networking.hostName = "laptop";
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  networking.interfaces.enp36s0.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  # networking.resolvconf = {
  #   enable = true;
  #   useLocalResolver = true;    
  # };
  # networking.dhcpcd.extraConfig = "nohook resolv.conf";
  # networking.networkmanager.dns = "none";
  # services.coredns.enable = true;
  # services.coredns.config =
  #   ''
  #   . {
  #       forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
  #       cache
  #   }
  #   local {
  #     template IN A  {
  #       answer "{{ .Name }} 0 IN A 127.0.0.1"
  #     }
  #   }
  #   '';
  networking.firewall = {
    logReversePathDrops = true;
    extraCommands = ''
      ip46tables -t raw -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t raw -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t raw -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t raw -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
  };

  services.avahi = {
    nssmdns = true;
    enable = true;
    ipv4 = true;
    ipv6 = true;
  };
  
  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  nix = {
    allowedUsers = [ "@wheel" ];
  };  

  nixpkgs.config.allowUnfree = true;

  programs.sway.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware.system76.enableAll = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.ledger.enable = true;
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2c97"
  '';

  services.udev.packages = [ pkgs.yubikey-personalization pkgs.via ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  security.pam.services.swaylock = {
    text = "auth include login";
  };

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };

  services.pcscd.enable = true;

  services.printing.enable = true;
  services.printing.browsing = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation = {
    waydroid.enable = true;
    lxd.enable = true;
  };

  systemd.services.waydroid-container.enable = true;

  environment.systemPackages = with pkgs; [ git ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
