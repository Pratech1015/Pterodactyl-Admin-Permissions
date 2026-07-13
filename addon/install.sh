#!/bin/bash

# Pterodactyl Admin Permissions Manager - Installation Script
# This script installs the permission manager addon into a Pterodactyl Panel installation.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect panel path
PANEL_PATH="${1:-/var/www/pterodactyl}"

echo -e "${YELLOW}Pterodactyl Admin Permissions Manager Installer${NC}"
echo "================================================"
echo ""

# Check if panel path exists
if [ ! -d "$PANEL_PATH" ]; then
    echo -e "${RED}Error: Pterodactyl panel not found at $PANEL_PATH${NC}"
    echo "Usage: $0 [panel-path]"
    echo "Example: $0 /var/www/pterodactyl"
    exit 1
fi

# Check if artisan exists
if [ ! -f "$PANEL_PATH/artisan" ]; then
    echo -e "${RED}Error: Laravel artisan not found at $PANEL_PATH/artisan${NC}"
    echo "Please provide the correct path to your Pterodactyl panel installation."
    exit 1
fi

echo -e "${GREEN}Panel found at: $PANEL_PATH${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Copying addon files...${NC}"

# Create addon directories in panel
mkdir -p "$PANEL_PATH/app/Http/Middleware"
mkdir -p "$PANEL_PATH/app/Http/Controllers/Admin"
mkdir -p "$PANEL_PATH/app/Models/Traits"
mkdir -p "$PANEL_PATH/config"
mkdir -p "$PANEL_PATH/routes"
mkdir -p "$PANEL_PATH/resources/views/admin/roles"

# Copy files
cp "$SCRIPT_DIR/app/Models/AdminRole.php" "$PANEL_PATH/app/Models/"
cp "$SCRIPT_DIR/app/Models/AdminRolePermission.php" "$PANEL_PATH/app/Models/"
cp "$SCRIPT_DIR/app/Models/AdminUserRole.php" "$PANEL_PATH/app/Models/"
cp "$SCRIPT_DIR/app/Models/Traits/HasAdminRoles.php" "$PANEL_PATH/app/Models/Traits/"
cp "$SCRIPT_DIR/app/Http/Middleware/AdminPermissionMiddleware.php" "$PANEL_PATH/app/Http/Middleware/"
cp "$SCRIPT_DIR/app/Http/Controllers/Admin/AdminRoleController.php" "$PANEL_PATH/app/Http/Controllers/Admin/"
cp "$SCRIPT_DIR/app/Providers/AdminPermissionsServiceProvider.php" "$PANEL_PATH/app/Providers/"
cp "$SCRIPT_DIR/config/permissions.php" "$PANEL_PATH/config/permissions.php"
cp "$SCRIPT_DIR/routes/admin.php" "$PANEL_PATH/routes/admin-roles.php"
cp -r "$SCRIPT_DIR/resources/views/admin/roles/"* "$PANEL_PATH/resources/views/admin/roles/"

echo -e "${GREEN}Files copied successfully.${NC}"
echo ""

echo -e "${YELLOW}Step 2: Running database migrations...${NC}"

# Copy migrations
cp "$SCRIPT_DIR/database/migrations/"*.php "$PANEL_PATH/database/migrations/"

cd "$PANEL_PATH"
php artisan migrate --force

echo -e "${GREEN}Migrations completed.${NC}"
echo ""

echo -e "${YELLOW}Step 3: Registering service provider...${NC}"

# Check if already registered
if grep -q "AdminPermissionsServiceProvider" "$PANEL_PATH/config/app.php"; then
    echo -e "${GREEN}Service provider already registered.${NC}"
else
    # Add service provider to config/app.php
    sed -i "/Pterodactyl\\\\Providers\\\\AppServiceProvider/a\\
\\
\\        /*\\
\\         * Pterodactyl Admin Permissions Manager\\
\\         */\\
\\        Pterodactyl\\\\Providers\\\\AdminPermissionsServiceProvider::class," "$PANEL_PATH/config/app.php"
    echo -e "${GREEN}Service provider registered.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Patching AdminAuthenticate middleware...${NC}"

# Backup original AdminAuthenticate middleware
if [ ! -f "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php.bak" ]; then
    cp "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php" "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php.bak"
    echo -e "${GREEN}Backup created: AdminAuthenticate.php.bak${NC}"
fi

# Replace AdminAuthenticate with permission-aware version
cat > "$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php" << 'PATCH'
<?php

namespace Pterodactyl\Http\Middleware;

use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class AdminAuthenticate
{
    /**
     * Handle an incoming request.
     *
     * Allows access if the user is a root_admin OR has any admin role assigned.
     * Specific permission checks are handled by AdminPermissionMiddleware.
     *
     * @throws AccessDeniedHttpException
     */
    public function handle(Request $request, \Closure $next): mixed
    {
        if (!$request->user()) {
            throw new AccessDeniedHttpException();
        }

        // Allow root admins (default behavior)
        if ($request->user()->root_admin) {
            return $next($request);
        }

        // Allow users with admin roles
        if ($request->user()->adminRoles()->count() > 0) {
            return $next($request);
        }

        throw new AccessDeniedHttpException();
    }
}
PATCH

echo -e "${GREEN}AdminAuthenticate middleware patched.${NC}"
echo ""

echo -e "${YELLOW}Step 5: Patching admin layout sidebar...${NC}"

# Add Roles link to admin sidebar
ADMIN_LAYOUT="$PANEL_PATH/resources/views/layouts/admin.blade.php"

if [ -f "$ADMIN_LAYOUT" ]; then
    if ! grep -q "admin.roles.index" "$ADMIN_LAYOUT"; then
        # Add roles menu item before the closing sidebar-menu ul
        sed -i '/<\/ul>/i\
                        <li class="{{ ! starts_with(Route::currentRouteName(), .admin.roles.) ?: .active. }}">\
                            <a href="{{ route(.admin.roles.index.) }}">\
                                <i class="fa fa-shield"></i> <span>Roles</span>\
                            </a>\
                        </li>' "$ADMIN_LAYOUT"
        echo -e "${GREEN}Roles menu item added to sidebar.${NC}"
    else
        echo -e "${GREEN}Roles menu item already exists in sidebar.${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Admin layout not found. Please manually add the Roles menu item.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 6: Patching User model...${NC}"

USER_MODEL="$PANEL_PATH/app/Models/User.php"

if [ -f "$USER_MODEL" ]; then
    if ! grep -q "HasAdminRoles" "$USER_MODEL"; then
        # Add use statement
        sed -i "/use Pterodactyl\\\\Traits\\\\Helpers\\\\AvailableLanguages;/a\\
use Pterodactyl\\\\Models\\\\Traits\\\\HasAdminRoles;" "$USER_MODEL"

        # Add trait usage
        sed -i "/use AvailableLanguages;/a\\
    use HasAdminRoles;" "$USER_MODEL"

        echo -e "${GREEN}User model patched with HasAdminRoles trait.${NC}"
    else
        echo -e "${GREEN}User model already patched.${NC}"
    fi
else
    echo -e "${YELLOW}Warning: User model not found. Please manually add the HasAdminRoles trait.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 7: Clearing caches...${NC}"

cd "$PANEL_PATH"
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo -e "${GREEN}Caches cleared.${NC}"
echo ""

echo "================================================"
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Create your first admin role at /admin/roles"
echo "  2. Assign roles to users who need limited admin access"
echo "  3. Root administrators retain full access by default"
echo ""
echo "To uninstall, run: bash $SCRIPT_DIR/uninstall.sh $PANEL_PATH"
echo "================================================"
