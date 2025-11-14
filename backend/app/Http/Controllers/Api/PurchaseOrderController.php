<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;


class PurchaseOrderController extends Controller
{
   /**
     * Display a listing of the purchase orders.
     */
    public function index(Request $request)
    {
        // Bisa filter berdasarkan supplier_id (jika dikirim dari query string)
        $query = PurchaseOrder::with(['supplier', 'product']);

        if ($request->has('supplier_id')) {
            $query->where('supplier_id', $request->supplier_id);
        }

        $purchaseOrders = $query->orderBy('created_at', 'desc')->get();

        return response()->json($purchaseOrders);
    }

    /**
     * Store a newly created purchase order.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'supplier_id' => 'required|exists:suppliers,id',
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1',
            'status' => 'required|in:pending,received',
        ]);

        $purchaseOrder = PurchaseOrder::create($validated);

        // Kalau status "received", tambahkan stok produk
        if ($validated['status'] === 'received') {
            $product = $purchaseOrder->product;
            $product->increment('stock', $validated['quantity']);
        }

        return response()->json($purchaseOrder->load(['supplier', 'product']), 201);
    }

    /**
     * Display the specified purchase order.
     */
    public function show(PurchaseOrder $purchaseOrder)
    {
        return response()->json($purchaseOrder->load(['supplier', 'product']));
    }

    /**
     * Update the specified purchase order.
     */
    public function update(Request $request, PurchaseOrder $purchaseOrder)
    {
        $validated = $request->validate([
            'supplier_id' => 'exists:suppliers,id',
            'product_id' => 'exists:products,id',
            'quantity' => 'integer|min:1',
            'status' => 'in:pending,received',
        ]);

        $oldStatus = $purchaseOrder->status;

        $purchaseOrder->update($validated);

        // Jika status berubah menjadi received → tambahkan stok
        if (
            isset($validated['status']) &&
            $validated['status'] === 'received' &&
            $oldStatus !== 'received'
        ) {
            $product = $purchaseOrder->product;
            $product->increment('stock', $purchaseOrder->quantity);
        }

        return response()->json($purchaseOrder->load(['supplier', 'product']));
    }

    /**
     * Remove the specified purchase order.
     */
    public function destroy(PurchaseOrder $purchaseOrder)
    {
        $purchaseOrder->delete();

        return response()->json(['message' => 'Purchase order deleted successfully']);
    }
}
