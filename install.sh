#!/bin/bash

DEFAULT_PRISM_URL="https://github.com/ArmorixTeam/Prism-Releases/releases/download/v1.0-beta/v1.0-public-beta-default.zip"
USERMODE_PRISM_URL="https://github.com/ArmorixTeam/Prism-Releases/releases/download/v1.0-beta/v1.0.public-beta-usermode.zip"
ROBLOX_URL="https://setup.rbxcdn.com/mac/arm64/version-3bc33ee7ffad426f-RobloxPlayer.zip"
SUPPORTED_VERSION="0.741.0.7411056"
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

bar() {
    PERCENT=$1
    WIDTH=30
    FILLED=$((PERCENT * WIDTH / 100))
    EMPTY=$((WIDTH - FILLED))
    BAR=""
    i=0
    while [ $i -lt $FILLED ]; do
        BAR="${BAR}━"
        i=$((i+1))
    done
    i=0
    while [ $i -lt $EMPTY ]; do
        BAR="${BAR}─"
        i=$((i+1))
    done
    printf "\r  ${CYAN}${BAR}${RESET} %s%%" "$PERCENT"
}

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
${CYAN}•${RESET} Armorix Team  github.com/armorixteam

${BOLD}Contributors:${RESET}
${CYAN}•${RESET} imeowforcash  github.com/imeowforcash

${BOLD}Prism:${RESET}
${CYAN}•${RESET} v1.0 Public Beta

${BOLD}System:${RESET}
${CYAN}•${RESET} macOS $MACOS
${CYAN}•${RESET} $CHIP
${CYAN}•${RESET} $MODEL
EOF
)

paste \
    <(echo "$LEFT") \
    <(echo "$RIGHT") \
    | sed 's/	/        /g'

echo ""
printf "${GRAY}────────────────────────────────────────${RESET}\n"

install_roblox() {
    ROBLOX_DEST="$1"
    ROBLOX_EXTRACT="$TEMP_DIR/roblox-extracted"

    printf "\n${BLUE}${BOLD}[!]${RESET} Downloading Roblox $SUPPORTED_VERSION\n\n"

    download "$ROBLOX_URL" "$ROBLOX_ZIP" || fail "Failed to download Roblox"

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

get_roblox_version() {
    RPATH="$1/Roblox.app/Contents/Info.plist"
    if [ -f "$RPATH" ]; then
        defaults read "$1/Roblox.app/Contents/Info" CFBundleShortVersionString 2>/dev/null
    fi
}

do_install_prism() {
    PRISM_URL="$1"
    INSTALL_DIR="$2"

    if [ "$INSTALL_DIR" = "$HOME/Applications" ]; then
        ROBLOX_DEST="$HOME/Applications"
    else
        ROBLOX_DEST="/Applications"
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
            install_roblox "$ROBLOX_DEST"
        elif [ -n "$VER_USER" ] && [ "$VER_USER" != "$SUPPORTED_VERSION" ]; then
            warn "Version mismatch detected"
            printf "  ${GRAY}Installed:${RESET}  $VER_USER\n"
            printf "  ${GRAY}Required:${RESET}   $SUPPORTED_VERSION\n"
            printf "\n  ${YELLOW}Installing the correct version automatically...${RESET}\n"
            install_roblox "$ROBLOX_DEST"
        else
            warn "Roblox is not installed"
            printf "  ${YELLOW}Prism requires Roblox $SUPPORTED_VERSION.${RESET}\n"
            printf "  ${GRAY}Installing the correct version automatically...${RESET}\n"
            install_roblox "$ROBLOX_DEST"
        fi
    fi

    printf "\n${GRAY}────────────────────────────────────────${RESET}\n"

    printf "\n${BLUE}${BOLD}[1/3]${RESET} Downloading Prism\n\n"

    download "$PRISM_URL" "$ZIP_FILE" || fail "Download failed"

    success "Download complete"

    printf "\n${BLUE}${BOLD}[2/3]${RESET} Extracting Prism\n\n"

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

    printf "\n${BLUE}${BOLD}[3/3]${RESET} Installing Prism\n\n"

    mkdir -p "$INSTALL_DIR"

    if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
        rm -rf "$INSTALL_DIR/$APP_NAME" 2>/dev/null || sudo rm -rf "$INSTALL_DIR/$APP_NAME"
    fi

    cp -R "$APP_PATH" "$INSTALL_DIR/$APP_NAME" 2>/dev/null

    if [ $? -ne 0 ]; then
        sudo cp -R "$APP_PATH" "$INSTALL_DIR/$APP_NAME" || fail "Installation failed"
    fi

    success "Prism installed to $INSTALL_DIR"

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
        printf "\n${BOLD}Select install mode:${RESET}\n\n"
        printf "  ${CYAN}[a]${RESET} Default\n"
        printf "  ${CYAN}[b]${RESET} Usermode\n\n"
        printf "  ${GRAY}*${RESET} Default mode installs directly into /Applications, whilst usermode\n"
        printf "    installs a custom version of Prism into ~/Applications, your user\n"
        printf "    directory, and stripes Prism features that require an administrator\n"
        printf "    password. Default requires you to be logged into an Administrator\n"
        printf "    account, and is installed for every user.\n"
        printf "\n  ${GRAY}Enter option:${RESET} "

        read -r MODE_CHOICE < /dev/tty

        case "$MODE_CHOICE" in
            a|A)
                printf "\n${GRAY}────────────────────────────────────────${RESET}\n"
                do_install_prism "$DEFAULT_PRISM_URL" "/Applications"
                ;;
            b|B)
                printf "\n${GRAY}────────────────────────────────────────${RESET}\n"
                do_install_prism "$USERMODE_PRISM_URL" "$HOME/Applications"
                ;;
            *)
                fail "Invalid option"
                ;;
        esac
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
