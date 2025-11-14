<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\Category;

class ProductSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        //
        $products = [
            ['name' => 'Coca Cola', 'category' => 'Beverages', 'price' => 10000, 'stock' => 50],
            ['name' => 'Pepsi', 'category' => 'Beverages', 'price' => 9000, 'stock' => 50],
            ['name' => 'Burger', 'category' => 'Food', 'price' => 25000, 'stock' => 30],
            ['name' => 'Chips', 'category' => 'Snacks', 'price' => 5000, 'stock' => 100],
            ['name' => 'Headphones', 'category' => 'Electronics', 'price' => 150000, 'stock' => 20],
        ];

        foreach ($products as $p) {
            $category = Category::where('name', $p['category'])->first();
            Product::create([
                'name' => $p['name'],
                'category_id' => $category->id,
                'price' => $p['price'],
                'stock' => $p['stock'],
            ]);
        }
    }
}
