<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockHistory extends Model
{
    use HasFactory;
    protected $fillable = [
        'product_id',
        'type',
        'change',
        'old_stock',
        'new_stock',
        'note',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
