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
    nixfmt-rfc-style
    openssl
    openssl.dev

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

    # Sway customization
    swaylock
    swayidle
    waybar
    wofi
    foot

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
  programs.firefox.enable = false;
  programs.zsh.enable = true;
}
