-- TextileDrop MySQL Seed Data: Surat Wholesaler Demo Store
-- Ingests plans, demo business (Surat Silk Mills), categories, products, collections, CRM contacts, and inquiries

-- 1. Plans
INSERT INTO plans (id, code, name, monthly_price, yearly_price, max_users, max_products, max_storage_mb, is_active)
VALUES 
(1, 'starter', 'Surat Trader Starter', 999.00, 9990.00, 2, 300, 2048, 1),
(2, 'growth', 'Wholesaler Pro', 2499.00, 24990.00, 5, 2000, 10240, 1)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 2. Business
INSERT INTO businesses (id, public_id, plan_id, name, legal_name, slug, business_type, owner_name, phone, whatsapp_number, email, address_line1, city, state, pincode, gst_number, subscription_status, storage_used_bytes)
VALUES
(1, 'biz_suratsilk2026', 2, 'Surat Silk Mills', 'Surat Silk Mills Pvt Ltd', 'surat-silk-mills', 'textile_wholesaler', 'Rajeshbhai Patel', '+91 98251 23456', '919825123456', 'sales@suratsilkmills.com', 'Shop 402-405, Millennium Textile Market, Ring Road', 'Surat', 'Gujarat', '395002', '24AACCS1234F1Z5', 'active', 440401920)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 3. Business Settings
INSERT INTO business_settings (business_id, catalog_title, catalog_description, default_currency, show_prices_publicly, allow_guest_inquiry, watermark_enabled, watermark_text, inquiry_whatsapp_template)
VALUES
(1, 'Surat Silk Mills • Today\'s Wholesale Drop', 'Exclusive Georgette, Dola Silk Sarees & Designer Kurtis direct from Surat manufacturer.', 'INR', 1, 1, 1, 'Surat Silk Mills', 'Hello, I am interested in Design {product_code} from {collection_name}. Please share price, video and available stock.')
ON DUPLICATE KEY UPDATE catalog_title=VALUES(catalog_title);

-- 4. Users (Password: Surat@2026)
INSERT INTO users (id, business_id, name, email, phone, password_hash, role, is_active)
VALUES
(1, 1, 'Rajeshbhai Patel', 'rajesh@suratsilkmills.com', '+91 98251 23456', '$2y$12$eZ3e0M1R/rBkW3sL8zL3O.k3t3B6q2L6c8y5w0n4c0g6l4j4h8x0m', 'owner', 1),
(2, 1, 'Amit Shah', 'amit@suratsilkmills.com', '+91 98251 78901', '$2y$12$eZ3e0M1R/rBkW3sL8zL3O.k3t3B6q2L6c8y5w0n4c0g6l4j4h8x0m', 'sales_staff', 1)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 5. Categories
INSERT INTO categories (id, business_id, name, slug, sort_order)
VALUES
(1, 1, 'Saree Collection', 'saree', 1),
(2, 1, 'Designer Kurtis', 'kurti', 2),
(3, 1, 'Dress Materials', 'dress-material', 3),
(4, 1, 'Bridal Lehenga', 'lehenga', 4)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 6. Products
INSERT INTO products (id, business_id, category_id, created_by_user_id, product_code, title, fabric, color, brand, price, price_label, cost_price, stock_status, stock_quantity, short_description, internal_notes, is_public)
VALUES
(101, 1, 1, 1, 'SR-260915-001', 'Pure Dola Silk Banarasi Saree with Rich Pallu', 'Dola Silk', 'Maroon', 'Surat Silk Exclusive', 1250.00, '₹1,250 / Pc (Set of 6)', 850.00, 'available', 150, 'Heavy Zari weaving work on Dola silk with contrast border.', 'Mill Lot #442. Minimum order 1 set.', 1),
(102, 1, 1, 1, 'SR-260915-002', 'Pure Georgette Foil Print Saree with Scallop Border', 'Georgette', 'Emerald Green', 'Surat Silk Exclusive', 890.00, '₹890 / Pc', 580.00, 'available', 220, '60 gram pure georgette fabric with gold foil stamping.', 'Fast moving festive item.', 1),
(103, 1, 2, 1, 'SR-260915-003', 'Rayon 14kg Handwork Anarkali Kurti with Dupatta', 'Rayon 14kg', 'Pink / Rani', 'Radha Rani', 650.00, '₹650 (Sizes: M, L, XL, XXL)', 420.00, 'limited', 45, 'Heavy mirror handwork with organza dupatta.', 'Only 45 pcs remaining.', 1),
(104, 1, 3, 1, 'SR-260915-004', 'Jam Cotton Unstitched Suit with Pure Nazneen Dupatta', 'Cotton', 'Mustard Yellow', 'Surat Fashion Hub', 520.00, '₹520 / Catalog Suit', 340.00, 'available', 300, 'Pure Jam cotton top 2.50m, pure cotton bottom 2.70m.', 'Best seller for daily wear boutiques.', 1),
(105, 1, 4, 1, 'SR-260915-005', 'Velvet Heavy Multi-Sequence Bridal Semi-Stitched Lehenga', 'Velvet', 'Royal Blue', 'Ambaji Creation', 3850.00, '₹3,850 / Single Piece', 2400.00, 'available', 35, '9000 Micro velvet with 5mm tone-to-tone sequence work.', 'Bridal season special.', 1)
ON DUPLICATE KEY UPDATE title=VALUES(title);

-- 7. Collections
INSERT INTO collections (id, business_id, created_by_user_id, name, slug, description, collection_date, visibility, price_visibility, share_token, published_at)
VALUES
(201, 1, 1, 'Today\'s Daily Drop • 15 Sep 2026', 'todays-drop-15-sep-2026', 'Exclusive 5 fresh designs in Dola Silk, Georgette & Rayon direct from Surat factory floor.', '2026-09-15', 'public', 'show', 'drop-2026-09-15', '2026-09-15 09:00:00')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 8. Collection Products
INSERT INTO collection_products (business_id, collection_id, product_id, sort_order)
VALUES
(1, 201, 101, 1),
(1, 201, 102, 2),
(1, 201, 103, 3),
(1, 201, 104, 4),
(1, 201, 105, 5)
ON DUPLICATE KEY UPDATE sort_order=VALUES(sort_order);

-- 9. Contacts CRM
INSERT INTO contacts (id, business_id, name, phone_e164, company_name, city, state, contact_type, preferred_language)
VALUES
(301, 1, 'Pooja Sharma', '+919876543210', 'Riya Boutique', 'Ahmedabad', 'Gujarat', 'boutique', 'gu'),
(302, 1, 'Manish Agarwal', '+919811122334', 'Agarwal Saree Sadan', 'Jaipur', 'Rajasthan', 'dealer', 'hi')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 10. Inquiries
INSERT INTO inquiries (id, business_id, contact_id, product_id, collection_id, assigned_to_user_id, source, status, message, quoted_amount)
VALUES
(401, 1, 301, 101, 201, 2, 'catalog', 'new', 'Please send video and available 6 colors in this Dola silk design. Ready to book 2 full sets.', 15000.00),
(402, 1, 302, 102, 201, 2, 'catalog', 'quoted', 'Need 50 pcs dispatch to Jaipur transporter.', 44500.00)
ON DUPLICATE KEY UPDATE status=VALUES(status);

