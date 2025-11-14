<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index()
    {
        return Order::with('customer', 'items.product')->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'customer_name' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        $total = 0;

        // Mulai transaction supaya aman
        \DB::beginTransaction();

        try {
            // Buat order
            $order = Order::create([
                'user_id' => $request->user()->id,
                'customer_id' => $request->customer_id,
                'customer_name' => $request->customer_name,
                'total_price' => 0, // nanti diupdate
            ]);

            foreach ($request->items as $item) {
                $product = Product::findOrFail($item['product_id']);

                // Cek stock
                if ($product->stock < $item['quantity']) {
                    throw new \Exception("Stock produk {$product->name} tidak cukup");
                }

                $subtotal = $product->price * $item['quantity'];
                $total += $subtotal;

                // Buat order item
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price,
                ]);

                // Kurangi stock produk
                $product->decrement('stock', $item['quantity']);
            }

            // Update total price
            $order->update(['total_price' => $total]);

            \DB::commit();

            return response()->json($order->load('customer', 'items.product'), 201);
        } catch (\Exception $e) {
            \DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    

    public function show(Order $order)
    {
        return $order->load('customer', 'items.product');
    }


    public function history()
    {
        $orders = Order::latest()
        ->get();

        // Format agar rapi
        $formatted = $orders->map(function ($o) {
            return [
                'id'            => $o->id,
                'customer'      => $o->customer_name ?? '-',
                'total_price'   => $o->total_price,
                'created_at'    => $o->created_at->format('Y-m-d H:i'),
                'items'         => $o->items->map(function ($i) {
                    return [
                        'product_id'   => $i->product_id,
                        'product_name' => $i->product->name,
                        'qty'          => $i->quantity,
                        'price'        => $i->price,
                    ];
                }),
            ];
        });

        return response()->json([
            'message' => 'Order history loaded',
            'data'    => $formatted,
        ]);
    }

}

