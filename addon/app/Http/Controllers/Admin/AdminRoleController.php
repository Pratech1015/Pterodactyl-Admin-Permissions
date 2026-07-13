<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Models\AdminRole;
use Pterodactyl\Models\AdminRolePermission;
use Pterodactyl\Models\User;
use Pterodactyl\Services\Alerts\Alert;

class AdminRoleController extends Controller
{
    /**
     * Display a listing of all admin roles.
     */
    public function index(Request $request)
    {
        $roles = AdminRole::withCount('users', 'permissions')->get();
        $users = User::orderBy('username')->get();

        return view('admin.roles.index', compact('roles', 'users'));
    }

    /**
     * Show the form for creating a new admin role.
     */
    public function create()
    {
        $permissions = config('permissions.permissions', []);

        return view('admin.roles.create', compact('permissions'));
    }

    /**
     * Store a newly created admin role.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:191|unique:admin_roles,name',
            'description' => 'nullable|string|max:500',
            'permissions' => 'array',
            'permissions.*' => 'string',
        ]);

        $role = AdminRole::create([
            'name' => $request->input('name'),
            'description' => $request->input('description'),
        ]);

        if ($request->has('permissions')) {
            foreach ($request->input('permissions') as $permission) {
                AdminRolePermission::create([
                    'admin_role_id' => $role->id,
                    'permission' => $permission,
                ]);
            }
        }

        Alert::success('Role created successfully.')->flash();

        return redirect()->route('admin.roles.index');
    }

    /**
     * Show the form for editing the specified admin role.
     */
    public function edit(int $id)
    {
        $role = AdminRole::with('permissions')->findOrFail($id);
        $permissions = config('permissions.permissions', []);
        $assignedPermissions = $role->permissions->pluck('permission')->toArray();

        return view('admin.roles.edit', compact('role', 'permissions', 'assignedPermissions'));
    }

    /**
     * Update the specified admin role.
     */
    public function update(Request $request, int $id)
    {
        $role = AdminRole::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:191|unique:admin_roles,name,' . $role->id,
            'description' => 'nullable|string|max:500',
            'permissions' => 'array',
            'permissions.*' => 'string',
        ]);

        $role->update([
            'name' => $request->input('name'),
            'description' => $request->input('description'),
        ]);

        // Sync permissions
        $role->permissions()->delete();

        if ($request->has('permissions')) {
            foreach ($request->input('permissions') as $permission) {
                AdminRolePermission::create([
                    'admin_role_id' => $role->id,
                    'permission' => $permission,
                ]);
            }
        }

        Alert::success('Role updated successfully.')->flash();

        return redirect()->route('admin.roles.index');
    }

    /**
     * Remove the specified admin role.
     */
    public function destroy(Request $request, int $id)
    {
        $role = AdminRole::findOrFail($id);

        if ($role->is_default) {
            Alert::danger('Cannot delete the default role.')->flash();
            return redirect()->route('admin.roles.index');
        }

        $role->users()->detach();
        $role->permissions()->delete();
        $role->delete();

        Alert::success('Role deleted successfully.')->flash();

        return redirect()->route('admin.roles.index');
    }

    /**
     * Assign a role to a user.
     */
    public function assignRole(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'role_id' => 'required|integer|exists:admin_roles,id',
        ]);

        $user = User::findOrFail($request->input('user_id'));
        $role = AdminRole::findOrFail($request->input('role_id'));

        // Don't assign roles to root admins (they already have full access)
        if ($user->root_admin) {
            Alert::danger('This user is a root administrator and does not need additional roles.')->flash();
            return redirect()->route('admin.roles.index');
        }

        // Check if already assigned
        if ($user->adminRoles()->where('admin_role_id', $role->id)->exists()) {
            Alert::warning('This user already has this role assigned.')->flash();
            return redirect()->route('admin.roles.index');
        }

        $user->adminRoles()->attach($role->id);

        Alert::success("Role \"{$role->name}\" assigned to {$user->username} successfully.")->flash();

        return redirect()->route('admin.roles.index');
    }

    /**
     * Remove a role from a user.
     */
    public function removeRole(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'role_id' => 'required|integer|exists:admin_roles,id',
        ]);

        $user = User::findOrFail($request->input('user_id'));
        $role = AdminRole::findOrFail($request->input('role_id'));

        $user->adminRoles()->detach($role->id);

        Alert::success("Role \"{$role->name}\" removed from {$user->username} successfully.")->flash();

        return redirect()->route('admin.roles.index');
    }

    /**
     * Get permissions for a specific role (AJAX endpoint).
     */
    public function getPermissions(int $id)
    {
        $role = AdminRole::with('permissions')->findOrFail($id);

        return response()->json([
            'permissions' => $role->permissions->pluck('permission')->toArray(),
        ]);
    }
}
