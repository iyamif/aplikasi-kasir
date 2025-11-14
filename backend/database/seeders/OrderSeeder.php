<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use App\Models\Customer;
use App\Models\Product;

class OrderSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        //

            $user = User::first(); // Admin
            $customer = Customer::first();
    
            $order = Order::create([
                'user_id' => $user->id,
                'customer_id' => $customer->id,
                'total_price' => 0, // nanti dihitung
            ]);
    
            $products = Product::take(3)->get();
            $total = 0;
    
            foreach ($products as $p) {
                $qty = rand(1, 3);
                $price = $p->price;
                $total += $price * $qty;
    
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $p->id,
                    'quantity' => $qty,
                    'price' => $price,
                ]);
    
                // Kurangi stock
                $p->decrement('stock', $qty);
            }
    
            $order->update(['total_price' => $total]);
        }
    }

