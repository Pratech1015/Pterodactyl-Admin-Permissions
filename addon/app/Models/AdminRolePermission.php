<?php

namespace Pterodactyl\Models;

class AdminRolePermission extends Model
{
    protected $table = 'admin_role_permissions';

    protected $fillable = [
        'admin_role_id',
        'permission',
    ];
}
