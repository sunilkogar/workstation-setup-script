#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Oh My Zsh
install_ohmyzsh() {
    local package_description="Oh My Zsh"
    
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "$package_description is already installed."
        return 0
    fi
    
    # Install Oh My Zsh
    echo "Installing $package_description..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    # Verify installation
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "$package_description has been successfully installed."
        return 0
    else
        echo "Failed to install $package_description."
        return 1
    fi
}

# Function to install a package via Homebrew
install_brew_package() {
    local package_name=$1
    local package_description=$2
    
    # Check if the package is already installed
    if command_exists "$package_name"; then
        echo "$package_description is already installed."
        return 0
    fi
    
    # Install the package via Homebrew
    echo "Installing $package_description..."
    if brew install "$package_name"; then
        echo "$package_description installed successfully."
        
        # Additional setup for asdf if package_name is "asdf"
        if [ "$package_name" == "asdf" ]; then
            echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> "${ZDOTDIR:-~}/.zshrc"
            echo "Added ASDF initialization to .zshrc."
            source "${ZDOTDIR:-~}/.zshrc"
            echo "Sourced .zshrc"
        fi
        
        return 0
    else
        echo "Failed to install $package_description."
        return 1
    fi
}

# Function to install a cask package via Homebrew
install_brew_cask() {
    local package_name=$1
    local package_description=$2
    
    # Check if the cask package is already installed
    if brew list --cask | grep -q "$package_name"; then
        echo "$package_description is already installed."
        return 0
    fi
    
    # Install the cask package via Homebrew
    echo "Installing $package_description..."
    if brew install --cask "$package_name"; then
        echo "$package_description installed successfully."
        return 0
    else
        echo "Failed to install $package_description."
        return 1
    fi
}

# Function to install a plugin version using ASDF
install_asdf_version() {
    local plugin=$1
    local version=$2
    local plugin_description=$3
    
    # Check if ASDF is installed
    if ! command_exists asdf; then
        echo "ASDF is not installed. Please install ASDF first."
        return 1
    fi
    
    # Check if the plugin version is already installed
    if asdf list "$plugin" 2>/dev/null | grep -q "$version"; then
        echo "$plugin_description $version is already installed via ASDF."
        return 0
    fi
    
    # Install the plugin version using ASDF
    echo "Installing $plugin_description $version via ASDF..."
    if asdf install "$plugin" "$version" &>/dev/null; then
        echo "$plugin_description $version installed successfully via ASDF."
        echo "$plugin $version" >> "${ASDF_DIR:-$HOME}/.tool-versions"
        echo "Added $plugin $version to ~/.tool-versions."
        return 0
    else
        echo "Failed to install $plugin_description $version via ASDF."
        return 1
    fi
}

# Read tool versions from file
read_asdf_plugin_versions() {
    while IFS= read -r line; do
        tool_name=$(echo "$line" | awk '{print $1}')
        tool_version=$(echo "$line" | awk '{print $2}')
        case "$tool_name" in
            "java") java_version="$tool_version" ;;
            "maven") maven_version="$tool_version" ;;
            "gradle") gradle_version="$tool_version" ;;
            *) echo "Unknown tool: $tool_name" ;;
        esac
    done < asdf_plugin_versions.txt
}

# Initialize array to track failed installations
failed_installs=()

# Install Homebrew (if not already installed)
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Install all packages via Homebrew (non-cask)
install_brew_package git "Git"
install_brew_package zsh "Zsh"
install_brew_package docker-compose "Docker Compose"
install_brew_package colima "Colima"
install_brew_package asdf "ASDF version manager"
install_brew_package jq "JSON processor"
install_brew_package awscli "AWS command-line interface"

install_ohmyzsh

# Install all packages via Homebrew (casks)
install_brew_cask brave-browser "Brave Browser"
install_brew_cask iterm2 "iterm2"
install_brew_cask google-chrome "Google Chrome"
install_brew_cask firefox "Firefox"
install_brew_cask docker "Docker"
install_brew_cask sourcetree "SourceTree"
install_brew_cask obsidian "Obsidian"
install_brew_cask rectangle "Rectangle"
install_brew_cask 1password "1Password"
install_brew_cask visual-studio-code "Visual Studio Code"

# Read tool versions from file
read_asdf_plugin_versions

# Install ASDF plugins
echo "Installing ASDF plugins..."
install_asdf_version java "$java_version" "Java"
install_asdf_version maven "$maven_version" "Maven"
install_asdf_version gradle "$gradle_version" "Gradle"

# Print summary of failed installations
if [ ${#failed_installs[@]} -eq 0 ]; then
    echo "All installations completed successfully!"
else
    echo "Some installations failed:"
    for package in "${failed_installs[@]}"; do
        echo " - $package"
    done
fi
