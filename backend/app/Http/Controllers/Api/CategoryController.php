<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;


class CategoryController extends Controller
{
     // List semua kategori
     public function index()
     {
         return response()->json(Category::all());
     }
 
     // Buat kategori baru
     public function store(Request $request)
     {
         $validated = $request->validate([
             'name' => 'required|string|unique:categories,name',
         ]);
 
         $category = Category::create($validated);
         return response()->json($category, 201);
     }
 
     // Tampilkan kategori spesifik
     public function show(Category $category)
     {
         return response()->json($category);
     }
 
     // Update kategori
     public function update(Request $request, Category $category)
     {
         $validated = $request->validate([
             'name' => 'required|string|unique:categories,name,' . $category->id,
         ]);
 
         $category->update($validated);
         return response()->json($category);
     }
 
     // Hapus kategori
     public function destroy(Category $category)
     {
         $category->delete();
         return response()->json(['message' => 'Kategori dihapus']);
     }
}
