#!/bin/bash

# Pterodactyl Admin Permissions Manager - Uninstallation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PANEL_PATH="${1:-/var/www/pterodactyl}"

echo -e "${YELLOW}Pterodactyl Admin Permissions Manager Uninstaller${NC}"
echo "====================================================="
echo ""

if [ ! -d "$PANEL_PATH" ]; then
    echo -e "${RED}Error: Pterodactyl panel not found at $PANEL_PATH${NC}"
    exit 1
fi

# Detect web server user/group
PANEL_OWNER=$(stat -c '%U' "$PANEL_PATH/bootstrap/cache" 2>/dev/null || stat -c '%U' "$PANEL_PATH/storage" 2>/dev/null || echo "www-data")
PANEL_GROUP=$(stat -c '%G' "$PANEL_PATH/bootstrap/cache" 2>/dev/null || stat -c '%G' "$PANEL_PATH/storage" 2>/dev/null || echo "www-data")

# Run Laravel commands as the appropriate web server user (if possible) or root and fix permissions
run_artisan() {
    local cmd="$1"
    if [ "$(id -u)" -eq 0 ]; then
        if id "$PANEL_OWNER" >/dev/null 2>&1; then
            sudo -u "$PANEL_OWNER" php "$PANEL_PATH/artisan" $cmd
        else
            php "$PANEL_PATH/artisan" $cmd
        fi
    else
        php "$PANEL_PATH/artisan" $cmd
    fi
}

echo -e "${YELLOW}Step 1: Restoring service provider configuration...${NC}"

PROVIDERS_FILE=""
if [ -f "$PANEL_PATH/bootstrap/providers.php" ]; then
    PROVIDERS_FILE="$PANEL_PATH/bootstrap/providers.php"
elif [ -f "$PANEL_PATH/config/app.php" ]; then
    PROVIDERS_FILE="$PANEL_PATH/config/app.php"
fi

if [ -n "$PROVIDERS_FILE" ]; then
    if [ -f "${PROVIDERS_FILE}.bak" ]; then
        cp "${PROVIDERS_FILE}.bak" "$PROVIDERS_FILE"
        rm "${PROVIDERS_FILE}.bak"
        echo -e "${GREEN}Restored original $(basename "$PROVIDERS_FILE") configuration from backup.${NC}"
    else
        # If no backup, do string removal safely
        sed -i '/AdminPermissionsServiceProvider/d' "$PROVIDERS_FILE"
        echo -e "${YELLOW}Warning: Backup not found. Cleaned references in $(basename "$PROVIDERS_FILE") safely.${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Configuration files not found, skipping.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 2: Restoring core files from backups...${NC}"

# AdminAuthenticate middleware
MIDDLEWARE_FILE="$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php"
if [ -f "${MIDDLEWARE_FILE}.bak" ]; then
    cp "${MIDDLEWARE_FILE}.bak" "$MIDDLEWARE_FILE"
    rm "${MIDDLEWARE_FILE}.bak"
    echo -e "${GREEN}Restored original AdminAuthenticate middleware from backup.${NC}"
else
    echo -e "${YELLOW}Warning: AdminAuthenticate backup not found, skipping.${NC}"
fi

# User model
USER_MODEL="$PANEL_PATH/app/Models/User.php"
if [ -f "${USER_MODEL}.bak" ]; then
    cp "${USER_MODEL}.bak" "$USER_MODEL"
    rm "${USER_MODEL}.bak"
    echo -e "${GREEN}Restored original User model from backup.${NC}"
else
    # If no backup, try safe removal
    sed -i '/HasAdminRoles/d' "$USER_MODEL" 2>/dev/null || true
    echo -e "${YELLOW}Warning: User model backup not found. Cleaned trait references safely.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Clearing caches to apply configuration changes...${NC}"
run_artisan "config:clear"
run_artisan "route:clear"
run_artisan "view:clear"
echo -e "${GREEN}Caches successfully cleared. Laravel is now bootstrapped with default configuration.${NC}"
echo ""

echo -e "${YELLOW}Step 4: Dropping database tables...${NC}"
run_artisan "tinker --execute=\"
Schema::dropIfExists('admin_user_roles');
Schema::dropIfExists('admin_role_permissions');
Schema::dropIfExists('admin_roles');
echo 'Addon database tables dropped.';
\""
echo -e "${GREEN}Database cleaned up successfully.${NC}"
echo ""

echo -e "${YELLOW}Step 5: Removing copied addon files...${NC}"

rm -f "$PANEL_PATH/app/Models/AdminRole.php"
rm -f "$PANEL_PATH/app/Models/AdminRolePermission.php"
rm -f "$PANEL_PATH/app/Models/AdminUserRole.php"
rm -f "$PANEL_PATH/app/Models/Traits/HasAdminRoles.php"
rm -f "$PANEL_PATH/app/Http/Middleware/AdminPermissionMiddleware.php"
rm -f "$PANEL_PATH/app/Http/Middleware/InjectSidebarMiddleware.php"
rm -f "$PANEL_PATH/app/Http/Controllers/Admin/AdminRoleController.php"
rm -f "$PANEL_PATH/app/Providers/AdminPermissionsServiceProvider.php"
rm -f "$PANEL_PATH/config/permissions.php"
rm -f "$PANEL_PATH/routes/admin-roles.php"
rm -rf "$PANEL_PATH/resources/views/admin/roles"

# Remove copied migrations
rm -f "$PANEL_PATH/database/migrations/"*_create_admin_roles_table.php

echo -e "${GREEN}Addon files removed.${NC}"
echo ""

echo -e "${YELLOW}Step 6: Rebuilding final clean caches...${NC}"
run_artisan "config:cache"
run_artisan "route:cache"
run_artisan "view:cache"
echo -e "${GREEN}Caches rebuilt.${NC}"
echo ""

# Ensure all permissions and ownerships are correct on bootstrap/cache and storage
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}Step 7: Re-verifying panel file ownership to $PANEL_OWNER:$PANEL_GROUP...${NC}"
    chown -R "$PANEL_OWNER:$PANEL_GROUP" "$PANEL_PATH/bootstrap/cache" "$PANEL_PATH/storage"
    echo -e "${GREEN}Ownership and permissions verified.${NC}"
    echo ""
fi

echo "====================================================="
echo -e "${GREEN}Uninstallation completed successfully!${NC}"
echo "====================================================="
