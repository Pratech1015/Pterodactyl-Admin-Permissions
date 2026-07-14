#!/bin/bash

# Pterodactyl Admin Permissions Manager - Uninstallation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PANEL_PATH="${1:-/var/www/pterodactyl}"

echo -e "${YELLOW}Pterodactyl Admin Permissions Manager Uninstaller${NC}"
echo "=================================================="
echo ""

if [ ! -d "$PANEL_PATH" ]; then
    echo -e "${RED}Error: Pterodactyl panel not found at $PANEL_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Removing service provider registration...${NC}"

if grep -q "AdminPermissionsServiceProvider" "$PANEL_PATH/config/app.php"; then
    sed -i '/AdminPermissionsServiceProvider/d' "$PANEL_PATH/config/app.php"
    sed -i '/Pterodactyl Admin Permissions Manager/d' "$PANEL_PATH/config/app.php"
    sed -i '/\*\//d' "$PANEL_PATH/config/app.php"
    echo -e "${GREEN}Service provider registration removed.${NC}"
else
    echo -e "${GREEN}Service provider not registered, skipping.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 2: Restoring AdminAuthenticate middleware...${NC}"

if [ -f "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php.bak" ]; then
    cp "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php.bak" "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php"
    rm "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php.bak"
    echo -e "${GREEN}Original middleware restored.${NC}"
else
    echo -e "${YELLOW}Warning: Backup not found. Please restore AdminAuthenticate.php manually.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Removing HasAdminRoles trait from User model...${NC}"

USER_MODEL="$PANEL_PATH/app/Models/User.php"
if [ -f "$USER_MODEL" ]; then
    sed -i '/HasAdminRoles/d' "$USER_MODEL"
    echo -e "${GREEN}Trait removed.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Clearing config and route caches...${NC}"

cd "$PANEL_PATH"
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

echo -e "${GREEN}Caches cleared.${NC}"
echo ""

echo -e "${YELLOW}Step 5: Dropping database tables...${NC}"

php artisan tinker --execute="
Schema::dropIfExists('admin_user_roles');
Schema::dropIfExists('admin_role_permissions');
Schema::dropIfExists('admin_roles');
echo 'Tables dropped.';
"

echo -e "${GREEN}Database tables dropped.${NC}"
echo ""

echo -e "${YELLOW}Step 6: Removing addon files...${NC}"

rm -f "$PANEL_PATH/app/Models/AdminRole.php"
rm -f "$PANEL_PATH/app/Models/AdminRolePermission.php"
rm -f "$PANEL_PATH/app/Models/AdminUserRole.php"
rm -f "$PANEL_PATH/app/Models/Traits/HasAdminRoles.php"
rm -f "$PANEL_PATH/app/Http/Middleware/AdminPermissionMiddleware.php"
rm -f "$PANEL_PATH/app/Http/Controllers/Admin/AdminRoleController.php"
rm -f "$PANEL_PATH/app/Providers/AdminPermissionsServiceProvider.php"
rm -f "$PANEL_PATH/config/permissions.php"
rm -f "$PANEL_PATH/routes/admin-roles.php"
rm -rf "$PANEL_PATH/resources/views/admin/roles"

echo -e "${GREEN}Files removed.${NC}"
echo ""

echo -e "${YELLOW}Step 7: Removing sidebar menu item...${NC}"

ADMIN_LAYOUT="$PANEL_PATH/resources/views/layouts/admin.blade.php"
if [ -f "$ADMIN_LAYOUT" ]; then
    sed -i '/admin.roles.index/d' "$ADMIN_LAYOUT"
    sed -i '/fa-shield/d' "$ADMIN_LAYOUT"
    echo -e "${GREEN}Sidebar item removed.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 8: Rebuilding caches...${NC}"

php artisan config:cache
php artisan route:cache
php artisan view:cache

echo -e "${GREEN}Caches rebuilt.${NC}"
echo ""

echo "=================================================="
echo -e "${GREEN}Uninstallation complete!${NC}"
echo "=================================================="
