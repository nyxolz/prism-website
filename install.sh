#!/bin/bash

DEFAULT_PRISM_URL="https://github.com/nyxolz/prism-website/releases/download/f/Prism.zip"
INTEL_PRISM_URL="https://github.com/nyxolz/prism-website/releases/download/y/Prism-intel.zip"
ROBLOX_ARM64_URL="https://setup.rbxcdn.com/mac/arm64/version-2fc79d515be6449d-RobloxPlayer.zip"
ROBLOX_INTEL_URL="https://setup.rbxcdn.com/mac/version-2fc79d515be6449d-RobloxPlayer.zip"
SUPPORTED_VERSION="0.746.0.7461264"
APP_NAME="Prism.app"

TEMP_DIR="/tmp/prism-installer"
ZIP_FILE="$TEMP_DIR/Prism.zip"
EXTRACT_DIR="$TEMP_DIR/extracted"
ROBLOX_ZIP="$TEMP_DIR/RobloxPlayer.zip"

mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

BLUE=$(tput setaf 4 2>/dev/null)
CYAN=$(tput setaf 6 2>/dev/null)
GREEN=$(tput setaf 2 2>/dev/null)
RED=$(tput setaf 1 2>/dev/null)
YELLOW=$(tput setaf 3 2>/dev/null)
GRAY=$(tput setaf 8 2>/dev/null)
BOLD=$(tput bold 2>/dev/null)
RESET=$(tput sgr0 2>/dev/null)

download() {
    URL="$1"
    DEST="$2"

    curl \
        -L \
        --fail \
        -# \
        "$URL" \
        -o "$DEST" \
        2>/dev/tty

    if [ $? -ne 0 ] || [ ! -s "$DEST" ]; then
        return 1
    fi

    return 0
}

success() {
    printf "\n  ${GREEN}✓${RESET} $1\n"
}

fail() {
    printf "\n  ${RED}✗${RESET} $1\n"
    exit 1
}

warn() {
    printf "\n  ${YELLOW}!${RESET} $1\n"
}

MACOS=$(sw_vers -productVersion)

if [ "$(uname -m)" = "arm64" ]; then
    CHIP="Apple Silicon"
else
    CHIP="Intel"
fi

MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/ {print $2}')

if [ -z "$MODEL" ]; then
    MODEL="Unknown Mac"
fi

clear

LEFT=$(cat <<'LOGO'
                                           
             %%%            *+             
          %%%%                  -          
       *####       +++******######%-       
      #####     ++       +++******###      
    %#****   =               +++++*****    
   %%#**+  =                   ====+++++   
  %%##**+.        %%@%%@@        ----====  
  ###**+-       ++***#%@@@.       #:-----  
 ******+.     @%.::=+#%%@-:.-     ##------ 
 ++++**+      %%#*.     %#-.:      ##----= 
 ====-*+     #@%##       ##*.-     **---== 
 %---:++      @%%%%     @##*+      ***-=== 
 %%::::++     @@@@@@@  %@@#*+     ****==== 
  %%=::.:       =-:.. #%@@%       ++++===  
  %%%##:..         :+*#%         ++++====  
   #####***-                   *++===-==   
    ******++++               *+=====-==    
      +++++++++===       ++++========     
       +++++============+++-======:=       
          ===============-=======          
             -====---:-=======             
LOGO
)

RIGHT=$(cat <<EOF
${BOLD}${BLUE}Prism Installer${RESET}
${GRAY}macOS Roblox External${RESET}

${BOLD}Developed by:${RESET}
${CYAN}•${RESET} kysonlol      github.com/kysonlol
${CYAN}•${RESET} nyxolz        github.com/nyxolz
${CYAN}•${RESET} sk            github.com/skdidit
${CYAN}•${RESET} Armorix Team  github.com/armorixteam

${BOLD}Contributors:${RESET}
${CYAN}•${RESET} imeowforcash  github.com/imeowforcash

${BOLD}Prism:${RESET}
${CYAN}•${RESET} v3 Public Beta

${BOLD}System:${RESET}
${CYAN}•${RESET} macOS $MACOS
${CYAN}•${RESET} $CHIP
${CYAN}•${RESET} $MODEL

${BOLD}Discord:${RESET}
${CYAN}•${RESET} discord.gg/prismmacos
EOF
)

paste \
    <(echo "$LEFT") \
    <(echo "$RIGHT") \
    | sed 's/	/        /g'

echo ""
printf "${GRAY}────────────────────────────────────────${RESET}\n"

get_roblox_version() {
    RPATH="$1/Roblox.app/Contents/Info.plist"
    if [ -f "$RPATH" ]; then
        defaults read "$1/Roblox.app/Contents/Info" CFBundleShortVersionString 2>/dev/null
    fi
}

install_roblox() {
    ROBLOX_URL_TO_USE="$1"
    ROBLOX_DEST="$2"
    ROBLOX_EXTRACT="$TEMP_DIR/roblox-extracted"

    printf "\n${BLUE}${BOLD}[!]${RESET} Downloading Roblox\n\n"

    download "$ROBLOX_URL_TO_USE" "$ROBLOX_ZIP" || fail "Failed to download Roblox"

    success "Roblox download complete"

    printf "\n${BLUE}${BOLD}[!]${RESET} Extracting Roblox\n\n"

    mkdir -p "$ROBLOX_EXTRACT"

    ditto -x -k "$ROBLOX_ZIP" "$ROBLOX_EXTRACT" \
        || fail "Could not extract Roblox zip"

    ROBLOX_APP=$(find "$ROBLOX_EXTRACT" -name "RobloxPlayer.app" -type d -print -quit)

    if [ -z "$ROBLOX_APP" ]; then
        ROBLOX_APP=$(find "$ROBLOX_EXTRACT" -name "Roblox.app" -type d -print -quit)
    fi

    [ -z "$ROBLOX_APP" ] && fail "Roblox.app not found in archive"

    success "Extraction complete"

    printf "\n${BLUE}${BOLD}[!]${RESET} Installing Roblox\n\n"

    mkdir -p "$ROBLOX_DEST"

    if [ -d "$ROBLOX_DEST/Roblox.app" ]; then
        rm -rf "$ROBLOX_DEST/Roblox.app" 2>/dev/null || sudo rm -rf "$ROBLOX_DEST/Roblox.app"
    fi

    cp -R "$ROBLOX_APP" "$ROBLOX_DEST/Roblox.app" 2>/dev/null

    if [ $? -ne 0 ]; then
        sudo cp -R "$ROBLOX_APP" "$ROBLOX_DEST/Roblox.app" || fail "Failed to install Roblox"
    fi

    success "Roblox installed to $ROBLOX_DEST"

    INSTALLED_VERSION=$(defaults read "$ROBLOX_DEST/Roblox.app/Contents/Info" CFBundleShortVersionString 2>/dev/null)

    if [ -z "$INSTALLED_VERSION" ]; then
        fail "Could not verify installed Roblox version"
    fi

    printf "\n  ${CYAN}Installed version:${RESET} $INSTALLED_VERSION\n"
}

sign_roblox() {
    ENTITLEMENTS_FILE="$TEMP_DIR/entitlements.plist"

    cat > "$ENTITLEMENTS_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://apple.com">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.get-task-allow</key>
    <true/>
</dict>
</plist>
EOF

    if [ -d "/Applications/Roblox.app" ]; then
        ROBLOX_APP_PATH="/Applications/Roblox.app"
    elif [ -d "$HOME/Applications/Roblox.app" ]; then
        ROBLOX_APP_PATH="$HOME/Applications/Roblox.app"
    else
        fail "Roblox.app not found for signing"
    fi

    if [ "$ROBLOX_APP_PATH" = "$HOME/Applications/Roblox.app" ]; then
        codesign --remove-signature "$ROBLOX_APP_PATH" 2>/dev/null
        codesign --force --deep --sign - --entitlements "$ENTITLEMENTS_FILE" "$ROBLOX_APP_PATH" || fail "Failed to sign Roblox"
    else
        codesign --remove-signature "$ROBLOX_APP_PATH" 2>/dev/null || sudo codesign --remove-signature "$ROBLOX_APP_PATH"
        codesign --force --deep --sign - --entitlements "$ENTITLEMENTS_FILE" "$ROBLOX_APP_PATH" 2>/dev/null || sudo codesign --force --deep --sign - --entitlements "$ENTITLEMENTS_FILE" "$ROBLOX_APP_PATH" || fail "Failed to sign Roblox"
    fi

    success "Roblox signed"
}

do_install_prism() {
    INSTALL_DIR="/Applications"
    ROBLOX_DEST="/Applications"

    if [ "$CHIP" = "Apple Silicon" ]; then
        PRISM_URL="$DEFAULT_PRISM_URL"
        ROBLOX_URL="$ROBLOX_ARM64_URL"
    else
        PRISM_URL="$INTEL_PRISM_URL"
        ROBLOX_URL="$ROBLOX_INTEL_URL"
    fi

    printf "\n${BLUE}${BOLD}[!]${RESET} Checking Roblox installation\n"

    VER_SYSTEM=$(get_roblox_version "/Applications")
    VER_USER=$(get_roblox_version "$HOME/Applications")

    if [ "$VER_SYSTEM" = "$SUPPORTED_VERSION" ] || [ "$VER_USER" = "$SUPPORTED_VERSION" ]; then
        printf "\n  ${GREEN}✓${RESET} ${BOLD}Congratulations, Prism supports your version${RESET} ${GRAY}($SUPPORTED_VERSION)${RESET}\n"
    else
        if [ -n "$VER_SYSTEM" ] && [ "$VER_SYSTEM" != "$SUPPORTED_VERSION" ]; then
            warn "Version mismatch detected"
            printf "  ${GRAY}Installed:${RESET}  $VER_SYSTEM\n"
            printf "  ${GRAY}Required:${RESET}   $SUPPORTED_VERSION\n"
            printf "\n  ${YELLOW}Installing the correct version automatically...${RESET}\n"
            install_roblox "$ROBLOX_URL" "$ROBLOX_DEST"
        elif [ -n "$VER_USER" ] && [ "$VER_USER" != "$SUPPORTED_VERSION" ]; then
            warn "Version mismatch detected"
            printf "  ${GRAY}Installed:${RESET}  $VER_USER\n"
            printf "  ${GRAY}Required:${RESET}   $SUPPORTED_VERSION\n"
            printf "\n  ${YELLOW}Installing the correct version automatically...${RESET}\n"
            install_roblox "$ROBLOX_URL" "$ROBLOX_DEST"
        else
            warn "Roblox is not installed"
            printf "  ${YELLOW}Prism requires Roblox $SUPPORTED_VERSION.${RESET}\n"
            printf "  ${GRAY}Installing the correct version automatically...${RESET}\n"
            install_roblox "$ROBLOX_URL" "$ROBLOX_DEST"
        fi
    fi

    printf "\n${GRAY}────────────────────────────────────────${RESET}\n"

    printf "\n${BLUE}${BOLD}[1/4]${RESET} Downloading Prism\n\n"

    download "$PRISM_URL" "$ZIP_FILE" || fail "Download failed"

    success "Download complete"

    printf "\n${BLUE}${BOLD}[2/4]${RESET} Extracting Prism\n\n"

    mkdir -p "$EXTRACT_DIR"

    ditto -x -k "$ZIP_FILE" "$EXTRACT_DIR" \
        || fail "Could not unzip archive"

    INNER=$(find "$EXTRACT_DIR" -name "*.zip" -print -quit)

    if [ -n "$INNER" ]; then
        ditto -x -k "$INNER" "$EXTRACT_DIR" \
            || fail "Could not extract application"
    fi

    APP_PATH=$(find "$EXTRACT_DIR" -name "$APP_NAME" -type d -print -quit)

    [ -z "$APP_PATH" ] && fail "Prism.app not found"

    success "Extraction complete"

    printf "\n${BLUE}${BOLD}[3/4]${RESET} Installing Prism\n\n"

    mkdir -p "$INSTALL_DIR"

    if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
        rm -rf "$INSTALL_DIR/$APP_NAME" 2>/dev/null || sudo rm -rf "$INSTALL_DIR/$APP_NAME"
    fi

    chown -R "$(whoami)" "$APP_PATH"

    cp -R "$APP_PATH" "$INSTALL_DIR/$APP_NAME" 2>/dev/null

    if [ $? -ne 0 ]; then
        sudo cp -R "$APP_PATH" "$INSTALL_DIR/$APP_NAME" || fail "Installation failed"
    fi

    success "Prism installed to $INSTALL_DIR"

    printf "\n${BLUE}${BOLD}[4/4]${RESET} Signing Roblox\n\n"

    sign_roblox

    printf "\n${BLUE}${BOLD}[5/5]${RESET} Clearing quarantine\n\n"

    xattr -cr "$INSTALL_DIR/$APP_NAME" 2>/dev/null || sudo xattr -cr "$INSTALL_DIR/$APP_NAME"

    success "Quarantine cleared"

    echo ""
    printf "${GREEN}${BOLD}✓ Prism is ready!${RESET}\n"
    printf "${GRAY}Open Prism from Applications.${RESET}\n"
    echo ""
}

do_uninstall_prism() {
    printf "\n${BLUE}${BOLD}[!]${RESET} Uninstalling Prism\n\n"

    REMOVED=0

    for TARGET in \
        "/Applications/$APP_NAME" \
        "$HOME/Applications/$APP_NAME" \
        "$HOME/prism"
    do
        if [ -d "$TARGET" ]; then
            rm -rf "$TARGET" 2>/dev/null || sudo rm -rf "$TARGET"
            success "Removed $TARGET"
            REMOVED=1
        fi
    done

    if [ "$REMOVED" -eq 0 ]; then
        warn "Prism is not installed"
    else
        echo ""
        printf "${GREEN}${BOLD}✓ Prism has been uninstalled.${RESET}\n"
    fi

    echo ""
}

printf "\n${BOLD}What would you like to do?${RESET}\n\n"
printf "  ${CYAN}[1]${RESET} Install Prism\n"
printf "  ${CYAN}[2]${RESET} Uninstall Prism\n"
printf "  ${CYAN}[3]${RESET} Exit Installer\n"
printf "\n  ${GRAY}Enter option:${RESET} "

read -r MAIN_CHOICE < /dev/tty

case "$MAIN_CHOICE" in
    1)
        printf "\n${GRAY}────────────────────────────────────────${RESET}\n"
        do_install_prism
        ;;
    2)
        printf "\n${GRAY}────────────────────────────────────────${RESET}\n"
        do_uninstall_prism
        ;;
    3)
        echo ""
        printf "${GRAY}Exiting installer.${RESET}\n"
        echo ""
        exit 0
        ;;
    *)
        fail "Invalid option"
        ;;
esac
