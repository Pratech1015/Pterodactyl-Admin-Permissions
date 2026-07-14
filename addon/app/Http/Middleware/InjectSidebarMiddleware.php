<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class InjectSidebarMiddleware
{
    /**
     * Handle an incoming request.
     *
     * Dynamically injects the "Roles" sidebar item into the admin panel layout HTML response
     * without modifying the core blade view files.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Only inject for safe, successful, HTML-based admin page GET requests
        if ($request->isMethod('GET')
            && str_starts_with($request->getPathInfo(), '/admin')
            && $response->headers->get('content-type')
            && str_contains($response->headers->get('content-type'), 'text/html')
        ) {
            $user = $request->user();
            if ($user && ($user->root_admin || $user->hasAdminPermission('admin.roles.view'))) {
                $content = $response->getContent();

                $rolesActive = str_starts_with($request->route()->getName(), 'admin.roles') ? 'active' : '';

                // Render the Roles sidebar menu item
                $sidebarItem = '
                        <li class="' . $rolesActive . '">
                            <a href="' . route('admin.roles.index') . '">
                                <i class="fa fa-shield"></i> <span>Roles</span>
                            </a>
                        </li>';

                // Look for admin/nests in the href attribute
                if (preg_match('/href="[^"]*\/admin\/nests"/', $content, $matches, PREG_OFFSET_CAPTURE)) {
                    $pos = $matches[0][1];
                    $liClosePos = strpos($content, '</li>', $pos);
                    if ($liClosePos !== false) {
                        $insertPos = $liClosePos + 5; // insert right after the </li> tag of Nests item
                        $content = substr_replace($content, $sidebarItem, $insertPos, 0);
                    }
                } else {
                    // Fallback: search for closing side-menu ul tag or any typical landmark
                    $fallbackSearch = '</ul>';
                    $pos = strrpos($content, $fallbackSearch);
                    if ($pos !== false) {
                        $content = substr_replace($content, $sidebarItem, $pos, 0);
                    }
                }

                $response->setContent($content);
            }
        }

        return $response;
    }
}
