# Alexander's NixOS Configuration

A modular, flake-based NixOS configuration with Home Manager integration.

## 📁 Directory Structure

```
nixos-configs/
├── flake.nix                      # Main flake configuration
├── flake.lock                     # Locked dependencies (auto-generated)
├── hosts/                         # Host-specific configurations
│   └── nixos/                     # Configuration for "nixos" machine
│       ├── configuration.nix      # Main host configuration
│       └── hardware-configuration.nix  # Hardware-specific settings (auto-generated)
├── modules/                       # Reusable configuration modules
│   ├── system/                    # System-wide modules
│   │   ├── boot.nix              # Bootloader configuration
│   │   ├── networking.nix        # Network settings
│   │   ├── locale.nix            # Time zone and locale
│   │   ├── audio.nix             # Audio (PipeWire) configuration
│   │   ├── desktop.nix           # Desktop environment (GNOME/GDM)
│   │   ├── services.nix          # System services (Flatpak, SSH, etc.)
│   │   ├── virtualization.nix    # Docker and virtualization
│   │   ├── packages.nix          # System-wide packages
│   │   ├── nix.nix               # Nix-specific settings (flakes, etc.)
│   │   └── maintenance.nix       # Auto-updates and garbage collection
│   └── users/                     # User-specific modules
│       └── alexander.nix         # User account configuration
├── home/                          # Home Manager configurations
│   └── alexander.nix             # Home Manager config for alexander
└── README.md                      # This file
```

## 🚀 Quick Start

### Initial Setup

1. **Clone this repository** (if not already done):
   ```bash
   cd ~
   # Your configs are already here in ~/nixos-configs
   ```

2. **Initialize Git** (recommended):
   ```bash
   cd ~/nixos-configs
   git init
   git add .
   git commit -m "Initial NixOS configuration"
   ```

### Building and Switching

Build and activate the configuration:
```bash
sudo nixos-rebuild switch --flake ~/nixos-configs#nixos
```

### Other Useful Commands

**Test changes without activating** (temporary until reboot):
```bash
sudo nixos-rebuild test --flake ~/nixos-configs#nixos
```

**Build without activating** (just check if it works):
```bash
sudo nixos-rebuild build --flake ~/nixos-configs#nixos
```

**Update all flake inputs** (nixpkgs, home-manager):
```bash
nix flake update ~/nixos-configs
```

**Update specific input only**:
```bash
nix flake lock --update-input nixpkgs ~/nixos-configs
```

## 🔧 System Configuration

### Current Setup

- **Host**: nixos (AMD system)
- **Bootloader**: systemd-boot with EFI
- **Desktop**: GNOME with GDM
- **Audio**: PipeWire
- **Shell**: Zsh (default for alexander)
- **Network**: NetworkManager
- **Time Zone**: Africa/Lagos
- **Virtualization**: Docker enabled

### Installed Applications

#### System Packages
- **Editors**: Vim, Helix, Neovim
- **Terminals**: WezTerm
- **Browsers**: Firefox
- **Development Tools**: 
  - Rust toolchain (rustc, cargo, rust-analyzer, clippy, rustfmt)
  - Node.js, TypeScript
  - Git, GCC, LLVM, Clang
  - Nix formatters

#### Flatpak Applications
- DBeaver Community (database tool)
- Spotify

#### Theming
- Orchis Theme
- WhiteSur GTK Theme
- Tela Icon Theme
- Papirus Icon Theme
- Bibata Cursors
- JetBrains Mono Nerd Font

## 📝 Making Changes

### Adding a System Package

Edit `modules/system/packages.nix`:
```nix
environment.systemPackages = with pkgs; [
  # ... existing packages ...
  your-new-package
];
```

### Adding a User Package

Edit `home/alexander.nix`:
```nix
home.packages = with pkgs; [
  # ... existing packages ...
  your-new-package
];
```

### Enabling a Commented Feature

Many features are commented out for future use. To enable them:

1. Find the relevant module (e.g., `modules/system/services.nix` for SSH)
2. Uncomment the desired lines
3. Rebuild: `sudo nixos-rebuild switch --flake ~/nixos-configs#nixos`

Examples:
- **Enable SSH**: Uncomment in `modules/system/services.nix`
- **Enable Printing**: Uncomment in `modules/system/services.nix`
- **Change Locale**: Uncomment in `modules/system/locale.nix`
- **Enable Qtile**: Uncomment in `modules/system/desktop.nix`

### Creating a New Module

1. Create a new `.nix` file in the appropriate directory
2. Add it to the imports in `hosts/nixos/configuration.nix`
3. Write your configuration using the standard module structure:

```nix
{ config, lib, pkgs, ... }:

{
  # Your configuration here
}
```

## 🏠 Home Manager

Home Manager manages user-specific configuration (dotfiles, user packages, etc.).

### Current Home Manager Setup
- **Shell**: Zsh with Spaceship prompt
- **Git**: Configured with user details
- **Packages**: Development tools (neovim, ripgrep, nodejs, etc.)

### Using Dotfiles

The configuration includes commented-out dotfile management. To enable:

1. Create a `config/` directory in this repo:
   ```bash
   mkdir -p ~/nixos-configs/config
   ```

2. Add your dotfiles (e.g., `qtile/`, `nvim/`, etc.)

3. Uncomment the relevant sections in `home/alexander.nix`:
   ```nix
   configs = {
     qtile = "qtile";
     nvim = "nvim";
     # ... etc
   };
   
   xdg.configFile = builtins.mapAttrs (name: subpath: {
     source = create_symlink "${dotfiles}/${subpath}";
     recursive = true;
   }) configs;
   ```

## 🔄 Maintenance

### Automatic Maintenance

The system is configured for automatic maintenance:
- **Updates**: Weekly system updates
- **Garbage Collection**: Daily cleanup of old generations (keeps last 10 days)
- **Store Optimization**: Automatic deduplication

### Manual Maintenance

**List all generations**:
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

**Delete old generations**:
```bash
sudo nix-collect-garbage --delete-older-than 30d
```

**Delete all old generations** (keep only current):
```bash
sudo nix-collect-garbage -d
```

**Optimize the Nix store**:
```bash
nix-store --optimize
```

## 🌐 Adding a New Machine

1. Create a new directory under `hosts/`:
   ```bash
   mkdir -p ~/nixos-configs/hosts/laptop
   ```

2. Generate hardware configuration on the new machine:
   ```bash
   nixos-generate-config --show-hardware-config > ~/nixos-configs/hosts/laptop/hardware-configuration.nix
   ```

3. Create `configuration.nix` for the new host:
   ```nix
   { config, lib, pkgs, ... }:
   
   {
     imports = [
       ./hardware-configuration.nix
       ../../modules/system/boot.nix
       # ... import relevant modules ...
     ];
     
     system.stateVersion = "25.11";
   }
   ```

4. Add to `flake.nix`:
   ```nix
   outputs = { self, nixpkgs, home-manager, ... }: {
     nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       modules = [
         ./hosts/laptop/configuration.nix
         # ... home-manager config ...
       ];
     };
   };
   ```

5. Build on the new machine:
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-configs#laptop
   ```

## 🐛 Troubleshooting

### Build Fails

1. Check syntax errors: `nix flake check ~/nixos-configs`
2. Try building without switching: `sudo nixos-rebuild build --flake ~/nixos-configs#nixos`
3. Check the detailed error output

### Rollback to Previous Generation

If something breaks after a rebuild:
```bash
sudo nixos-rebuild switch --rollback
```

Or reboot and select a previous generation from the bootloader menu.

### Home Manager Issues

Rebuild only Home Manager:
```bash
home-manager switch --flake ~/nixos-configs#alexander
```

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [NixOS Packages Search](https://search.nixos.org/packages)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)

## 📄 License

This configuration is personal and provided as-is for reference.

## 👤 Author

**Alexander Nitiola**
- Email: cre8tor.alexander@gmail.com
- GitHub: [Your GitHub URL]

---

**NixOS Version**: 25.11  
**Last Updated**: February 2026
