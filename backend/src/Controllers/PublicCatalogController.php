<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;
use TextileDrop\Services\InquiryService;
use TextileDrop\Services\WhatsAppLinkService;

class PublicCatalogController
{
    private Database $db;
    private InquiryService $inquiryService;

    public function __construct(Database $db)
    {
        $this->db = $db;
        $this->inquiryService = new InquiryService($db);
    }

    public function getBusinessBySlug(Request $request, array $params): void
    {
        $slug = (string)($params['slug'] ?? '');

        $stmt = $this->db->pdo()->prepare(
            'SELECT b.id, b.business_name, b.slug, b.market_name, b.shop_number, b.city, b.state, b.logo_url, b.primary_phone,
                    s.sku_prefix, s.show_prices_publicly, s.enable_watermark, s.watermark_text, s.whatsapp_phone, s.instagram_handle
             FROM businesses b
             LEFT JOIN business_settings s ON s.business_id = b.id
             WHERE b.slug = :slug AND b.status != "suspended"
             LIMIT 1'
        );
        $stmt->execute([':slug' => $slug]);
        $business = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$business) {
            Response::notFound('Textile store not found.');
        }

        $businessId = (int)$business['id'];
        $business['id'] = $businessId;
        $business['show_prices_publicly'] = (bool)$business['show_prices_publicly'];
        $business['enable_watermark'] = (bool)$business['enable_watermark'];

        // Fetch published collections that are public in main catalog
        $colStmt = $this->db->pdo()->prepare(
            'SELECT c.*, 
                    (SELECT COUNT(*) FROM collection_products cp WHERE cp.collection_id = c.id) AS product_count,
                    (SELECT ma.original_path FROM collection_products cp 
                     JOIN media_assets ma ON ma.product_id = cp.product_id 
                     WHERE cp.collection_id = c.id ORDER BY cp.sort_order ASC LIMIT 1) AS sample_image
             FROM collections c
             WHERE c.business_id = :business_id 
               AND c.visibility = "public" 
               AND c.show_in_main_catalog = 1
             ORDER BY c.collection_date DESC, c.id DESC'
        );
        $colStmt->execute([':business_id' => $businessId]);
        $collections = $colStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($collections as &$col) {
            $col['is_expired'] = !empty($col['expires_at']) && strtotime($col['expires_at']) < time();
        }

        // Fetch latest published products with multi-image URLs for carousels
        $prodStmt = $this->db->pdo()->prepare(
            'SELECT p.*,
                    (SELECT file_url FROM media_assets WHERE product_id = p.id AND is_cover = 1 LIMIT 1) AS cover_image
             FROM products p
             WHERE p.business_id = :business_id AND p.is_public = 1 AND p.stock_status != "discontinued"
             ORDER BY p.id DESC LIMIT 40'
        );
        $prodStmt->execute([':business_id' => $businessId]);
        $products = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

        $showPrice = (bool)$business['show_prices_publicly'];

        foreach ($products as &$p) {
            $p['id'] = (int)$p['id'];
            $p['set_count'] = (int)($p['set_count'] ?? 4);
            $p['price'] = $showPrice && $p['price'] !== null ? (float)$p['price'] : null;

            // Fetch image URLs array for swipeable carousel
            $mStmt = $this->db->pdo()->prepare('SELECT file_url FROM media_assets WHERE product_id = :pid ORDER BY sort_order ASC');
            $mStmt->execute([':pid' => $p['id']]);
            $p['image_urls'] = $mStmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        Response::success([
            'business' => $business,
            'collections' => $collections,
            'products' => $products,
        ]);
    }

    public function getCollectionBySlug(Request $request, array $params): void
    {
        $businessSlug = (string)($params['slug'] ?? '');
        $dropTokenOrSlug = (string)($params['drop_slug'] ?? '');

        // Business
        $bStmt = $this->db->pdo()->prepare(
            'SELECT b.*, s.show_prices_publicly, s.whatsapp_phone, s.watermark_text
             FROM businesses b
             LEFT JOIN business_settings s ON s.business_id = b.id
             WHERE b.slug = :slug LIMIT 1'
        );
        $bStmt->execute([':slug' => $businessSlug]);
        $business = $bStmt->fetch(PDO::FETCH_ASSOC);

        if (!$business) {
            Response::notFound('Business not found.');
        }

        $businessId = (int)$business['id'];

        // Collection by share_token or slug
        $cStmt = $this->db->pdo()->prepare(
            'SELECT * FROM collections 
             WHERE business_id = :business_id 
               AND (share_token = :token OR slug = :slug) 
               AND visibility != "draft" 
             LIMIT 1'
        );
        $cStmt->execute([':business_id' => $businessId, ':token' => $dropTokenOrSlug, ':slug' => $dropTokenOrSlug]);
        $collection = $cStmt->fetch(PDO::FETCH_ASSOC);

        if (!$collection) {
            Response::notFound('Collection drop not found.');
        }

        $isExpired = !empty($collection['expires_at']) && strtotime($collection['expires_at']) < time();
        $collection['is_expired'] = $isExpired;

        // Fetch products
        $prodStmt = $this->db->pdo()->prepare(
            'SELECT p.*, cp.sort_order,
                    (SELECT file_url FROM media_assets WHERE product_id = p.id AND is_cover = 1 LIMIT 1) AS cover_image
             FROM collection_products cp
             JOIN products p ON p.id = cp.product_id
             WHERE cp.collection_id = :col_id
             ORDER BY cp.sort_order ASC'
        );
        $prodStmt->execute([':col_id' => $collection['id']]);
        $products = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

        $showPrice = (bool)($business['show_prices_publicly'] ?? true);
        foreach ($products as &$p) {
            $p['id'] = (int)$p['id'];
            $p['set_count'] = (int)($p['set_count'] ?? 4);
            $p['price'] = $showPrice && $p['price'] !== null ? (float)$p['price'] : null;

            $mStmt = $this->db->pdo()->prepare('SELECT file_url FROM media_assets WHERE product_id = :pid ORDER BY sort_order ASC');
            $mStmt->execute([':pid' => $p['id']]);
            $p['image_urls'] = $mStmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        Response::success([
            'business' => [
                'id' => $businessId,
                'name' => $business['business_name'],
                'market_name' => $business['market_name'],
                'primary_phone' => $business['primary_phone'],
                'whatsapp_phone' => $business['whatsapp_phone'] ?? $business['primary_phone'],
                'show_prices_publicly' => $showPrice,
            ],
            'collection' => $collection,
            'products' => $products,
        ]);
    }

    public function submitInquiry(Request $request, array $params): void
    {
        $businessSlug = (string)($params['slug'] ?? '');

        $bStmt = $this->db->pdo()->prepare(
            'SELECT b.id, b.business_name, b.primary_phone, s.whatsapp_phone 
             FROM businesses b 
             LEFT JOIN business_settings s ON s.business_id = b.id 
             WHERE b.slug = :slug LIMIT 1'
        );
        $bStmt->execute([':slug' => $businessSlug]);
        $business = $bStmt->fetch(PDO::FETCH_ASSOC);

        if (!$business) {
            Response::notFound('Business not found.');
        }

        $validator = Validator::make($request->all(), [
            'buyer_name' => 'required|min:2|max:100',
            'buyer_phone' => 'required|min:10|max:20',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $businessId = (int)$business['id'];
        $buyerName = trim((string)$request->input('buyer_name'));
        $buyerPhone = trim((string)$request->input('buyer_phone'));
        $buyerCity = $request->input('buyer_city');
        $productId = $request->input('product_id') ? (int)$request->input('product_id') : null;
        $productCode = $request->input('product_code');
        $fabricType = $request->input('fabric');
        $price = $request->input('price') !== null ? (float)$request->input('price') : null;
        $message = $request->input('message');

        $inquiry = $this->inquiryService->createInquiry(
            $businessId,
            $buyerName,
            $buyerPhone,
            $buyerCity,
            $productId,
            $request->input('collection_id') ? (int)$request->input('collection_id') : null,
            $message,
            'public_catalog',
            $productCode
        );

        $sellerPhone = $business['whatsapp_phone'] ?: $business['primary_phone'];
        $waLink = WhatsAppLinkService::generateInquiryLink(
            $sellerPhone,
            $business['business_name'],
            $productCode ?: 'Daily Drop',
            $fabricType,
            $price,
            $buyerName
        );

        Response::success([
            'inquiry' => $inquiry,
            'whatsapp_url' => $waLink,
        ], 'Inquiry logged successfully. Redirecting to WhatsApp chat.');
    }

    public function trackView(Request $request, array $params): void
    {
        $businessSlug = (string)($params['slug'] ?? '');
        $dropSlug = $request->input('drop_slug');

        $bStmt = $this->db->pdo()->prepare('SELECT id FROM businesses WHERE slug = :slug LIMIT 1');
        $bStmt->execute([':slug' => $businessSlug]);
        $businessId = $bStmt->fetchColumn();

        if ($businessId) {
            $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
            $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';

            $stmt = $this->db->pdo()->prepare(
                'INSERT INTO catalog_views (business_id, collection_id, ip_address, user_agent, view_date, created_at)
                 VALUES (:bid, NULL, :ip, :ua, CURDATE(), NOW())'
            );
            $stmt->execute([
                ':bid' => $businessId,
                ':ip' => substr($ip, 0, 45),
                ':ua' => substr($ua, 0, 255),
            ]);

            if ($dropSlug) {
                $cStmt = $this->db->pdo()->prepare('UPDATE collections SET views_count = views_count + 1 WHERE slug = :slug AND business_id = :bid');
                $cStmt->execute([':slug' => $dropSlug, ':bid' => $businessId]);
            }
        }

        Response::success(['tracked' => true]);
    }
}
