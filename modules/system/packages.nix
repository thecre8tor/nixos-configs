# System-wide packages configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Allow non-opensource softwares
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  # You can use https://search.nixos.org/ to find more packages (and options)
  environment.systemPackages = with pkgs; [
    # Core utilities
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wezterm
    helix

    # Rust development tools
    rustc # Rust compiler
    cargo # Rust package manager
    rust-analyzer # IDE support
    rustfmt # Formatter
    clippy # Linter
    cargo-watch # Auto-rebuild on file changes
    cargo-edit # cargo add/rm commands
    sqlx-cli
    lldb
    clang
    lld

    # Other development tools
    typescript-language-server
    llvm
    nixfmt
    openssl
    openssl.dev

    # Desktop customization (Garuda-like)
    whitesur-gtk-theme
    tela-icon-theme
    papirus-icon-theme
    bibata-cursors
    gnome-tweaks
    gnome-extension-manager
    adw-gtk3
    nerd-fonts.jetbrains-mono

    # Sway customization
    # swaylock
    # swayidle
    # waybar
    # wofi

    # Fingerprint
    fprintd

    # TOML language servers
    taplo
    tombi

    # Codelldb Seamlink
    (pkgs.writeShellScriptBin "codelldb" ''
      exec ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb "$@"
    '')

    # Setup dotfiles repo using stow
    stow
    claude-code
    ngrok
    antares
    tiny-rdm
    zed-editor
    dbeaver-bin
    mission-center

    # AMD's own s2idle/s0ix analysis tooling, from the maintainer of the
    # amd_pmc driver. Provides amd-s2idle (plus amd-bios, amd-pstate,
    # amd-ttm). Used to diagnose the Cezanne wake hang documented in
    # boot.nix; the kernel docs point at this before filing anything at
    # drm/amd gitlab.
    #
    #   sudo amd-s2idle test --count 10 --duration 30 --format html
    #
    # Note it only captures state *after* a successful resume, so it will
    # never see the hard hang itself — that is what the pm_trace toggle in
    # boot.nix is for. This provides the supporting report.
    #
    # nixpkgs only wires up dbus-fast, but validator.py's --logind path
    # imports dbus-python. Without it the run dies on an UnboundLocalError
    # (upstream's `except dbus.exceptions.DBusException` is evaluated before
    # its own `except ImportError` can catch the missing module).
    (amd-debug-tools.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ [ python3Packages.dbus-python ];
    }))
  ];

  # Fonts
  fonts.packages = with pkgs; [
    # nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
    inter
    roboto
    jetbrains-mono
  ];

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      sansSerif = [ "Inter" ];
      serif = [ "Noto Serif" ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Environment variables for development
  environment.variables = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  # Programs
  programs.firefox.enable = false;
  programs.zsh.enable = true;
}
