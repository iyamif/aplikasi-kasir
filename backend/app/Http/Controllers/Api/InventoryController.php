<?php

namespace App\Http\Controllers\Api;


use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\StockHistory;

class InventoryController extends Controller
{
   /**
     * GET /inventory (history)
     */
    public function index()
    {
        $history = StockHistory::with('product')->latest()->get();

        return response()->json([
            'message' => 'Stock history list',
            'data' => $history,
        ]);
    }

    /**
     * POST /inventory (stock in / stock out / adjustment)
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'change' => 'required|integer',
            'type' => 'required|in:in,out,adjustment,opname',
            'note' => 'nullable|string'
        ]);

        $product = Product::find($validated['product_id']);

        // Apply stock change
        $product->stock += $validated['change'];
        $product->save();

        // Create log
        $log = StockHistory::create([
            'product_id' => $product->id,
            'change'     => $validated['change'],
            'type'       => $validated['type'],
            'note'       => $request->note
        ]);

        return response()->json([
            'message' => 'Stock history created',
            'data' => $log
        ], 201);
    }

    /**
     * GET /inventory/{id}
     */
    public function show($id)
    {
        $log = StockHistory::with('product')->findOrFail($id);

        return response()->json([
            'message' => 'Stock history detail',
            'data' => $log,
        ]);
    }

    /**
     * PUT /inventory/{id}
     */
    public function update(Request $request, $id)
    {
        $log = StockHistory::findOrFail($id);

        $validated = $request->validate([
            'change' => 'required|integer',
            'type' => 'required|in:in,out,adjustment,opname',
            'note' => 'nullable|string'
        ]);

        $product = Product::find($log->product_id);

        // Rollback old stock
        $product->stock -= $log->change;

        // Apply new change
        $product->stock += $validated['change'];
        $product->save();

        // Update log
        $log->update($validated);

        return response()->json([
            'message' => 'Stock history updated',
            'data' => $log
        ]);
    }

    /**
     * DELETE /inventory/{id}
     */
    public function destroy($id)
    {
        $log = StockHistory::findOrFail($id);
        $product = Product::find($log->product_id);

        // Rollback stock
        $product->stock -= $log->change;
        $product->save();

        $log->delete();

        return response()->json([
            'message' => 'Stock history deleted'
        ]);
    }
    public function updateStock(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'change'     => 'required|integer',
        ]);

        $product = Product::findOrFail($validated['product_id']);

        // Update stock
        $product->stock += $validated['change'];
        $product->save();

        // log stock
        $log = StockHistory::create([
            'product_id' => $product->id,
            'change'     => $validated['change'],
            'type'       => $validated['change'] > 0 ? 'in' : 'out',
            'note'       => 'Manual stock update'
        ]);

        return response()->json([
            'message' => 'Stock updated',
            'data'    => $log,
        ], 200);
    }

    /**
     * POST /inventory/stock-opname
     * Set stok langsung (opname)
     */
    public function stockOpname(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'stock'      => 'required|integer|min:0',
        ]);

        $product = Product::findOrFail($validated['product_id']);

        $old = $product->stock;
        $new = $validated['stock'];

        // Hitung selisih opname
        $change = $new - $old;
       

        // Update stok produk
        $product->stock = $new;
        $product->save();

        // Log history
        $log = StockHistory::create([
            'product_id' => $product->id,
            'change'     => $change,
            'type'       => 'opname',
            'note'       => 'Stock Opname'
        ]);

        return response()->json([
            'message' => 'Stock opname successful',
            'data'    => $log
        ], 200);
    }
}
