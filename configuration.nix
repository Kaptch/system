{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  greetd-cfg = config.services.greetd;
  greetd-tty = "tty${toString greetd-cfg.vt}";
in
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

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelModules = [ "v4l2loopback" ];

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  nix = {
    settings.allowed-users = [ "@wheel" ];
    package = pkgs.nixFlakes;
    settings.auto-optimise-store = true;
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
  # networking.nftables.enable = false;

  networking.firewall = {
    package = pkgs.iptables-legacy;
    logReversePathDrops = true;
    # extraCommands =
    # ''
    #   ip46tables -t raw -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
    #   ip46tables -t raw -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    # '';
    # ''
    #   ${pkgs.nftables}/bin/nft insert rule ip raw nixos-fw-rpfilter udp sport 51820 counter return
    #   ${pkgs.nftables}/bin/nft insert rule ip raw nixos-fw-rpfilter udp dport 51820 counter return
    # '';
    # extraStopCommands =
    # ''
    #   ip46tables -t raw -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
    #   ip46tables -t raw -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    # '';
    # ''
    #   ${pkgs.nftables}/bin/nft insert rule ip raw nixos-fw-rpfilter udp sport 51820 counter return || true
    #   ${pkgs.nftables}/bin/nft insert rule ip raw nixos-fw-rpfilter udp dport 51820 counter return || true
    # '';
  };
  services.tor = {
    enable = true;
    enableGeoIP = false;
    client.enable = true;
  };

  services.i2p.enable = true;

  # services.i2pd = {
  #   enable = true;
  #   proto.httpProxy.enable = true;
  # };

  services.udisks2.enable = true;

  containers.punchbox = {
    autoStart = false;
    ephemeral = true;
    extraFlags = [ "-U" ];

    config = { config, pkgs, ... }: {
      system.stateVersion = "22.05";

	    environment.systemPackages = with pkgs; [ openssh coreutils nftables ];

      users.users.bob = {
        isNormalUser  = true;
        password = "alice";
        shell = "${pkgs.coreutils}/bin/true";
      };

      services.openssh = {
        enable = true;
        ports = [20022];
        permitRootLogin = "no";
        passwordAuthentication = true;
        extraConfig = "
          AllowUsers bob
          Match User bob
            PermitOpen 127.0.0.1:20222
            X11Forwarding no
            AllowAgentForwarding no
            ForceCommand ${pkgs.coreutils}/bin/false
        ";
      };

      services.tor = {
        enable = true;
	      torsocks.allowInbound = true;
        enableGeoIP = false;
        relay.onionServices = {
          punchbox = {
            version = 3;
            map = [{
              port = 20022;
              target = {
                addr = "localhost";
                port = 20022;
              };
            }];
          };
        };
      };
    };
  };

  services.avahi = {
    nssmdns = true;
    enable = true;
    ipv4 = true;
    ipv6 = true;
  };

  services.upower = {
    enable = true;
  };

  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --cmd sway";
        user = "kaptch";
      };
    };
  };

  systemd.services.greetd = {
      unitConfig = {
        After = [
          "multi-user.target"
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
          "getty@${greetd-tty}.service"
        ];
      };
  };

  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
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

  # security.pam.services.swaylock = {
  #   text = "auth include login";
  # };

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };

  services.pcscd.enable = true;

  services.printing.enable = true;
  services.printing.browsing = true;

  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
    waydroid.enable = true;
    lxd.enable = true;
    virtualbox = {
      host.enable = true;
      host.enableExtensionPack = true;
    };
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
