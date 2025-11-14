<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

use Database\Seeders\UserSeeder;
use Database\Seeders\CategorySeeder;
use Database\Seeders\ProductSeeder;
use Database\Seeders\CustomerSeeder;
use Database\Seeders\OrderSeeder;


class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,      // Buat user dulu
            CategorySeeder::class,  // Buat kategori sebelum produk
            ProductSeeder::class,   // Buat produk setelah kategori
            CustomerSeeder::class,  // Buat customer
            OrderSeeder::class,     // Buat order setelah semua di atas
        ]);
    }
}
