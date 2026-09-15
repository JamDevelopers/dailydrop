-- TextileDrop MySQL Migration 001: Core SaaS Tables
-- Plans, Businesses, Users, API Tokens, Subscriptions

CREATE TABLE IF NOT EXISTS plans (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS businesses (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_tokens (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subscriptions (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

