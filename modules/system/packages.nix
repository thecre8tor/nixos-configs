# System-wide packages configuration
{ config, lib, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  # You can use https://search.nixos.org/ to find more packages (and options)
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    wezterm
    helix

    # Rust development tools
    rustc          # Rust compiler
    cargo          # Rust package manager
    rust-analyzer  # IDE support
    rustfmt        # Formatter
    clippy         # Linter
    cargo-watch    # Auto-rebuild on file changes
    cargo-edit     # cargo add/rm commands
    sqlx-cli
    lldb
    clang
    lld

    # Other development tools
    typescript-language-server
    llvm
    nixfmt-rfc-style
    openssl
    openssl.dev
    pkg-config

    # Desktop customization (Garuda-like)
    orchis-theme
    whitesur-gtk-theme
    tela-icon-theme
    papirus-icon-theme
    bibata-cursors
    gnome-tweaks
    gnome-extension-manager
    adw-gtk3
    nerd-fonts.jetbrains-mono

    # Fingerprint
    fprintd
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Environment variables for development
  environment.variables = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  # Programs
  programs.firefox.enable = true;
  programs.zsh.enable = true;
}
