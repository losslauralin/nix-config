# modules/hacking/default.nix
#
# Domain: 渗透攻防 — 安全工具箱核心
{inputs, ...}: {
  lossilk.hacking = {
    nixos = {
      environment.etc.hosts.mode = "0644";
      programs.wireshark.enable = true;
    };

    user.extraGroups = [
      "wireshark"
    ];

    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = with pkgs; [
        wordlists
        (writeScriptBin "wlfuzz" ''
          #!${lib.getExe nushell}

          ${lib.getExe television} files ${wordlists}/share/wordlists -s "fd . -t l" -p "${lib.getExe bat} {}"
            | $"${wordlists}/share/wordlists/($in)"
            | tee { print $in }
            | ${lib.getExe' wl-clipboard "wl-copy"}
        '')

        nmap
        theharvester
        enum4linux-ng
        smbmap
        gobuster
        feroxbuster
        sherlock
        amass
        waymore
        subfinder
        alterx
        dnsx
        naabu
        httpx
        nuclei
        uncover
        cloudlist
        tlsx
        notify
        mapcidr
        interactsh
        katana
        cvemap
        shuffledns
        massdns
        uro
        secrethound
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.gf

        sqlmap
        bruno
        arjun
        exploitdb
        responder
        netexec
        python3Packages.impacket

        aircrack-ng
        volatility3
        binwalk
        exiftool
        stress-ng

        wireshark
        bettercap
        python3Packages.scapy
        mitmproxy
        mitmproxy2swagger

        thc-hydra
        hashcat
        hashcat-utils
        john

        whatweb
        zap
        firefox-bin
        ffuf
        xh
        wpscan
        dalfox
        wafw00f
        graphw00f

        ghidra
        imhex
        social-engineer-toolkit
        python314Packages.bloodyad
        tor-browser
        (writeScriptBin "cyberchef" ''
          #!${pkgs.runtimeShell}
          exec ${lib.getExe' xdg-utils "xdg-open"} ${cyberchef}/share/cyberchef/index.html
        '')

        rustscan
        metasploit
      ];
    };
  };
}
