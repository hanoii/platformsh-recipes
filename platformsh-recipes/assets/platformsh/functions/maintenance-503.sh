function platformsh_recipes_maintenance_503_check() {
  if [ -n "$PLATFORMSH_RECIPES_MAINTENANCE_503" ]; then
      echo -e "\033[0;33m[warning] PLATFORMSH_RECIPES_MAINTENANCE_503 is set, doing nothing!\033[0m"
      exit 0
  fi
}
