# tsu migrate - Manage migration scripts

local MIGRATIONS_DIR="$DOTS_DIR/.data/tsu-cli/migrations"
local DONE_FILE="$HOME/.local/share/tsu/migrations-done"
local subcmd="${1:-}"

mkdir -p "$(dirname "$DONE_FILE")"
touch "$DONE_FILE"

case "$subcmd" in
    -h|--help)
        echo "Usage: tsu migrate [subcommand]"
        echo ""
        echo "Manage dotfiles migration scripts."
        echo ""
        echo "Subcommands:"
        echo "  (none)  Run pending migrations"
        echo "  list    Show all migrations and their status"
        echo "  done    Mark all pending migrations as done"
        ;;
    list)
        local total=0
        local pending=0

        for migration in "$MIGRATIONS_DIR"/*.sh; do
            [[ -f "$migration" ]] || continue
            local name="$(basename "$migration")"
            ((total++))
            if grep -qxF "$name" "$DONE_FILE" 2>/dev/null; then
                echo -e "  \e[1;32m[done]\e[0m    $name"
            else
                echo -e "  \e[1;33m[pending]\e[0m $name"
                ((pending++))
            fi
        done

        if [[ $total -eq 0 ]]; then
            echo "tsu migrate: no migrations found"
        else
            echo ""
            echo "  $total total, $pending pending"
        fi
        ;;
    done)
        local count=0
        for migration in "$MIGRATIONS_DIR"/*.sh; do
            [[ -f "$migration" ]] || continue
            local name="$(basename "$migration")"
            if ! grep -qxF "$name" "$DONE_FILE" 2>/dev/null; then
                echo "$name" >> "$DONE_FILE"
                ((count++))
            fi
        done

        if [[ $count -eq 0 ]]; then
            echo "tsu migrate: all migrations already marked as done"
        else
            echo "tsu migrate: marked $count migrations as done"
        fi
        ;;
    "")
        echo ":: Running pending migrations..."
        source "$DOTS_DIR/.data/tsu-cli/lib/run-migrations.sh"
        ;;
    *)
        echo "tsu migrate: unknown subcommand '$subcmd'"
        echo "Run 'tsu migrate --help' for usage information."
        ;;
esac
