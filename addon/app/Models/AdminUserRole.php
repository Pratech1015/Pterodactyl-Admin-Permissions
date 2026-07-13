<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class AdminUserRole extends Model
{
    protected $table = 'admin_user_roles';

    protected $fillable = [
        'user_id',
        'admin_role_id',
    ];
}
