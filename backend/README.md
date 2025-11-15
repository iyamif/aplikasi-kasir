# Laravel POS – REST API Backend

Backend ini adalah sistem Point of Sale (POS) berbasis **Laravel** dengan arsitektur **REST API** untuk digunakan pada aplikasi mobile atau web POS.  
Fitur meliputi manajemen produk, stok, supplier, transaksi penjualan, customer, dan laporan.

---

## 🔧 Tech Stack

- **Laravel 10+**
- **PHP 8.1+**
- **MySQL / MariaDB**
- **Laravel Sanctum (Authentication)**
- **REST API JSON**
- **Laravel Eloquent ORM**

---

## 📦 Installation

### 1. Clone Repository

```bash
git clone https://github.com/your-username/laravel-pos-api.git
```

### 2. Install Dependencies

Pastikan Composer sudah terinstall di komputer Anda.

```bash
composer install
```

### 3. Setup Environment

```bash
cp .env.example .env
php artisan key:generate
```

### 4. Database Migration

```bash
php artisan migrate --seed
```

### 5. Run the Application

```bash
php artisan serve
```



