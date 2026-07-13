@extends('layouts.admin')

@section('title', 'Admin Roles')

@section('content-header')
    <h1>Admin Roles<small>Manage administrator roles and permissions</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Roles</li>
    </ol>
@endsection

@section('content')
<div class="row">
    <div class="col-xs-12">
        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">Roles</h3>
                <div class="box-tools pull-right">
                    <a href="{{ route('admin.roles.create') }}" class="btn btn-primary btn-sm">
                        <i class="fa fa-plus"></i> Create New Role
                    </a>
                </div>
            </div>
            <div class="box-body no-padding">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Permissions</th>
                            <th>Users</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($roles as $role)
                            <tr>
                                <td>{{ $role->id }}</td>
                                <td>
                                    <strong>{{ $role->name }}</strong>
                                    @if ($role->is_default)
                                        <span class="label label-info">Default</span>
                                    @endif
                                </td>
                                <td>{{ $role->description ?: '—' }}</td>
                                <td><span class="label label-primary">{{ $role->permissions_count }} permissions</span></td>
                                <td><span class="label label-success">{{ $role->users_count }} users</span></td>
                                <td>
                                    <a href="{{ route('admin.roles.edit', ['id' => $role->id]) }}" class="btn btn-xs btn-default" data-toggle="tooltip" title="Edit Role">
                                        <i class="fa fa-pencil"></i>
                                    </a>
                                    @if (!$role->is_default)
                                        <form action="{{ route('admin.roles.delete', ['id' => $role->id]) }}" method="POST" style="display:inline;" onsubmit="return confirm('Are you sure you want to delete this role?');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-xs btn-danger" data-toggle="tooltip" title="Delete Role">
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </form>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center text-muted">No roles have been created yet.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-xs-12">
        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">User Role Assignments</h3>
                <div class="box-tools pull-right">
                    <button type="button" class="btn btn-success btn-sm" data-toggle="modal" data-target="#assignRoleModal">
                        <i class="fa fa-plus"></i> Assign Role
                    </button>
                </div>
            </div>
            <div class="box-body no-padding">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Email</th>
                            <th>Root Admin</th>
                            <th>Assigned Roles</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                            $usersWithRoles = $users->filter(function ($user) {
                                return $user->root_admin || $user->adminRoles()->count() > 0;
                            });
                        @endphp
                        @forelse ($usersWithRoles as $user)
                            <tr>
                                <td>{{ $user->username }}</td>
                                <td>{{ $user->email }}</td>
                                <td>
                                    @if ($user->root_admin)
                                        <span class="label label-danger">Root Admin</span>
                                    @else
                                        <span class="label label-default">No</span>
                                    @endif
                                </td>
                                <td>
                                    @if ($user->adminRoles->count() > 0)
                                        @foreach ($user->adminRoles as $role)
                                            <span class="label label-primary">
                                                {{ $role->name }}
                                                @if (!$user->root_admin)
                                                    <form action="{{ route('admin.roles.remove') }}" method="POST" style="display:inline;">
                                                        @csrf
                                                        <input type="hidden" name="user_id" value="{{ $user->id }}">
                                                        <input type="hidden" name="role_id" value="{{ $role->id }}">
                                                        <button type="submit" class="btn-link" style="color:white;text-decoration:none;" data-toggle="tooltip" title="Remove Role">
                                                            <i class="fa fa-times"></i>
                                                        </button>
                                                    </form>
                                                @endif
                                            </span>
                                        @endforeach
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                                <td>
                                    <a href="{{ route('admin.users.view', ['user' => $user->id]) }}" class="btn btn-xs btn-default" data-toggle="tooltip" title="View User">
                                        <i class="fa fa-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="text-center text-muted">No users have been assigned roles yet.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Assign Role Modal -->
<div class="modal fade" id="assignRoleModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <form action="{{ route('admin.roles.assign') }}" method="POST">
                @csrf
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title">Assign Role to User</h4>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label for="user_id">Select User</label>
                        <select name="user_id" id="user_id" class="form-control select2" required>
                            <option value="">— Select a User —</option>
                            @foreach ($users as $user)
                                @if (!$user->root_admin)
                                    <option value="{{ $user->id }}">{{ $user->username }} ({{ $user->email }})</option>
                                @endif
                            @endforeach
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="role_id">Select Role</label>
                        <select name="role_id" id="role_id" class="form-control" required>
                            <option value="">— Select a Role —</option>
                            @foreach ($roles as $role)
                                <option value="{{ $role->id }}">{{ $role->name }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Assign Role</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
