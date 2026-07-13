<?php

namespace Pterodactyl\Providers;

use Illuminate\Support\Facades\Blade;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Pterodactyl\Http\Middleware\AdminPermissionMiddleware;

class AdminPermissionsServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/permissions.php', 'permissions');
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register middleware
        $this->app['router']->aliasMiddleware('admin.permission', AdminPermissionMiddleware::class);

        // Register routes
        $this->registerRoutes();

        // Register views
        $this->loadViewsFrom(__DIR__ . '/../../resources/views', 'admin-permissions');

        // Publish config
        $this->publishes([
            __DIR__ . '/../../config/permissions.php' => config_path('permissions.php'),
        ], 'admin-permissions-config');

        // Publish migrations
        $this->publishes([
            __DIR__ . '/../../database/migrations/' => database_path('migrations'),
        ], 'admin-permissions-migrations');

        // Publish views
        $this->publishes([
            __DIR__ . '/../../resources/views/' => resource_path('views/vendor/admin-permissions'),
        ], 'admin-permissions-views');
    }

    /**
     * Register the admin permission routes.
     */
    protected function registerRoutes(): void
    {
        Route::middleware(['web', 'auth.session', 'admin.permission:admin.roles.view'])
            ->prefix('/admin')
            ->group(__DIR__ . '/../../routes/admin.php');
    }
}
