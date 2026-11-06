# tsu git - Passthrough to git in the dotfiles repo

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tsu git <args...>"
    echo ""
    echo "Run git commands scoped to the dotfiles repository."
    echo ""
    echo "Examples:"
    echo "  tsu git status"
    echo "  tsu git log --oneline -5"
    echo "  tsu git diff"
    return 0
fi

git -C "$DOTS_DIR" "$@"
