<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SupplierController;
use App\Http\Controllers\Api\PurchaseOrderController;
use App\Http\Controllers\Api\InventoryController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/


// Route::post('login', [AuthController::class, 'login']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register',[AuthController::class,'register']);
Route::post('/verify-2fa', [AuthController::class, 'verify2FA']);
Route::middleware('auth:sanctum')->post('/enable-2fa', [AuthController::class, 'enable2FA']);


Route::middleware('auth:sanctum')->group(function () {
    // Route::post('enable-2fa',[AuthController::class,'enable2FA']);
    Route::get('orders/history', [OrderController::class, 'history']);
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('me', [AuthController::class, 'me']);
    Route::post('products/{id}/stock-opname',[ProductController::class,'stockOpname']);
    
    Route::apiResource('category', CategoryController::class);
    Route::apiResource('products', ProductController::class);
    Route::apiResource('customers', CustomerController::class);
    Route::apiResource('orders', OrderController::class);
    
    Route::apiResource('suppliers', SupplierController::class);
    Route::apiResource('purchase-orders', PurchaseOrderController::class);
    Route::apiResource('inventory', InventoryController::class);
    Route::prefix('inventory')->group(function () {
        Route::post('/update-stock', [InventoryController::class, 'updateStock']);
        Route::post('/stock-opname', [InventoryController::class, 'stockOpname']);
        Route::get('/history', [InventoryController::class, 'history']);
    });
   
    
    
});



