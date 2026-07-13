# Pterodactyl Admin Permissions Manager

An open-source role-based permission management system for the [Pterodactyl Panel](https://pterodactyl.io/). This addon allows you to create granular admin roles with specific permissions, so you can delegate admin tasks without giving full root access.

## Features

- **Role-based access control** - Create roles with fine-grained permissions
- **Granular permissions** - Control access to every admin panel section (servers, nodes, users, databases, etc.)
- **User assignment** - Assign one or more roles to non-root-admin users
- **Navbar customization** - Sidebar only shows menu items the user has permission to access
- **Root admin preserved** - Root administrators retain full access by default
- **No Wings modification needed** - Panel-only addon
- **Easy installation** - One-command install script

## Requirements

- Pterodactyl Panel v1.x.x
- PHP 8.1+
- MySQL/MariaDB or PostgreSQL

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/Pterodactyl-Admin-Permissions.git
cd Pterodactyl-Admin-Permissions

# Run the installer (default panel path: /var/www/pterodactyl)
bash addon/install.sh

# Or specify a custom panel path
bash addon/install.sh /path/to/pterodactyl
```

## Uninstallation

```bash
bash addon/uninstall.sh /path/to/pterodactyl
```

## Manual Installation

If you prefer to install manually:

1. Copy the files from `addon/` into your Pterodactyl panel directory
2. Run `php artisan migrate` to create the database tables
3. Register `AdminPermissionsServiceProvider` in `config/app.php`
4. Add the `HasAdminRoles` trait to `app/Models/User.php`
5. Replace `AdminAuthenticate` middleware with the permission-aware version
6. Add the Roles menu item to the admin sidebar
7. Run `php artisan config:cache && php artisan route:cache`

## Permissions

| Permission | Description |
|---|---|
| `admin.dashboard.view` | View admin dashboard |
| `admin.users.view` | View user list |
| `admin.users.create` | Create new users |
| `admin.users.update` | Update user details |
| `admin.users.delete` | Delete users |
| `admin.servers.view` | View server list |
| `admin.servers.create` | Create new servers |
| `admin.servers.update` | Update server details |
| `admin.servers.delete` | Delete servers |
| `admin.servers.manage` | Manage server state |
| `admin.servers.suspend` | Suspend servers |
| `admin.servers.reinstall` | Reinstall servers |
| `admin.nodes.view` | View node list |
| `admin.nodes.create` | Create new nodes |
| `admin.nodes.update` | Update node settings |
| `admin.nodes.delete` | Delete nodes |
| `admin.nodes.allocations` | Manage node allocations |
| `admin.databases.view` | View database hosts |
| `admin.databases.create` | Create database hosts |
| `admin.databases.update` | Update database hosts |
| `admin.databases.delete` | Delete database hosts |
| `admin.locations.view` | View locations |
| `admin.locations.create` | Create locations |
| `admin.locations.update` | Update locations |
| `admin.nests.view` | View nests |
| `admin.nests.create` | Create nests |
| `admin.nests.update` | Update nests |
| `admin.nests.delete` | Delete nests |
| `admin.nests.eggs.*` | Egg management permissions |
| `admin.mounts.*` | Mount management permissions |
| `admin.api.*` | Application API permissions |
| `admin.settings.*` | Panel settings permissions |
| `admin.roles.*` | Role management permissions |

## Usage

1. Log in as a root administrator
2. Navigate to **Admin > Roles** in the sidebar
3. Create a new role with the desired permissions
4. Assign the role to users via the **User Role Assignments** section
5. Users with roles will only see and access the sections their permissions allow

## License

MIT License - see [LICENSE](LICENSE) for details.
