#!/bin/bash

# Claude Session Picker - Interactive menu for choosing Claude session type
# Provides options for new session, continue, resume, manual command, or regular shell
# Now with tmux session persistence for reconnection on navigation

TMUX_SESSION_NAME="claude"

# Colors
TERRACOTTA='\033[38;2;217;119;87m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

show_banner() {
    clear
    echo ""
    echo -e "  ${TERRACOTTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${TERRACOTTA}║${NC}                                                              ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}║${NC}   ${WHITE}Claude Terminal${NC}  ${DIM}·  Session Picker${NC}                         ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}║${NC}                                                              ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_existing_session() {
    tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null
}

show_menu() {
    echo "Choose your Claude session type:"
    echo ""

    if check_existing_session; then
        echo "  0) 🔄 Reconnect to existing session (recommended)"
        echo ""
    fi

    echo "  1) 🆕 New interactive session (default)"
    echo "  2) ⏩ Continue most recent conversation (-c)"
    echo "  3) 📋 Resume from conversation list (-r)"
    echo "  4) ⚙️  Custom Claude command (manual flags)"
    echo "  5) 🔐 Get login URL (if OAuth clipboard doesn't work)"
    echo "  6) 🐚 Drop to bash shell"
    echo "  7) ❌ Exit"
    echo ""
}

get_user_choice() {
    local choice
    local default="1"

    if check_existing_session; then
        default="0"
    fi

    printf "Enter your choice [0-7] (default: %s): " "$default" >&2
    read -r choice

    if [ -z "$choice" ]; then
        choice="$default"
    fi

    choice=$(echo "$choice" | tr -d '[:space:]')
    echo "$choice"
}

attach_existing_session() {
    echo "🔄 Reconnecting to existing Claude session..."
    sleep 1
    exec tmux attach-session -t "$TMUX_SESSION_NAME"
}

launch_claude_new() {
    echo "🚀 Starting new Claude session..."

    if check_existing_session; then
        echo "   (closing previous session)"
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" 'claude'
}

launch_claude_continue() {
    echo "⏩ Continuing most recent conversation..."

    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" 'claude -c'
}

launch_claude_resume() {
    echo "📋 Opening conversation list for selection..."

    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" 'claude -r'
}

launch_claude_custom() {
    echo ""
    echo "Enter your Claude command (e.g., 'claude --help' or 'claude -p \"hello\"'):"
    echo "Available flags: -c (continue), -r (resume), -p (print), --model, etc."
    echo -n "> claude "
    read -r custom_args

    if [ -z "$custom_args" ]; then
        echo "No arguments provided. Starting default session..."
        launch_claude_new
    else
        echo "🚀 Running: claude $custom_args"

        if check_existing_session; then
            tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
        fi

        sleep 1
        exec tmux new-session -s "$TMUX_SESSION_NAME" "claude $custom_args"
    fi
}

launch_login_url() {
    echo "🔐 Fetching Claude login URL..."
    sleep 1
    if [ -f /usr/local/bin/claude-login-url ]; then
        /usr/local/bin/claude-login-url
    else
        echo "claude-login-url helper not found"
    fi
    echo ""
    printf "Press Enter to return to menu..." >&2
    read -r
}

launch_bash_shell() {
    echo "🐚 Dropping to bash shell..."
    echo "Tip: Run 'tmux new-session -A -s claude \"claude\"' to start with persistence"
    sleep 1
    exec bash
}

main() {
    while true; do
        show_banner
        show_menu
        choice=$(get_user_choice)

        case "$choice" in
            0)
                if check_existing_session; then
                    attach_existing_session
                else
                    echo "❌ No existing session found"
                    sleep 1
                fi
                ;;
            1) launch_claude_new ;;
            2) launch_claude_continue ;;
            3) launch_claude_resume ;;
            4) launch_claude_custom ;;
            5) launch_login_url ;;
            6) launch_bash_shell ;;
            7) echo "👋 Goodbye!"; exit 0 ;;
            *)
                echo ""
                echo "❌ Invalid choice: '$choice'"
                echo "Please select a number between 0-7"
                echo ""
                printf "Press Enter to continue..." >&2
                read -r
                ;;
        esac
    done
}

trap 'echo ""; exit 0' EXIT INT TERM

main "$@"
