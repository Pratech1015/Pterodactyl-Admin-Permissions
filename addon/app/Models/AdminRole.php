<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AdminRole extends Model
{
    protected $table = 'admin_roles';

    protected $fillable = [
        'name',
        'description',
        'is_default',
    ];

    protected $casts = [
        'is_default' => 'boolean',
    ];

    public function permissions(): HasMany
    {
        return $this->hasMany(AdminRolePermission::class, 'admin_role_id');
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'admin_user_roles', 'admin_role_id', 'user_id');
    }

    /**
     * Check if this role has a specific permission.
     */
    public function hasPermission(string $permission): bool
    {
        return $this->permissions()->where('permission', $permission)->exists();
    }

    /**
     * Check if this role has all the given permissions.
     */
    public function hasAllPermissions(array $permissions): bool
    {
        foreach ($permissions as $permission) {
            if (!$this->hasPermission($permission)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Get all permission keys for this role.
     */
    public function getPermissionKeys(): array
    {
        return $this->permissions()->pluck('permission')->toArray();
    }
}
