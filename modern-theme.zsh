# Modern ZSH Theme
# Author: Ravindra Singh
# Github: BadRat-in
# License: MIT
#
# A modern and elegant ZSH theme that adapts to light and dark terminal themes.
# Features:
# - Automatic light/dark theme detection
# - Rainbow directory path
# - Git status integration
# - Command execution time
# - Username and host display
# - Error status indication
# - Clean and minimal design

#------------------------------------------------------------------------------
# Theme Detection
#------------------------------------------------------------------------------

# Function: detect_terminal_theme
# Description: Detects whether the terminal is using a light or dark theme
# Returns: "light" or "dark"
# The detection works across different terminal emulators:
# - Apple Terminal
# - iTerm2
# - GNOME Terminal
# - Konsole
# Also handles terminal multiplexers like tmux and screen
function detect_terminal_theme() {
    local fallback_theme="dark"

    # Detect terminal app
    local terminal_app="${TERM_PROGRAM:-$TERM}"
    local bg_color=""
    local running_in_app=""

    # Check if running inside another app (e.g., tmux or screen)
    if [[ "$TERM" == "screen"* || "$TERM" == "tmux"* ]]; then
        running_in_app="true"
        terminal_app="tmux/screen"
    fi

    # Terminal-specific background color retrieval
    case "$terminal_app" in
        "Apple_Terminal")
            bg_color=$(osascript -e '
            tell application "Terminal"
                set bgColor to background color of selected tab of front window
                return item 1 of bgColor as integer
            end tell' 2>/dev/null)
            ;;
        "iTerm.app")
            bg_color=$(osascript -e '
            tell application "iTerm"
                tell current session of current tab of current window
                    set bgColor to background color
                    return item 1 of bgColor
                end tell
            end tell' 2>/dev/null)
            ;;
        *"gnome-terminal"*)
            bg_color=$(gsettings get org.gnome.desktop.background picture-options 2>/dev/null || echo "")
            ;;
        *"konsole"*)
            bg_color=$(grep "Background" ~/.config/konsolerc 2>/dev/null | awk -F '=' '{print $2}' || echo "")
            ;;
        *)
            bg_color=""
            ;;
    esac

    # Determine theme based on the background color
    if [[ -n "$bg_color" ]]; then
        if [[ "$bg_color" =~ ^[0-9]+$ ]] && [[ "$bg_color" -lt 128 ]]; then
            echo "dark"
        else
            echo "light"
        fi
    else
        echo "$fallback_theme"
    fi
}

#------------------------------------------------------------------------------
# Color Configuration
#------------------------------------------------------------------------------

# Function: set_colors_based_on_theme
# Description: Sets up color schemes based on the detected terminal theme
# The color schemes are optimized for readability in both light and dark themes
function set_colors_based_on_theme() {
    local theme
    theme=$(detect_terminal_theme)
    
    if [[ "$theme" == "dark" ]]; then
        # Dark theme colors - Optimized for dark backgrounds
        typeset -g DEFAULT_COLOR=$'%f'
        typeset -g DEFAULT_BG=$'%k'
        typeset -g PROMPT_COLOR=$'%F{033}'          # Bright blue
        typeset -g DIR_COLOR=$'%F{081}'             # Light cyan
        typeset -g GIT_CLEAN_COLOR=$'%F{118}'       # Bright green
        typeset -g GIT_DIRTY_COLOR=$'%F{203}'       # Bright red
        typeset -g GIT_BRANCH_COLOR=$'%F{140}'      # Bright magenta
        typeset -g TIME_COLOR=$'%F{248}'            # Light gray
        typeset -g USER_COLOR=$'%F{226}'            # Bright yellow
        typeset -g WHITE_COLOR=$'%F{255}'           # Pure white
        
        # Rainbow colors for dark theme - Vibrant colors
        typeset -g RAINBOW_COLORS=(
            $'%F{208}'  # Bright orange
            $'%F{220}'  # Bright yellow
            $'%F{082}'  # Bright green
            $'%F{039}'  # Bright blue
            $'%F{171}'  # Deep purple
            $'%F{033}'  # Deep blue
        )
    else
        # Light theme colors - Optimized for light backgrounds
        typeset -g DEFAULT_COLOR=$'%f'
        typeset -g DEFAULT_BG=$'%k'
        typeset -g PROMPT_COLOR=$'%F{033}'          # Dark blue
        typeset -g DIR_COLOR=$'%F{024}'             # Dark cyan
        typeset -g GIT_CLEAN_COLOR=$'%F{022}'       # Dark green
        typeset -g GIT_DIRTY_COLOR=$'%F{203}'       # Dark red
        typeset -g GIT_BRANCH_COLOR=$'%F{090}'      # Dark magenta
        typeset -g TIME_COLOR=$'%F{238}'            # Dark gray
        typeset -g USER_COLOR=$'%F{094}'            # Dark gold
        typeset -g WHITE_COLOR=$'%F{232}'           # Almost black
        
        # Rainbow colors for light theme - Darker, more visible colors
        typeset -g RAINBOW_COLORS=(
            $'%F{166}'  # Dark orange
            $'%F{136}'  # Dark yellow
            $'%F{028}'  # Dark green
            $'%F{018}'  # Dark blue
            $'%F{161}'  # Dark purple
            $'%F{033}'  # Dark blue
        )
    fi
}

# Initialize colors
set_colors_based_on_theme

# Text formatting
typeset -g BOLD_TEXT=$(tput bold)           # Make text bold
typeset -g NORMAL_TEXT=$(tput sgr0)         # Reset text formatting

#------------------------------------------------------------------------------
# Git Integration
#------------------------------------------------------------------------------

# Git status symbols
typeset -g GIT_CLEAN_SYMBOL='✓'
typeset -g GIT_DIRTY_SYMBOL='✗'
typeset -g GIT_PREFIX=' & '
typeset -g GIT_SUFFIX=''

# Function: git_prompt_info
# Description: Displays the current git branch name
function git_prompt_info() {
    local ref
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    echo "$GIT_PREFIX$GIT_BRANCH_COLOR${ref#refs/heads/}$DEFAULT_COLOR$GIT_SUFFIX"
}

# Function: git_prompt_status
# Description: Shows git repository status (clean/dirty)
function git_prompt_status() {
    local STATUS=""
    local -a FLAGS
    FLAGS=('--porcelain')

    if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]; then
        FLAGS+='--untracked-files=no'
    fi
    
    STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
    if [[ -n $STATUS ]]; then
        echo " $GIT_DIRTY_COLOR$GIT_DIRTY_SYMBOL$DEFAULT_COLOR"
    else
        echo " $GIT_CLEAN_COLOR$GIT_CLEAN_SYMBOL$DEFAULT_COLOR"
    fi
}

#------------------------------------------------------------------------------
# Directory Path
#------------------------------------------------------------------------------

# Function: rainbow_path
# Description: Creates a colorful directory path with different colors for each component
function rainbow_path() {
    local path_parts=("${(s:/:)PWD}")
    local colored_path=""
    local index=1

    for part in $path_parts; do
        if [[ -n $part ]]; then
            local color_index=$(( (index - 1) % ${#RAINBOW_COLORS[@]} ))
            colored_path+="${RAINBOW_COLORS[$color_index+1]}$part$DEFAULT_COLOR/"
            ((index++))
        fi
    done

    colored_path="${colored_path%/}"
    colored_path="${colored_path/#$HOME/${RAINBOW_COLORS[1]}~}"
    echo "${colored_path}"
}

#------------------------------------------------------------------------------
# Command Execution Timer
#------------------------------------------------------------------------------

# Function: preexec
# Description: Called just before command execution
function preexec() {
    timer=$(date +%s)
}

# Function: precmd
# Description: Called before each prompt display
function precmd() {
    if [ $timer ]; then
        now=$(date +%s)
        elapsed=$((now - timer))

        if [ $elapsed -gt 60 ]; then
            timer_show="${elapsed}s"
        else
            timer_show="${elapsed}s"
        fi
        unset timer
    fi
}

#------------------------------------------------------------------------------
# Prompt Configuration
#------------------------------------------------------------------------------

# Enable prompt substitution
setopt PROMPT_SUBST

# Main prompt configuration
# Format: ╭─ username@directory git_branch git_status
#        ╰─❯
PROMPT=$'${PROMPT_COLOR}╭─ ${BOLD_TEXT}${USER_COLOR}%n${WHITE_COLOR}@${DEFAULT_COLOR}$(rainbow_path)${DEFAULT_COLOR}$(git_prompt_info)$(git_prompt_status)\n${NORMAL_TEXT}${DEFAULT_COLOR}${PROMPT_COLOR}╰─${DEFAULT_COLOR}%(?.%F{078}.%F{203})%(?.❯%F{255}.❯%F{203})%f '

# Right prompt configuration
# Format: HH:MM:SS [execution_time]
RPROMPT=$'${TIME_COLOR}%*${timer_show:+" took ${TIME_COLOR}$timer_show${DEFAULT_COLOR}"}'