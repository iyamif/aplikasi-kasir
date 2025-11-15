# aplikasi-kasirThe project was created while recording video "Create POS System Using Laravel"

Installation

Requirements

For system requirements you Check Laravel Requirement

Clone the repository from github.

git clone https://github.com/angkosal/laravel-pos.git [YourDirectoryName]
The command installs the project in a directory named YourDirectoryName. You can choose a different directory name if you want.

Install dependencies

Laravel utilizes Composer to manage its dependencies. So, before using Laravel, make sure you have Composer installed on your machine.

cd YourDirectoryName
composer install
Config file

Rename or copy .env.example file to .env 1.php artisan key:generate to generate app key.

Set your database credentials in your .env file
Set your APP_URL in your .env file.
Database

Migrate database table php artisan migrate
php artisan db:seed, this will initialize settings and create and admin user for you [email: admin@gmail.com - password: admin123]
Install Node Dependencies

npm install to install node dependencies
npm run dev for development or npm run build for production
Create storage link

php artisan storage:link

Run Server

php artisan serve or Laravel Homestead
Visit localhost:8000 in your browser. Email: admin@gmail.com, Password: admin123.
Feature To-Do List

📊 Dashboard

 Display overall sales summary (total revenue, today's sales, top-selling product)
📦 Products

 Product list with pagination, search, and category filters
 Add product form (name, price, stock, image, category)
 Edit/Delete product actions
🛒 Point Of Sale

 Responsive POS interface (for desktop & tablet)
 Add products via barcode scan or name search
 Display cart with items, quantity
 Support multiple payment methods (cash, card, etc.)
 Apply discount by specific items
 Apply discount by invoice (overall discount)
 Print or download sale receipt
📦 Orders

 List all sales/orders with filters (date)
 Add filter (status, customer)
 View detailed order/invoice page
 Support order returns and refunds
👥 Customers

 Customer list
 Filter customer with (name, phone and email)
 Add/Edit customer information (name, phone, email, address)
 View customer order history
🚚 Supplier

 Supplier list
 Filter supplier with (name, phone and email)
 Add/Edit supplier info (name, phone, email, ...)
 View purchase/order history by supplier
📥 Purchase — by Emre Dikmen

 Add purchase form (select supplier, date, invoice number)
 Add purchased items with quantity and cost
 Update product stock automatically on purchase
 View list of purchases with filters (supplier, date)
 Generate printable purchase receipt (80mm)
⚙️ Settings

 Store settings (name, currency)
 Add tax config to store setting
Screenshots

Product list

Product list

Create order

Create order

Order list

Order list

Customer list

Customer list

🌟 Or Khmernokor POS :)

Khmernokor POS is a modern and efficient Point of Sale system tailored for restaurants, cafés, and retail businesses. Built with a focus on usability, speed, and flexibility, it provides an all-in-one solution for front-of-house and back-of-house operations.

🖥️ POS Screen

POS Screen

The POS interface is clean, responsive, and optimized for quick ordering. Cashiers and servers can easily select items, apply discounts, manage tables, and process various payment methods efficiently.

🖨️ Kitchen Printer

Kitchen Printer

Orders placed via the POS are instantly sent to the kitchen printer. This ensures accurate, printed tickets that help kitchen staff prepare dishes quickly and with minimal error.

🍽️ Kitchen Display System (KDS)

Kitchen Display

Replace traditional printed tickets with a digital kitchen display. Staff can view and manage incoming orders in real time, mark items as complete, and streamline food preparation.

🧾 Receipt Preview

Receipt Preview

Preview and print receipts with detailed breakdowns of items, quantities, discounts, taxes, and total amounts—customizable to suit your business branding.

🖨️ Cashier Printer

Cashier Printer

Print high-quality receipts at the cashier station for customers upon checkout. Reliable and fast printing supports smooth and professional transactions.

📱 QR Menu for Customers ordering

Let customers scan a QR code to view the digital menu on their phones. This contactless feature enhances the dining experience while reducing the need for physical menus.

Video Demo on Windows

Watch the video

Video Demo on Mobile

Watch the video

