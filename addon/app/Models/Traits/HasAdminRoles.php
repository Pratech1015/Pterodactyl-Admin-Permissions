<?php

namespace Pterodactyl\Models\Traits;

use Pterodactyl\Models\AdminRole;

trait HasAdminRoles
{
    /**
     * Get all admin roles assigned to this user.
     */
    public function adminRoles()
    {
        return $this->belongsToMany(AdminRole::class, 'admin_user_roles', 'user_id', 'admin_role_id');
    }

    /**
     * Check if user has a specific admin permission.
     * Root admins always return true.
     */
    public function hasAdminPermission(string $permission): bool
    {
        if ($this->root_admin) {
            return true;
        }

        return $this->adminRoles()
            ->whereHas('permissions', function ($query) use ($permission) {
                $query->where('permission', $permission);
            })
            ->exists();
    }

    /**
     * Check if user has all of the given admin permissions.
     */
    public function hasAllAdminPermissions(array $permissions): bool
    {
        if ($this->root_admin) {
            return true;
        }

        foreach ($permissions as $permission) {
            if (!$this->hasAdminPermission($permission)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Check if user has any of the given admin permissions.
     */
    public function hasAnyAdminPermission(array $permissions): bool
    {
        if ($this->root_admin) {
            return true;
        }

        foreach ($permissions as $permission) {
            if ($this->hasAdminPermission($permission)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Check if user has an admin role (any role, not necessarily root_admin).
     */
    public function hasAdminRole(): bool
    {
        return $this->root_admin || $this->adminRoles()->count() > 0;
    }

    /**
     * Get all permission keys this user has through their roles.
     */
    public function getAdminPermissions(): array
    {
        if ($this->root_admin) {
            return array_keys(config('permissions.permissions', []) ... array_values(config('permissions.permissions', [])));
        }

        $permissions = [];

        $this->adminRoles->each(function (AdminRole $role) use (&$permissions) {
            $permissions = array_merge($permissions, $role->getPermissionKeys());
        });

        return array_unique($permissions);
    }
}
