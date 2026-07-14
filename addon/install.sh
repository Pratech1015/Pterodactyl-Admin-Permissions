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
echo "====================================================="
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

# Define backup function
create_backup() {
    local file="$1"
    if [ -f "$file" ] && [ ! -f "${file}.bak" ]; then
        cp "$file" "${file}.bak"
        echo -e "${GREEN}Created backup of $(basename "$file")${NC}"
    fi
}

# Define validation & restore function
validate_php_file() {
    local file="$1"
    if ! php -l "$file" > /dev/null 2>&1; then
        echo -e "${RED}Syntax validation failed for $(basename "$file")!${NC}"
        if [ -f "${file}.bak" ]; then
            echo -e "${YELLOW}Restoring backup of $(basename "$file")...${NC}"
            cp "${file}.bak" "$file"
        fi
        return 1
    fi
    return 0
}

# Determine web server user/group from existing files (e.g., storage or bootstrap/cache)
PANEL_OWNER=$(stat -c '%U' "$PANEL_PATH/bootstrap/cache" 2>/dev/null || stat -c '%U' "$PANEL_PATH/storage" 2>/dev/null || echo "www-data")
PANEL_GROUP=$(stat -c '%G' "$PANEL_PATH/bootstrap/cache" 2>/dev/null || stat -c '%G' "$PANEL_PATH/storage" 2>/dev/null || echo "www-data")

echo -e "${YELLOW}Detected panel file owner: $PANEL_OWNER:$PANEL_GROUP${NC}"
echo ""

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
cp "$SCRIPT_DIR/app/Http/Middleware/InjectSidebarMiddleware.php" "$PANEL_PATH/app/Http/Middleware/"
cp "$SCRIPT_DIR/app/Http/Controllers/Admin/AdminRoleController.php" "$PANEL_PATH/app/Http/Controllers/Admin/"
cp "$SCRIPT_DIR/app/Providers/AdminPermissionsServiceProvider.php" "$PANEL_PATH/app/Providers/"
cp "$SCRIPT_DIR/config/permissions.php" "$PANEL_PATH/config/permissions.php"
cp "$SCRIPT_DIR/routes/admin.php" "$PANEL_PATH/routes/admin-roles.php"
cp -r "$SCRIPT_DIR/resources/views/admin/roles/"* "$PANEL_PATH/resources/views/admin/roles/"

# Validate added PHP files
for file in "$PANEL_PATH/app/Models/AdminRole.php" \
            "$PANEL_PATH/app/Models/AdminRolePermission.php" \
            "$PANEL_PATH/app/Models/AdminUserRole.php" \
            "$PANEL_PATH/app/Models/Traits/HasAdminRoles.php" \
            "$PANEL_PATH/app/Http/Middleware/AdminPermissionMiddleware.php" \
            "$PANEL_PATH/app/Http/Middleware/InjectSidebarMiddleware.php" \
            "$PANEL_PATH/app/Http/Controllers/Admin/AdminRoleController.php" \
            "$PANEL_PATH/app/Providers/AdminPermissionsServiceProvider.php" \
            "$PANEL_PATH/config/permissions.php" \
            "$PANEL_PATH/routes/admin-roles.php"; do
    if [ -f "$file" ]; then
        if ! validate_php_file "$file"; then
            echo -e "${RED}Installation aborted due to a syntax error in copied files.${NC}"
            exit 1
        fi
    fi
done

echo -e "${GREEN}Files copied and validated successfully.${NC}"
echo ""

echo -e "${YELLOW}Step 2: Copying database migrations...${NC}"

# Copy migrations
cp "$SCRIPT_DIR/database/migrations/"*.php "$PANEL_PATH/database/migrations/"

echo -e "${GREEN}Migrations copied.${NC}"
echo ""

echo -e "${YELLOW}Step 3: Registering service provider...${NC}"

# Detect if Laravel uses config/app.php or bootstrap/providers.php (Laravel 11+)
PROVIDERS_FILE=""
if [ -f "$PANEL_PATH/bootstrap/providers.php" ]; then
    PROVIDERS_FILE="$PANEL_PATH/bootstrap/providers.php"
elif [ -f "$PANEL_PATH/config/app.php" ]; then
    PROVIDERS_FILE="$PANEL_PATH/config/app.php"
fi

if [ -n "$PROVIDERS_FILE" ]; then
    create_backup "$PROVIDERS_FILE"
    
    # Idempotent registration check
    if grep -q "AdminPermissionsServiceProvider" "$PROVIDERS_FILE"; then
        echo -e "${GREEN}Service provider already registered in $(basename "$PROVIDERS_FILE").${NC}"
    else
        if [ "$(basename "$PROVIDERS_FILE")" = "providers.php" ]; then
            # Insert before the closing bracket of the return array
            sed -i "/];/i\\    Pterodactyl\\\\Providers\\\\AdminPermissionsServiceProvider::class," "$PROVIDERS_FILE"
        else
            # Insert after AppServiceProvider in config/app.php
            sed -i "/Pterodactyl\\\\Providers\\\\AppServiceProvider/a\\
\\        Pterodactyl\\\\Providers\\\\AdminPermissionsServiceProvider::class," "$PROVIDERS_FILE"
        fi
        
        # Validate syntax
        if ! validate_php_file "$PROVIDERS_FILE"; then
            echo -e "${RED}Failed to register service provider safely. Restoring configuration.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Service provider registered in $(basename "$PROVIDERS_FILE").${NC}"
    fi
else
    echo -e "${RED}Error: Could not locate config/app.php or bootstrap/providers.php.${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 4: Patching AdminAuthenticate middleware...${NC}"

MIDDLEWARE_FILE="$PANEL_PATH/app/Http/Middleware/AdminAuthenticate.php"
if [ -f "$MIDDLEWARE_FILE" ]; then
    create_backup "$MIDDLEWARE_FILE"
    
    # Replace with permission-aware implementation
    cat > "$MIDDLEWARE_FILE" << 'PATCH'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
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
    public function handle(Request $request, Closure $next): Response
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

    if ! validate_php_file "$MIDDLEWARE_FILE"; then
        echo -e "${RED}Failed to patch AdminAuthenticate middleware safely. Restoring.${NC}"
        exit 1
    fi
    echo -e "${GREEN}AdminAuthenticate middleware patched and validated.${NC}"
else
    echo -e "${RED}Error: AdminAuthenticate middleware not found at $MIDDLEWARE_FILE.${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 5: Patching User model...${NC}"

USER_MODEL="$PANEL_PATH/app/Models/User.php"
if [ -f "$USER_MODEL" ]; then
    create_backup "$USER_MODEL"
    
    if ! grep -q "HasAdminRoles" "$USER_MODEL"; then
        # Add use statement after namespace or namespace use block
        sed -i "/use Pterodactyl\\\\Traits\\\\Helpers\\\\AvailableLanguages;/a\\
use Pterodactyl\\\\Models\\\\Traits\\\\HasAdminRoles;" "$USER_MODEL"

        # Add trait usage after AvailableLanguages trait usage
        sed -i "/use AvailableLanguages;/a\\
    use HasAdminRoles;" "$USER_MODEL"

        if ! validate_php_file "$USER_MODEL"; then
            echo -e "${RED}Failed to patch User model safely. Restoring.${NC}"
            exit 1
        fi
        echo -e "${GREEN}User model patched and validated with HasAdminRoles trait.${NC}"
    else
        echo -e "${GREEN}User model already patched with HasAdminRoles trait.${NC}"
    fi
else
    echo -e "${RED}Error: User model not found at $USER_MODEL.${NC}"
    exit 1
fi
echo ""

# Run Laravel commands as the appropriate web server user (if possible) or root and fix permissions
run_artisan() {
    local cmd="$1"
    if [ "$(id -u)" -eq 0 ]; then
        # Running as root, try running as the web user or fall back to root and then fix permissions
        if id "$PANEL_OWNER" >/dev/null 2>&1; then
            sudo -u "$PANEL_OWNER" php "$PANEL_PATH/artisan" $cmd
        else
            php "$PANEL_PATH/artisan" $cmd
        fi
    else
        # Not root, run directly
        php "$PANEL_PATH/artisan" $cmd
    fi
}

echo -e "${YELLOW}Step 6: Running database migrations...${NC}"
run_artisan "migrate --force"
echo -e "${GREEN}Database migrations completed successfully.${NC}"
echo ""

echo -e "${YELLOW}Step 7: Clearing and rebuilding caches...${NC}"
run_artisan "config:clear"
run_artisan "route:clear"
run_artisan "view:clear"
run_artisan "config:cache"
run_artisan "route:cache"
run_artisan "view:cache"
echo -e "${GREEN}Caches successfully optimized.${NC}"
echo ""

# Ensure all permissions and ownerships are correct on bootstrap/cache and storage
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}Step 8: Fixing file ownership to $PANEL_OWNER:$PANEL_GROUP...${NC}"
    chown -R "$PANEL_OWNER:$PANEL_GROUP" "$PANEL_PATH/bootstrap/cache" "$PANEL_PATH/storage"
    echo -e "${GREEN}Ownership and permissions verified.${NC}"
    echo ""
fi

echo "====================================================="
echo -e "${GREEN}Installation completed successfully!${NC}"
echo ""
echo "Notes:"
echo "  - Added dynamic sidebar link without modifying blade layouts."
echo "  - Ensured all patched files have valid PHP syntax."
echo "  - Restored proper owner/permissions on cache and storage directories."
echo ""
echo "Next steps:"
echo "  1. Log in to your Pterodactyl admin area."
echo "  2. Go to the brand new 'Roles' section in the sidebar."
echo "  3. Create roles and assign permissions as needed."
echo ""
echo "To uninstall, run: bash $SCRIPT_DIR/uninstall.sh $PANEL_PATH"
echo "====================================================="
