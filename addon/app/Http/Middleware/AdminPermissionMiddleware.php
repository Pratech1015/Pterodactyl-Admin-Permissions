<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Pterodactyl\Models\AdminRole;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class AdminPermissionMiddleware
{
    /**
     * Handle an incoming request.
     *
     * Checks if the user has the required permission for the current admin route.
     * Root admins always have access. Users with admin roles are checked against
     * their assigned role permissions.
     */
    public function handle(Request $request, Closure $next, ?string $permission = null): mixed
    {
        $user = $request->user();

        if (!$user) {
            throw new AccessDeniedHttpException();
        }

        // Root admins always have full access
        if ($user->root_admin) {
            return $next($request);
        }

        // If no specific permission is required, allow (fallback to default behavior)
        if (!$permission) {
            // Check if the user has ANY admin role assigned
            if ($user->adminRoles()->count() === 0) {
                throw new AccessDeniedHttpException();
            }

            return $next($request);
        }

        // Check if user has the required permission through any of their assigned roles
        $hasPermission = $user->adminRoles()
            ->whereHas('permissions', function ($query) use ($permission) {
                $query->where('permission', $permission);
            })
            ->exists();

        if (!$hasPermission) {
            throw new AccessDeniedHttpException();
        }

        return $next($request);
    }
}
