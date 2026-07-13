@extends('layouts.admin')

@section('title', 'Create Admin Role')

@section('content-header')
    <h1>Create Admin Role<small>Create a new role with specific permissions</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li><a href="{{ route('admin.roles.index') }}">Roles</a></li>
        <li class="active">Create</li>
    </ol>
@endsection

@section('content')
<div class="row">
    <div class="col-xs-12">
        <form action="{{ route('admin.roles.store') }}" method="POST">
            @csrf
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">Role Information</h3>
                </div>
                <div class="box-body">
                    <div class="form-group">
                        <label for="name">Role Name <span class="text-danger">*</span></label>
                        <input type="text" name="name" id="name" class="form-control" value="{{ old('name') }}" required maxlength="191" placeholder="e.g., Server Manager">
                        <p class="help-block">A unique name for this role.</p>
                    </div>
                    <div class="form-group">
                        <label for="description">Description</label>
                        <textarea name="description" id="description" class="form-control" rows="3" maxlength="500" placeholder="Optional description for this role">{{ old('description') }}</textarea>
                    </div>
                </div>
            </div>

            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">Permissions</h3>
                    <div class="box-tools pull-right">
                        <button type="button" class="btn btn-xs btn-default" id="selectAll">Select All</button>
                        <button type="button" class="btn btn-xs btn-default" id="deselectAll">Deselect All</button>
                    </div>
                </div>
                <div class="box-body">
                    @foreach ($permissions as $section => $sectionPermissions)
                        <div class="permission-section" style="margin-bottom: 20px;">
                            <h4 style="text-transform: uppercase; color: #666; font-size: 12px; letter-spacing: 1px; border-bottom: 1px solid #eee; padding-bottom: 5px;">
                                {{ ucfirst(str_replace('_', ' ', $section)) }}
                            </h4>
                            <div class="row">
                                @foreach ($sectionPermissions as $permissionKey => $permissionDescription)
                                    <div class="col-md-4 col-sm-6">
                                        <div class="checkbox">
                                            <label>
                                                <input type="checkbox" name="permissions[]" value="{{ $permissionKey }}"
                                                    {{ in_array($permissionKey, old('permissions', [])) ? 'checked' : '' }}>
                                                {{ $permissionDescription }}
                                            </label>
                                            <br>
                                            <small class="text-muted" style="margin-left: 20px;">{{ $permissionKey }}</small>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            <div class="box-footer">
                <a href="{{ route('admin.roles.index') }}" class="btn btn-default">Cancel</a>
                <button type="submit" class="btn btn-primary pull-right">Create Role</button>
            </div>
        </form>
    </div>
</div>
@endsection

@section('footer-scripts')
    @parent
    <script>
        $(function() {
            $('#selectAll').on('click', function() {
                $('input[name="permissions[]"]').prop('checked', true);
            });
            $('#deselectAll').on('click', function() {
                $('input[name="permissions[]"]').prop('checked', false);
            });
        });
    </script>
@endsection
