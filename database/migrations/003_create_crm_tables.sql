-- TextileDrop MySQL Migration 003: Buyer CRM, Consents, Inquiries, and Inquiry Activities

CREATE TABLE IF NOT EXISTS contacts (
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
    contact_type ENUM('buyer','dealer','reseller','retailer','boutique','other') NOT NULL DEFAULT 'buyer',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contact_preferences (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS consents (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inquiries (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inquiry_activities (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

