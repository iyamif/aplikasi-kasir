<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Customer;

class CustomerSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        //
        $customers = [
            ['name' => 'John Doe', 'email' => 'john@example.com', 'phone' => '081234567890'],
            ['name' => 'Jane Smith', 'email' => 'jane@example.com', 'phone' => '081987654321'],
            ['name' => 'Alice', 'email' => 'alice@example.com', 'phone' => '081112223334'],
        ];

        foreach ($customers as $c) {
            Customer::create($c);
        }
    }
}
