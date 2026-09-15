# TextileDrop SaaS — Plain PHP + MySQL Blueprint

## 1. Goal

Build **TextileDrop**, a multi-tenant SaaS for Surat textile wholesalers, sellers, and resellers.

### Core workflow

```text
Seller uploads daily product images
        ↓
Creates a collection / Daily Drop
        ↓
System creates design codes and catalog records
        ↓
Seller shares one public catalog link on WhatsApp
        ↓
Buyer browses catalog and taps “Ask on WhatsApp”
        ↓
System stores inquiry and seller follows up
```

### Technology rules

- Flutter frontend: Android app + Flutter Web admin + Flutter Web public catalog.
- Backend: **plain PHP 8.3/8.4 REST APIs**.
- Database: **MySQL 8**.
- Hosting: Windows/IIS/PHP hosting.
- No Laravel.
- No Docker.
- No Node.js backend required.
- Use `index.php` as the single API entry point.
- Use `src/` for all business logic.
- Use PDO prepared statements only.
- Use local Windows hosting storage for images initially.

---

## 2. SaaS Rules: Multi-Tenant First

TextileDrop is SaaS, so one installation serves many businesses.

### Tenant isolation rule

Every business-owned record must contain `business_id`.

Examples:

```text
products.business_id
collections.business_id
contacts.business_id
inquiries.business_id
media_assets.business_id
```

### Critical security rule

Never trust this from Flutter:

```json
{
  "business_id": 12
}
```

A user could change it and try to access another client’s data.

Correct flow:

```text
Flutter sends Bearer token
       ↓
PHP validates token
       ↓
PHP finds logged-in user
       ↓
PHP gets business_id from database/session/token
       ↓
Every SQL query filters using that business_id
```

Example:

```php
$businessId = $currentUser['business_id'];

$stmt = $db->prepare(
    'SELECT * FROM products WHERE business_id = :business_id AND deleted_at IS NULL'
);
$stmt->execute(['business_id' => $businessId]);
```

Never do this:

```php
$stmt = $db->query('SELECT * FROM products');
```

Never do this:

```php
$businessId = $_POST['business_id'];
```

unless it is a platform-admin-only operation and is separately authorized.

---

## 3. Project Folder Structure

Keep only the `public/` folder accessible from the internet. The `src/`, `config/`, and `storage/private/` folders must be outside public web root if your hosting allows it.

```text
textiledrop-api/
│
├── public/                         # IIS document root
│   ├── index.php                   # Single API front controller
│   ├── .htaccess                   # Only if Apache; ignore for IIS
│   ├── web.config                  # IIS rewrite configuration
│   └── uploads/                    # Public optimized/watermarked files only
│       ├── optimized/
│       ├── thumbnails/
│       ├── watermarked/
│       └── pdf/
│
├── src/                            # Application code, not directly public
│   ├── Core/
│   │   ├── App.php
│   │   ├── Router.php
│   │   ├── Request.php
│   │   ├── Response.php
│   │   ├── Database.php
│   │   ├── Auth.php
│   │   ├── Validator.php
│   │   ├── Logger.php
│   │   ├── Config.php
│   │   ├── Upload.php
│   │   ├── ImageProcessor.php
│   │   ├── Pagination.php
│   │   └── Helpers.php
│   │
│   ├── Middleware/
│   │   ├── AuthMiddleware.php
│   │   ├── TenantMiddleware.php
│   │   ├── RoleMiddleware.php
│   │   ├── CorsMiddleware.php
│   │   └── RateLimitMiddleware.php
│   │
│   ├── Controllers/
│   │   ├── AuthController.php
│   │   ├── BusinessController.php
│   │   ├── StaffController.php
│   │   ├── CategoryController.php
│   │   ├── ProductController.php
│   │   ├── CollectionController.php
│   │   ├── MediaController.php
│   │   ├── ContactController.php
│   │   ├── ConsentController.php
│   │   ├── InquiryController.php
│   │   ├── DashboardController.php
│   │   ├── ReportController.php
│   │   └── PublicCatalogController.php
│   │
│   ├── Services/
│   │   ├── AuthService.php
│   │   ├── TokenService.php
│   │   ├── ProductService.php
│   │   ├── ProductCodeService.php
│   │   ├── CollectionService.php
│   │   ├── CatalogService.php
│   │   ├── ContactService.php
│   │   ├── ConsentService.php
│   │   ├── InquiryService.php
│   │   ├── WhatsAppLinkService.php
│   │   ├── ImageService.php
│   │   ├── PdfService.php
│   │   └── AuditLogService.php
│   │
│   ├── Repositories/
│   │   ├── BaseRepository.php
│   │   ├── UserRepository.php
│   │   ├── BusinessRepository.php
│   │   ├── ProductRepository.php
│   │   ├── CollectionRepository.php
│   │   ├── ContactRepository.php
│   │   ├── InquiryRepository.php
│   │   └── MediaRepository.php
│   │
│   └── Routes/
│       ├── api.php
│       ├── auth.php
│       ├── admin.php
│       └── public_catalog.php
│
├── config/
│   ├── app.php
│   ├── database.php
│   ├── auth.php
│   ├── storage.php
│   └── cors.php
│
├── database/
│   ├── migrations/
│   │   ├── 001_create_core_tables.sql
│   │   ├── 002_create_catalog_tables.sql
│   │   ├── 003_create_crm_tables.sql
│   │   └── 004_create_saas_billing_tables.sql
│   ├── seeds/
│   │   └── demo_business.sql
│   └── backups/
│
├── storage/
│   ├── private/
│   │   ├── originals/
│   │   ├── temp/
│   │   ├── exports/
│   │   └── logs/
│   └── cache/
│
├── scripts/
│   ├── process_image_queue.php
│   ├── send_reminders.php
│   ├── generate_catalog_pdf.php
│   ├── cleanup_temp_files.php
│   └── backup_database.bat
│
├── vendor/                         # Composer packages, optional but recommended
├── composer.json
├── .env                            # Never commit this
├── .env.example
└── README.md
```

### Do not put these in `public/`

```text
.env
config/database.php
storage/private/originals
logs
backups
SQL migrations
PHP controller/service files
```

If your Windows hosting only gives one public folder, use IIS request filtering rules to deny direct access to sensitive files and folders.

---

## 4. `public/index.php` — Single Entry Point

Every API request goes through this file.

```php
<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../src/Core/App.php';

use TextileDrop\Core\App;

$app = new App(__DIR__ . '/..');
$app->run();
```

`index.php` should stay very small. Do not write all API logic here. It only boots the application and passes requests to the Router.

---

## 5. IIS `web.config`

Put this file inside `public/web.config`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <defaultDocument>
      <files>
        <clear />
        <add value="index.php" />
      </files>
    </defaultDocument>

    <rewrite>
      <rules>
        <rule name="TextileDrop API Routes" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.php" appendQueryString="true" />
        </rule>
      </rules>
    </rewrite>

    <security>
      <requestFiltering>
        <requestLimits maxAllowedContentLength="10485760" />
        <hiddenSegments>
          <add segment="config" />
          <add segment="storage" />
          <add segment="database" />
          <add segment="src" />
        </hiddenSegments>
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
```

`10485760` is 10 MB. Start with 10 MB maximum image upload size. Increase only if required.

---

## 6. Plain PHP Core Design

### Request lifecycle

```text
HTTP request
  ↓
public/index.php
  ↓
Core/App.php
  ↓
CORS middleware
  ↓
Router identifies route
  ↓
Auth middleware validates Bearer token when required
  ↓
Tenant middleware identifies business_id
  ↓
Role middleware checks permissions
  ↓
Controller validates request
  ↓
Service performs business logic
  ↓
Repository uses PDO prepared SQL
  ↓
JSON response
```

### `src/Core/App.php`

Responsibilities:

- Load `.env` and config files.
- Create PDO database connection.
- Register routes.
- Handle global exceptions.
- Return safe JSON errors.
- Run router dispatch.

### `src/Core/Router.php`

Required features:

- `GET`, `POST`, `PUT`, `PATCH`, `DELETE` routes.
- Route parameters like `/products/{id}`.
- Middleware per route/group.
- Route grouping such as `/api/v1`.
- 404 handling.
- Method-not-allowed handling.

Example desired API registration:

```php
$router->group('/api/v1', function ($router) {
    $router->post('/auth/login', [AuthController::class, 'login']);
    $router->post('/auth/register-owner', [AuthController::class, 'registerOwner']);

    $router->group('', ['middleware' => ['auth', 'tenant']], function ($router) {
        $router->get('/products', [ProductController::class, 'index']);
        $router->post('/products', [ProductController::class, 'store']);
        $router->patch('/products/{id}', [ProductController::class, 'update']);
    });
});
```

---

## 7. Database Connection: PDO

Use PDO, exceptions, UTF-8, and real prepared statements.

### `config/database.php`

```php
<?php

return [
    'host' => $_ENV['DB_HOST'] ?? '127.0.0.1',
    'port' => $_ENV['DB_PORT'] ?? '3306',
    'database' => $_ENV['DB_DATABASE'] ?? 'textiledrop_db',
    'username' => $_ENV['DB_USERNAME'] ?? '',
    'password' => $_ENV['DB_PASSWORD'] ?? '',
    'charset' => 'utf8mb4',
];
```

### `src/Core/Database.php`

```php
<?php

declare(strict_types=1);

namespace TextileDrop\Core;

use PDO;
use PDOException;

final class Database
{
    private PDO $pdo;

    public function __construct(array $config)
    {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            $config['host'],
            $config['port'],
            $config['database'],
            $config['charset']
        );

        $this->pdo = new PDO($dsn, $config['username'], $config['password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    }

    public function pdo(): PDO
    {
        return $this->pdo;
    }
}
```

### Required PDO rules

- Always use `$pdo->prepare()` and `$stmt->execute()`.
- Never concatenate user text into SQL.
- Never return raw database errors to Flutter users.
- Use database transactions for operations that create a collection + products + media records.
- Keep `utf8mb4` for Gujarati/Hindi/emoji support.

---

## 8. Database Schema

Use MySQL 8, `InnoDB`, and `utf8mb4_unicode_ci` or a modern `utf8mb4` collation.

### 8.1 Platform/SaaS tables

#### `plans`

```sql
CREATE TABLE plans (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    monthly_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    yearly_price DECIMAL(12,2) NULL,
    max_users INT UNSIGNED NOT NULL DEFAULT 1,
    max_products INT UNSIGNED NOT NULL DEFAULT 500,
    max_storage_mb INT UNSIGNED NOT NULL DEFAULT 1024,
    max_collections_per_month INT UNSIGNED NULL,
    features_json JSON NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `businesses`

```sql
CREATE TABLE businesses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    public_id CHAR(26) NOT NULL UNIQUE,
    plan_id BIGINT UNSIGNED NULL,
    name VARCHAR(150) NOT NULL,
    legal_name VARCHAR(180) NULL,
    slug VARCHAR(120) NOT NULL UNIQUE,
    business_type ENUM('textile_wholesaler','textile_manufacturer','reseller','boutique','service_business','other') NOT NULL DEFAULT 'textile_wholesaler',
    owner_name VARCHAR(120) NULL,
    phone VARCHAR(25) NULL,
    whatsapp_number VARCHAR(25) NULL,
    email VARCHAR(191) NULL,
    address_line1 VARCHAR(255) NULL,
    city VARCHAR(100) NULL DEFAULT 'Surat',
    state VARCHAR(100) NULL DEFAULT 'Gujarat',
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    pincode VARCHAR(20) NULL,
    gst_number VARCHAR(30) NULL,
    logo_path VARCHAR(500) NULL,
    primary_color VARCHAR(20) NULL DEFAULT '#0B8F5B',
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    subscription_status ENUM('trial','active','past_due','suspended','cancelled') NOT NULL DEFAULT 'trial',
    trial_ends_at DATETIME NULL,
    subscription_ends_at DATETIME NULL,
    storage_used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_business_plan FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE SET NULL,
    INDEX idx_business_subscription (subscription_status, is_active),
    INDEX idx_business_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `users`

```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(191) NOT NULL UNIQUE,
    phone VARCHAR(25) NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('platform_admin','owner','manager','sales_staff','catalog_staff') NOT NULL DEFAULT 'owner',
    avatar_path VARCHAR(500) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    email_verified_at DATETIME NULL,
    last_login_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    INDEX idx_user_business_role (business_id, role),
    INDEX idx_user_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Platform admins have `business_id = NULL`. Every normal business user must have a valid `business_id`.

#### `api_tokens`

Store only a hash of the token, never the plain token.

```sql
CREATE TABLE api_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    token_name VARCHAR(100) NOT NULL DEFAULT 'Flutter App',
    expires_at DATETIME NULL,
    last_used_at DATETIME NULL,
    revoked_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token_active (token_hash, revoked_at, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `subscriptions`

```sql
CREATE TABLE subscriptions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    plan_id BIGINT UNSIGNED NOT NULL,
    billing_cycle ENUM('monthly','yearly','manual') NOT NULL DEFAULT 'monthly',
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    status ENUM('trial','active','past_due','cancelled','expired') NOT NULL DEFAULT 'trial',
    starts_at DATETIME NOT NULL,
    ends_at DATETIME NULL,
    cancelled_at DATETIME NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id) REFERENCES plans(id),
    INDEX idx_subscription_business_status (business_id, status, ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.2 Business settings and catalog structure

#### `business_settings`

```sql
CREATE TABLE business_settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL UNIQUE,
    catalog_title VARCHAR(150) NULL,
    catalog_description TEXT NULL,
    default_currency CHAR(3) NOT NULL DEFAULT 'INR',
    show_prices_publicly TINYINT(1) NOT NULL DEFAULT 0,
    allow_guest_inquiry TINYINT(1) NOT NULL DEFAULT 1,
    watermark_enabled TINYINT(1) NOT NULL DEFAULT 1,
    watermark_text VARCHAR(120) NULL,
    inquiry_whatsapp_template TEXT NULL,
    terms_url VARCHAR(500) NULL,
    privacy_url VARCHAR(500) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_settings_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `categories`

```sql
CREATE TABLE categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    parent_id BIGINT UNSIGNED NULL,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    UNIQUE KEY uq_category_business_slug (business_id, slug),
    INDEX idx_category_business_active (business_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `collections`

A collection is a daily drop, festival collection, category launch, or private dealer catalog.

```sql
CREATE TABLE collections (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    created_by_user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(180) NOT NULL,
    slug VARCHAR(180) NOT NULL,
    description TEXT NULL,
    collection_date DATE NULL,
    cover_media_id BIGINT UNSIGNED NULL,
    visibility ENUM('draft','public','private','archived') NOT NULL DEFAULT 'draft',
    price_visibility ENUM('inherit','show','hide','on_request') NOT NULL DEFAULT 'inherit',
    share_token CHAR(36) NOT NULL UNIQUE,
    published_at DATETIME NULL,
    expires_at DATETIME NULL,
    sort_order INT NOT NULL DEFAULT 0,
    deleted_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_collection_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_collection_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    UNIQUE KEY uq_collection_business_slug (business_id, slug),
    INDEX idx_collection_public (business_id, visibility, published_at),
    INDEX idx_collection_date (business_id, collection_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `products`

```sql
CREATE TABLE products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NULL,
    created_by_user_id BIGINT UNSIGNED NOT NULL,
    product_code VARCHAR(80) NOT NULL,
    title VARCHAR(180) NULL,
    fabric VARCHAR(100) NULL,
    color VARCHAR(100) NULL,
    brand VARCHAR(100) NULL,
    price DECIMAL(12,2) NULL,
    price_label VARCHAR(100) NULL,
    cost_price DECIMAL(12,2) NULL,
    stock_status ENUM('available','limited','sold_out','discontinued') NOT NULL DEFAULT 'available',
    stock_quantity INT NULL,
    short_description VARCHAR(500) NULL,
    internal_notes TEXT NULL,
    is_public TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    deleted_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_product_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    UNIQUE KEY uq_product_business_code (business_id, product_code),
    INDEX idx_product_search (business_id, product_code, stock_status, is_active),
    INDEX idx_product_category (business_id, category_id),
    INDEX idx_product_fabric (business_id, fabric),
    INDEX idx_product_color (business_id, color)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `collection_products`

```sql
CREATE TABLE collection_products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    collection_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_featured TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cp_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY uq_collection_product (collection_id, product_id),
    INDEX idx_cp_collection_sort (collection_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.3 Media tables

#### `media_assets`

```sql
CREATE TABLE media_assets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    collection_id BIGINT UNSIGNED NULL,
    uploaded_by_user_id BIGINT UNSIGNED NOT NULL,
    media_type ENUM('image','video','pdf') NOT NULL DEFAULT 'image',
    original_filename VARCHAR(255) NULL,
    storage_disk VARCHAR(50) NOT NULL DEFAULT 'local',
    original_path VARCHAR(500) NOT NULL,
    optimized_path VARCHAR(500) NULL,
    thumbnail_path VARCHAR(500) NULL,
    watermarked_path VARCHAR(500) NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT UNSIGNED NOT NULL,
    width INT NULL,
    height INT NULL,
    duration_seconds INT NULL,
    processing_status ENUM('pending','processing','ready','failed') NOT NULL DEFAULT 'pending',
    processing_error TEXT NULL,
    alt_text VARCHAR(255) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_media_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_media_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_media_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
    CONSTRAINT fk_media_user FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id),
    INDEX idx_media_product (business_id, product_id, sort_order),
    INDEX idx_media_collection (business_id, collection_id, sort_order),
    INDEX idx_media_processing (processing_status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Do not store product image binary files as MySQL BLOB data. Store the file in disk storage and its metadata/path in this table.

### 8.4 Buyer CRM tables

#### `contacts`

```sql
CREATE TABLE contacts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    created_by_user_id BIGINT UNSIGNED NULL,
    name VARCHAR(150) NULL,
    phone_e164 VARCHAR(25) NOT NULL,
    email VARCHAR(191) NULL,
    company_name VARCHAR(150) NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    contact_type ENUM('buyer','dealer','reseller','retailer','other') NOT NULL DEFAULT 'buyer',
    preferred_language ENUM('gu','hi','en') NOT NULL DEFAULT 'hi',
    preferred_frequency ENUM('daily','weekly','special_only','none') NOT NULL DEFAULT 'daily',
    tags_json JSON NULL,
    is_blocked TINYINT(1) NOT NULL DEFAULT 0,
    deleted_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_contact_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_contact_user FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uq_contact_business_phone (business_id, phone_e164),
    INDEX idx_contact_type (business_id, contact_type),
    INDEX idx_contact_city (business_id, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `contact_preferences`

```sql
CREATE TABLE contact_preferences (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    contact_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NULL,
    fabric VARCHAR(100) NULL,
    color VARCHAR(100) NULL,
    min_price DECIMAL(12,2) NULL,
    max_price DECIMAL(12,2) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_preference_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_preference_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
    CONSTRAINT fk_preference_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_preference_contact (contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `consents`

This table makes future official WhatsApp API onboarding easier.

```sql
CREATE TABLE consents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    contact_id BIGINT UNSIGNED NOT NULL,
    consent_type ENUM('catalog_updates','offers','order_updates','whatsapp_api') NOT NULL,
    status ENUM('opted_in','opted_out','pending') NOT NULL DEFAULT 'pending',
    source ENUM('qr_form','catalog_form','website','shop','manual','import','other') NOT NULL,
    consent_text_version VARCHAR(50) NOT NULL,
    proof_path VARCHAR(500) NULL,
    ip_hash CHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    given_at DATETIME NULL,
    withdrawn_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_consent_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_consent_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
    INDEX idx_consent_search (business_id, consent_type, status),
    INDEX idx_consent_contact (contact_id, consent_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `inquiries`

```sql
CREATE TABLE inquiries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    contact_id BIGINT UNSIGNED NULL,
    product_id BIGINT UNSIGNED NULL,
    collection_id BIGINT UNSIGNED NULL,
    assigned_to_user_id BIGINT UNSIGNED NULL,
    source ENUM('catalog','whatsapp','manual','qr','instagram','website','other') NOT NULL DEFAULT 'catalog',
    status ENUM('new','contacted','catalog_sent','quoted','follow_up','ordered','lost','closed') NOT NULL DEFAULT 'new',
    message TEXT NULL,
    quoted_amount DECIMAL(12,2) NULL,
    next_follow_up_at DATETIME NULL,
    last_contacted_at DATETIME NULL,
    lost_reason VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inquiry_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_inquiry_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiry_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiry_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiry_assignee FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_inquiry_dashboard (business_id, status, next_follow_up_at),
    INDEX idx_inquiry_assignee (assigned_to_user_id, status),
    INDEX idx_inquiry_created (business_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `inquiry_activities`

```sql
CREATE TABLE inquiry_activities (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    inquiry_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    activity_type ENUM('created','note','status_changed','call','whatsapp_opened','quote_sent','follow_up_scheduled','product_shared') NOT NULL,
    body TEXT NULL,
    metadata_json JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_activity_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_activity_inquiry FOREIGN KEY (inquiry_id) REFERENCES inquiries(id) ON DELETE CASCADE,
    CONSTRAINT fk_activity_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_activity_inquiry (inquiry_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.5 Analytics and SaaS support tables

#### `catalog_views`

```sql
CREATE TABLE catalog_views (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    collection_id BIGINT UNSIGNED NULL,
    product_id BIGINT UNSIGNED NULL,
    visitor_hash CHAR(64) NULL,
    referrer VARCHAR(500) NULL,
    utm_source VARCHAR(100) NULL,
    utm_medium VARCHAR(100) NULL,
    utm_campaign VARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_view_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_view_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE SET NULL,
    CONSTRAINT fk_view_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    INDEX idx_view_collection_date (collection_id, created_at),
    INDEX idx_view_product_date (product_id, created_at),
    INDEX idx_view_business_date (business_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `share_links`

```sql
CREATE TABLE share_links (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    collection_id BIGINT UNSIGNED NULL,
    product_id BIGINT UNSIGNED NULL,
    created_by_user_id BIGINT UNSIGNED NOT NULL,
    short_code VARCHAR(30) NOT NULL UNIQUE,
    target_url VARCHAR(1000) NOT NULL,
    channel ENUM('whatsapp','instagram','qr','manual','other') NOT NULL DEFAULT 'whatsapp',
    click_count INT UNSIGNED NOT NULL DEFAULT 0,
    expires_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_share_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_share_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE SET NULL,
    CONSTRAINT fk_share_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    CONSTRAINT fk_share_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    INDEX idx_share_business_channel (business_id, channel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `notifications`

```sql
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    notification_type VARCHAR(80) NOT NULL,
    title VARCHAR(180) NOT NULL,
    body TEXT NULL,
    payload_json JSON NULL,
    read_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notification_user (user_id, read_at, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `audit_logs`

```sql
CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT UNSIGNED NULL,
    user_id BIGINT UNSIGNED NULL,
    action VARCHAR(120) NOT NULL,
    entity_type VARCHAR(100) NULL,
    entity_id BIGINT UNSIGNED NULL,
    old_values_json JSON NULL,
    new_values_json JSON NULL,
    ip_hash CHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_business_date (business_id, created_at),
    INDEX idx_audit_entity (entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 9. Relationships Summary

```text
Plan 1 ─────── * Business
Business 1 ─── * User
Business 1 ─── 1 BusinessSetting
Business 1 ─── * Category
Business 1 ─── * Product
Business 1 ─── * Collection
Collection * ─ * Product through CollectionProduct
Product 1 ─── * MediaAsset
Business 1 ─── * Contact
Contact 1 ─── * Consent
Contact 1 ─── * Inquiry
Product 1 ─── * Inquiry
Collection 1 ── * Inquiry
Inquiry 1 ──── * InquiryActivity
Business 1 ─── * CatalogView
Business 1 ─── * ShareLink
Business 1 ─── * Subscription
```

---

## 10. Authentication Design

Use opaque random Bearer tokens stored as SHA-256 hashes in `api_tokens`.

### Login flow

```text
Flutter sends email + password
      ↓
PHP finds user by email
      ↓
password_verify() verifies password_hash
      ↓
PHP creates cryptographically random token
      ↓
PHP stores hash('sha256', plainToken) in api_tokens
      ↓
PHP returns plainToken once to Flutter
      ↓
Flutter stores it in flutter_secure_storage
      ↓
Flutter sends Authorization: Bearer {token} on future requests
```

### Token generation

```php
$plainToken = bin2hex(random_bytes(32));
$tokenHash = hash('sha256', $plainToken);
```

### Password creation

```php
$passwordHash = password_hash($password, PASSWORD_ARGON2ID);
```

If Argon2ID is not available in your PHP build, use `PASSWORD_BCRYPT`.

### Auth middleware responsibilities

1. Read `Authorization: Bearer <token>`.
2. Hash token with SHA-256.
3. Find active non-revoked token.
4. Load user and business.
5. Ensure user is active.
6. Ensure normal users have active business and valid subscription/trial state.
7. Attach `current_user` and `business_id` to request context.
8. Update `last_used_at` periodically, not on every request if it becomes expensive.

---

## 11. API Routes

Base URL:

```text
https://api.yourdomain.com/api/v1
```

### 11.1 Public/unauthenticated routes

```text
POST   /auth/register-owner
POST   /auth/login
POST   /auth/forgot-password
POST   /auth/reset-password

GET    /public/catalog/{businessSlug}
GET    /public/catalog/{businessSlug}/collections/{collectionSlug}
GET    /public/catalog/{businessSlug}/products/{productCode}
POST   /public/catalog/{businessSlug}/inquiries
POST   /public/catalog/{businessSlug}/opt-ins
POST   /public/track/view
GET    /s/{shortCode}
```

### 11.2 Authenticated business routes

```text
POST   /auth/logout
GET    /auth/me
PATCH  /auth/me

GET    /business
PATCH  /business
GET    /business/settings
PATCH  /business/settings

GET    /staff
POST   /staff
PATCH  /staff/{id}
DELETE /staff/{id}

GET    /categories
POST   /categories
PATCH  /categories/{id}
DELETE /categories/{id}

GET    /products
POST   /products
GET    /products/{id}
PATCH  /products/{id}
DELETE /products/{id}
POST   /products/bulk-create
PATCH  /products/{id}/stock-status

POST   /media/upload
GET    /media/{id}
DELETE /media/{id}
PATCH  /media/{id}/sort

GET    /collections
POST   /collections
GET    /collections/{id}
PATCH  /collections/{id}
DELETE /collections/{id}
POST   /collections/{id}/products
DELETE /collections/{id}/products/{productId}
PATCH  /collections/{id}/product-order
POST   /collections/{id}/publish
POST   /collections/{id}/unpublish
POST   /collections/{id}/share-link
POST   /collections/{id}/generate-qr
POST   /collections/{id}/generate-pdf

GET    /contacts
POST   /contacts
GET    /contacts/{id}
PATCH  /contacts/{id}
DELETE /contacts/{id}
POST   /contacts/import-csv
GET    /contacts/export-csv
POST   /contacts/{id}/consents
POST   /contacts/{id}/opt-out

GET    /inquiries
POST   /inquiries
GET    /inquiries/{id}
PATCH  /inquiries/{id}
POST   /inquiries/{id}/activities
POST   /inquiries/{id}/assign
POST   /inquiries/{id}/follow-up
POST   /inquiries/{id}/mark-lost

GET    /dashboard
GET    /reports/catalog-performance
GET    /reports/inquiry-funnel
GET    /reports/top-products
GET    /reports/follow-ups

GET    /notifications
POST   /notifications/{id}/read
```

### 11.3 Platform admin routes

```text
GET    /admin/businesses
GET    /admin/businesses/{id}
PATCH  /admin/businesses/{id}/status
GET    /admin/plans
POST   /admin/plans
PATCH  /admin/plans/{id}
GET    /admin/subscriptions
POST   /admin/subscriptions
PATCH  /admin/subscriptions/{id}
GET    /admin/dashboard
```

Every `/admin` route must require `platform_admin` role.

---

## 12. Example Request/Response Patterns

### Create product

```http
POST /api/v1/products
Authorization: Bearer TOKEN
Content-Type: application/json
```

```json
{
  "product_code": "SR-250915-001",
  "title": "Premium Georgette Saree",
  "category_id": 4,
  "fabric": "Georgette",
  "color": "Pink",
  "price": 950,
  "price_label": "₹950 onwards",
  "stock_status": "available",
  "short_description": "New arrival, ready stock"
}
```

```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "id": 501,
    "product_code": "SR-250915-001",
    "stock_status": "available"
  }
}
```

### Public inquiry

```http
POST /api/v1/public/catalog/abc-textiles/inquiries
Content-Type: application/json
```

```json
{
  "product_code": "SR-250915-001",
  "collection_slug": "new-arrival-15-sep-2026",
  "name": "Riya Boutique",
  "phone": "+919876543210",
  "message": "Please send price and video."
}
```

```json
{
  "success": true,
  "message": "Inquiry submitted successfully",
  "data": {
    "inquiry_id": 890,
    "whatsapp_url": "https://wa.me/919999999999?text=..."
  }
}
```

---

## 13. Essential Service Rules

### ProductCodeService

Generate unique product codes per business.

Example format:

```text
SR-250915-001
ABC-SAR-0001
FAB-2026-0125
```

Rules:

- Prefix configured per business.
- Do not reuse old/sold-out product codes.
- Permit manual override after uniqueness check.
- Use transaction/unique index to avoid duplicate codes during concurrent uploads.

### ImageService

Responsibilities:

- Validate MIME type and file size.
- Generate a random safe filename.
- Store original outside `public/`.
- Generate optimized WebP/JPEG.
- Generate thumbnail.
- Apply configured watermark.
- Save media metadata in MySQL.
- Return public optimized URL.

### WhatsAppLinkService

Generate buyer-initiated click-to-chat link:

```php
$message = sprintf(
    'Hello, I am interested in Design %s from %s. Please share price, video and available stock.',
    $productCode,
    $collectionName
);

$url = 'https://wa.me/' . $businessWhatsappNumber . '?text=' . rawurlencode($message);
```

Version 1 should use click-to-chat. Do not make unofficial automated sending a dependency of this SaaS.

### InquiryService

When public buyer inquiry arrives:

1. Verify business and public product/collection exist.
2. Normalize phone to E.164 style as much as possible.
3. Create or find contact for this business only.
4. Create inquiry with source `catalog`.
5. Store inquiry activity `created`.
6. Return safe WhatsApp click-to-chat link.
7. Do not expose whether a phone number exists in your system.

---

## 14. Upload and Storage Design

### File locations

```text
storage/private/originals/business_12/2026/09/
public/uploads/optimized/business_12/2026/09/
public/uploads/thumbnails/business_12/2026/09/
public/uploads/watermarked/business_12/2026/09/
public/uploads/pdf/business_12/2026/09/
```

### Database paths

Store relative paths only:

```text
uploads/optimized/business_12/2026/09/a84f...webp
```

Build complete URL from configuration:

```php
$imageUrl = rtrim($_ENV['APP_URL'], '/') . '/' . $relativePath;
```

This makes migration to a new domain or cloud storage easier later.

### Image validation checklist

- Allow only `image/jpeg`, `image/png`, `image/webp` in V1.
- Verify actual file MIME type via `finfo`, not only extension.
- Maximum 10 MB per image initially.
- Use random filename; never save user-provided filename directly.
- Strip EXIF metadata if possible.
- Reject PHP/script files disguised as images.
- Do not allow SVG uploads in V1 because SVG can contain script content.
- Keep originals private; expose watermarked/optimized public copies.

### Upload API flow

```text
Flutter selects 50 images
      ↓
Flutter compresses locally when possible
      ↓
Flutter uploads images one-by-one or max 3 concurrent uploads
      ↓
POST /media/upload (multipart/form-data)
      ↓
PHP creates media_assets record with pending/ready status
      ↓
PHP processes image immediately OR adds row to image_jobs table
      ↓
Flutter polls media status
      ↓
Flutter attaches ready media to product
```

For your first release, immediate processing is acceptable. Add a job table later if upload processing becomes slow.

---

## 15. Optional Plain-PHP Queue Table

If you need background image tasks but have no persistent worker, add this table.

```sql
CREATE TABLE background_jobs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    job_type VARCHAR(100) NOT NULL,
    payload_json JSON NOT NULL,
    status ENUM('pending','processing','completed','failed') NOT NULL DEFAULT 'pending',
    attempts INT UNSIGNED NOT NULL DEFAULT 0,
    available_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    locked_at DATETIME NULL,
    completed_at DATETIME NULL,
    error_message TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_job_runner (status, available_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Then configure Windows Task Scheduler to run every minute:

```bat
C:\path\to\php.exe C:\inetpub\sites\textiledrop-api\scripts\process_image_queue.php
```

`process_image_queue.php` should:

1. Atomically lock one pending job.
2. Mark it processing.
3. Generate images/PDF/reminder.
4. Mark completed.
5. Retry up to 3 times.
6. Mark failed and log details if retries are exhausted.

Do not process the same job twice. Use a database transaction and lock/conditional update.

---

## 16. PHP Security Checklist

### Mandatory

- PHP 8.3+.
- HTTPS only.
- PDO prepared statements.
- `password_hash()` / `password_verify()`.
- Opaque API tokens stored only as SHA-256 hashes.
- Validate JSON body and multipart upload inputs.
- Authenticate every seller/admin route.
- Check roles for every restricted action.
- Enforce `business_id` at repository/query level.
- Rate limit login, registration, public inquiry, and opt-in endpoints.
- Use random file names.
- Validate real image MIME type.
- Do not return stack traces in production.
- Log server errors privately.
- Use CORS allow-list—do not allow all origins in production.
- Back up database and image folders daily.
- Keep `.env` out of `public/`.
- Use `utf8mb4` database charset.

### Recommended PHP headers

Set security headers from PHP or IIS:

```text
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; img-src 'self' data: https:; connect-src 'self' https://app.yourdomain.com https://catalog.yourdomain.com;
```

Adjust CSP after testing Flutter Web, because Flutter assets/WebAssembly may require additional allowances depending on build mode.

---

## 17. Flutter API Integration

### API base URLs by environment

```dart
class ApiConfig {
  static const devBaseUrl = 'https://dev-api.yourdomain.com/api/v1';
  static const productionBaseUrl = 'https://api.yourdomain.com/api/v1';
}
```

### Flutter client rules

- Store API token using `flutter_secure_storage`.
- Add `Authorization: Bearer TOKEN` to authenticated API calls.
- Use Dio interceptors for 401/logout/error handling.
- Support multipart uploads with progress callback.
- Upload maximum 3 images concurrently to avoid memory/network issues.
- Cache product/collection drafts using Drift/SQLite when network fails.
- On public catalog, do not require login for basic browsing.

### Suggested Flutter features

```text
features/
├── auth/
├── onboarding/
├── dashboard/
├── products/
├── upload/
├── collections/
├── catalog_share/
├── contacts/
├── inquiries/
├── followups/
├── reports/
├── settings/
└── public_catalog/
```

---

## 18. Core MVP Build Order

### Step 1: Foundation

- Create PHP project structure.
- Add composer autoload (recommended).
- Build Router, Request, Response, Database, Auth.
- Create MySQL core schema: plans, businesses, users, api_tokens.
- Create owner registration and login APIs.
- Test with Postman before Flutter.

### Step 2: Multi-tenant catalog data

- Add business settings and categories.
- Add product CRUD.
- Enforce tenant filtering.
- Add product-code generation.
- Add media upload and local storage.

### Step 3: Daily Drop

- Add collections and collection_products.
- Create publish/unpublish flow.
- Create public catalog API.
- Build Flutter public catalog page.

### Step 4: WhatsApp inquiry flow

- Add contacts, inquiries, inquiry activities.
- Add public inquiry endpoint.
- Create click-to-chat URL with product code.
- Build seller inquiry list and follow-up date.

### Step 5: SaaS controls

- Add plans and subscriptions.
- Add quota checks: users, products, storage.
- Add platform admin APIs.
- Add audit logs.
- Add daily backup/script plan.

### Step 6: Pilot and improve

- Onboard three Surat textile customers.
- Observe daily image upload workflow.
- Fix speed, upload, product-code, and catalog UX problems.
- Only then add PDF, buyer preferences, dealer prices, orders, and official WhatsApp API integration.

---

## 19. MVP Definition of Done

A business owner must be able to complete this without your help:

1. Register their business and log in.
2. Upload 20 textile images.
3. Create products with automatic design codes.
4. Add products to a collection called “Today’s New Arrival.”
5. Publish one public catalog link.
6. Share that link on WhatsApp.
7. Buyer opens catalog on mobile and searches a product code.
8. Buyer taps “Ask on WhatsApp.”
9. Seller sees linked inquiry in Flutter app.
10. Seller sets a follow-up date and updates status.

If this works reliably, launch a paid pilot before adding complex automation.

---

## 20. AI Coding Prompt: Backend Generation

Use this prompt with your coding AI. Generate and test in modules, not as one huge uncontrolled code dump.

```text
Build a plain PHP 8.3 REST API named TextileDrop for a multi-tenant textile catalog SaaS. Do not use Laravel, Symfony, CodeIgniter, Node.js, Docker, or a framework. Use index.php as a single front controller and organize code inside src/.

Environment:
- Windows IIS PHP hosting
- MySQL 8
- PHP PDO with real prepared statements
- Flutter Android/Web clients
- Local file storage for product images

Required project structure:
- public/index.php as only web entry point
- src/Core: App, Router, Request, Response, Database, Auth, Validator, Upload, ImageProcessor, Logger
- src/Middleware: AuthMiddleware, TenantMiddleware, RoleMiddleware, CorsMiddleware, RateLimitMiddleware
- src/Controllers, src/Services, src/Repositories, src/Routes
- config/, database/migrations/, storage/private/, public/uploads/

Implement first vertical slice only:
1. MySQL migration SQL for plans, businesses, users, api_tokens, categories, products, collections, collection_products, media_assets.
2. PDO Database class with ERRMODE_EXCEPTION, utf8mb4, ATTR_EMULATE_PREPARES=false.
3. Owner registration API and login API.
4. Password hashing with PASSWORD_ARGON2ID.
5. Opaque Bearer tokens generated with random_bytes(32); store SHA-256 hash only in api_tokens.
6. Auth middleware reads Bearer token, loads active user/business, and sets request context.
7. Tenant security: never take business_id from request body; scope every business query from authenticated user’s business_id.
8. Product CRUD with prepared statements and ownership validation.
9. Collection create/list/publish APIs.
10. Public catalog endpoint that exposes only public/published products and never exposes cost_price, internal_notes, staff data, buyer data, or internal stock quantity.
11. JSON responses in format: {success, message, data, meta}.
12. IIS public/web.config rewrite rules.
13. .env.example and clear local/Windows deployment instructions.

Write secure, modular PHP code with type declarations. Do not put business logic inside index.php. Include Postman test examples for every endpoint.
```

---

## 21. Final Product Positioning

Do not position the system as only a WhatsApp sender.

Position it as:

> **TextileDrop: Surat textile traders ke liye daily new-arrival catalog, design-code, buyer inquiry, and WhatsApp sales workflow system.**

Your first value is:

```text
No more forwarding 100 loose images daily.
Upload once → publish one catalog link → buyer asks by design code → every inquiry is tracked.
```