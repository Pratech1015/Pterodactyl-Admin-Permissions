<?php

use Illuminate\Support\Facades\Route;
use Pterodactyl\Http\Controllers\Admin\AdminRoleController;

Route::group(['prefix' => 'roles', 'as' => 'admin.roles.'], function () {
    Route::get('/', [AdminRoleController::class, 'index'])->name('index');
    Route::get('/create', [AdminRoleController::class, 'create'])->name('create');
    Route::post('/create', [AdminRoleController::class, 'store'])->name('store');
    Route::get('/edit/{id}', [AdminRoleController::class, 'edit'])->name('edit');
    Route::patch('/edit/{id}', [AdminRoleController::class, 'update'])->name('update');
    Route::delete('/delete/{id}', [AdminRoleController::class, 'destroy'])->name('delete');
    Route::get('/permissions/{id}', [AdminRoleController::class, 'getPermissions'])->name('permissions');
    Route::post('/assign', [AdminRoleController::class, 'assignRole'])->name('assign');
    Route::post('/remove', [AdminRoleController::class, 'removeRole'])->name('remove');
});
