<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Admin Permissions Configuration
    |--------------------------------------------------------------------------
    |
    | Define all available admin permissions grouped by section.
    | These permissions map to admin panel routes and features.
    |
    */

    'permissions' => [
        'dashboard' => [
            'admin.dashboard.view' => 'View admin dashboard',
        ],

        'users' => [
            'admin.users.view' => 'View user list',
            'admin.users.create' => 'Create new users',
            'admin.users.update' => 'Update user details',
            'admin.users.delete' => 'Delete users',
        ],

        'servers' => [
            'admin.servers.view' => 'View server list',
            'admin.servers.create' => 'Create new servers',
            'admin.servers.update' => 'Update server details',
            'admin.servers.delete' => 'Delete servers',
            'admin.servers.manage' => 'Manage server state (start/stop/restart)',
            'admin.servers.suspend' => 'Suspend servers',
            'admin.servers.reinstall' => 'Reinstall servers',
            'admin.servers.transfer' => 'Transfer servers',
        ],

        'nodes' => [
            'admin.nodes.view' => 'View node list',
            'admin.nodes.create' => 'Create new nodes',
            'admin.nodes.update' => 'Update node settings',
            'admin.nodes.delete' => 'Delete nodes',
            'admin.nodes.allocations' => 'Manage node allocations',
            'admin.nodes.configuration' => 'View node configuration',
            'admin.nodes.system_information' => 'View node system information',
        ],

        'databases' => [
            'admin.databases.view' => 'View database hosts',
            'admin.databases.create' => 'Create database hosts',
            'admin.databases.update' => 'Update database hosts',
            'admin.databases.delete' => 'Delete database hosts',
        ],

        'locations' => [
            'admin.locations.view' => 'View locations',
            'admin.locations.create' => 'Create locations',
            'admin.locations.update' => 'Update locations',
        ],

        'nests' => [
            'admin.nests.view' => 'View nests',
            'admin.nests.create' => 'Create nests',
            'admin.nests.update' => 'Update nests',
            'admin.nests.delete' => 'Delete nests',
            'admin.nests.eggs.view' => 'View eggs',
            'admin.nests.eggs.create' => 'Create eggs',
            'admin.nests.eggs.update' => 'Update eggs',
            'admin.nests.eggs.delete' => 'Delete eggs',
            'admin.nests.eggs.import' => 'Import eggs',
            'admin.nests.eggs.export' => 'Export eggs',
            'admin.nests.eggs.variables' => 'Manage egg variables',
            'admin.nests.eggs.scripts' => 'Manage egg scripts',
        ],

        'mounts' => [
            'admin.mounts.view' => 'View mounts',
            'admin.mounts.create' => 'Create mounts',
            'admin.mounts.update' => 'Update mounts',
            'admin.mounts.delete' => 'Delete mounts',
        ],

        'api' => [
            'admin.api.view' => 'View application API keys',
            'admin.api.create' => 'Create application API keys',
            'admin.api.delete' => 'Delete application API keys',
        ],

        'settings' => [
            'admin.settings.view' => 'View panel settings',
            'admin.settings.update' => 'Update panel settings',
            'admin.settings.mail' => 'View mail settings',
            'admin.settings.mail.update' => 'Update mail settings',
            'admin.settings.mail.test' => 'Send test emails',
            'admin.settings.advanced' => 'View advanced settings',
            'admin.settings.advanced.update' => 'Update advanced settings',
        ],

        'roles' => [
            'admin.roles.view' => 'View admin roles',
            'admin.roles.create' => 'Create admin roles',
            'admin.roles.update' => 'Update admin roles',
            'admin.roles.delete' => 'Delete admin roles',
            'admin.roles.assign' => 'Assign roles to users',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Route to Permission Mapping
    |--------------------------------------------------------------------------
    |
    | Maps admin route names to the required permission.
    | Routes not listed here require root_admin (default Pterodactyl behavior).
    |
    */

    'route_permissions' => [
        // Dashboard
        'admin.index' => 'admin.dashboard.view',

        // Users
        'admin.users' => 'admin.users.view',
        'admin.users.json' => 'admin.users.view',
        'admin.users.new' => 'admin.users.create',

        // Servers
        'admin.servers' => 'admin.servers.view',
        'admin.servers.new' => 'admin.servers.create',
        'admin.servers.view' => 'admin.servers.view',
        'admin.servers.view.details' => 'admin.servers.update',
        'admin.servers.view.build' => 'admin.servers.update',
        'admin.servers.view.startup' => 'admin.servers.update',
        'admin.servers.view.database' => 'admin.servers.update',
        'admin.servers.view.mounts' => 'admin.servers.update',
        'admin.servers.view.manage' => 'admin.servers.manage',
        'admin.servers.view.delete' => 'admin.servers.delete',

        // Nodes
        'admin.nodes' => 'admin.nodes.view',
        'admin.nodes.new' => 'admin.nodes.create',
        'admin.nodes.view' => 'admin.nodes.view',
        'admin.nodes.view.settings' => 'admin.nodes.update',
        'admin.nodes.view.configuration' => 'admin.nodes.configuration',
        'admin.nodes.view.allocation' => 'admin.nodes.allocations',
        'admin.nodes.view.servers' => 'admin.nodes.view',
        'admin.nodes.view.delete' => 'admin.nodes.delete',

        // Databases
        'admin.databases' => 'admin.databases.view',
        'admin.databases.view' => 'admin.databases.view',

        // Locations
        'admin.locations' => 'admin.locations.view',
        'admin.locations.view' => 'admin.locations.view',

        // Nests
        'admin.nests' => 'admin.nests.view',
        'admin.nests.new' => 'admin.nests.create',
        'admin.nests.view' => 'admin.nests.view',
        'admin.nests.egg.new' => 'admin.nests.eggs.create',
        'admin.nests.egg.view' => 'admin.nests.eggs.view',
        'admin.nests.egg.export' => 'admin.nests.eggs.export',
        'admin.nests.egg.variables' => 'admin.nests.eggs.variables',
        'admin.nests.egg.scripts' => 'admin.nests.eggs.scripts',

        // Mounts
        'admin.mounts' => 'admin.mounts.view',
        'admin.mounts.view' => 'admin.mounts.view',

        // Settings
        'admin.settings' => 'admin.settings.view',
        'admin.settings.mail' => 'admin.settings.mail',
        'admin.settings.advanced' => 'admin.settings.advanced',

        // API
        'admin.api.index' => 'admin.api.view',
        'admin.api.new' => 'admin.api.create',

        // Roles
        'admin.roles.index' => 'admin.roles.view',
        'admin.roles.create' => 'admin.roles.create',
        'admin.roles.edit' => 'admin.roles.update',
    ],
];
