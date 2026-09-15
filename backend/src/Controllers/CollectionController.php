<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;
use TextileDrop\Services\WhatsAppLinkService;

class CollectionController
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function index(Request $request): void
    {
        $businessId = (int)$request->businessId();

        $stmt = $this->db->pdo()->prepare(
            'SELECT c.*, 
                    (SELECT COUNT(*) FROM collection_products cp WHERE cp.collection_id = c.id) AS product_count,
                    (SELECT ma.original_path FROM collection_products cp 
                     JOIN media_assets ma ON ma.product_id = cp.product_id 
                     WHERE cp.collection_id = c.id ORDER BY cp.sort_order ASC LIMIT 1) AS sample_image
             FROM collections c
             WHERE c.business_id = :business_id
             ORDER BY c.collection_date DESC, c.id DESC'
        );
        $stmt->execute([':business_id' => $businessId]);
        $collections = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($collections as &$col) {
            $col['id'] = (int)$col['id'];
            $col['business_id'] = (int)$col['business_id'];
            $col['total_products'] = (int)$col['product_count'];
            $col['show_in_main_catalog'] = (bool)$col['show_in_main_catalog'];
            $col['is_expired'] = !empty($col['expires_at']) && strtotime($col['expires_at']) < time();
        }

        Response::success($collections);
    }

    public function show(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $collectionId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare(
            'SELECT * FROM collections WHERE id = :id AND business_id = :business_id LIMIT 1'
        );
        $stmt->execute([':id' => $collectionId, ':business_id' => $businessId]);
        $collection = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$collection) {
            Response::notFound('Collection not found.');
        }

        $collection['id'] = (int)$collection['id'];
        $collection['show_in_main_catalog'] = (bool)$collection['show_in_main_catalog'];
        $collection['is_expired'] = !empty($collection['expires_at']) && strtotime($collection['expires_at']) < time();

        // Fetch products in this collection with all images
        $prodStmt = $this->db->pdo()->prepare(
            'SELECT p.*, cp.sort_order,
                    (SELECT file_url FROM media_assets WHERE product_id = p.id AND is_cover = 1 LIMIT 1) AS cover_image
             FROM collection_products cp
             JOIN products p ON p.id = cp.product_id
             WHERE cp.collection_id = :collection_id
             ORDER BY cp.sort_order ASC, p.id DESC'
        );
        $prodStmt->execute([':collection_id' => $collectionId]);
        $products = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($products as &$p) {
            $p['id'] = (int)$p['id'];
            $p['set_count'] = (int)($p['set_count'] ?? 4);
            $p['price'] = $p['price'] !== null ? (float)$p['price'] : null;

            $mStmt = $this->db->pdo()->prepare('SELECT file_url FROM media_assets WHERE product_id = :pid ORDER BY sort_order ASC');
            $mStmt->execute([':pid' => $p['id']]);
            $p['image_urls'] = $mStmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        $collection['products'] = $products;

        Response::success($collection);
    }

    public function store(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $validator = Validator::make($request->all(), [
            'name' => 'required|min:2|max:180',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $name = trim((string)$request->input('name'));
        $description = $request->input('description');
        $collectionDate = $request->input('collection_date') ?: date('Y-m-d');
        $visibility = $request->input('visibility', 'public');
        $priceVisibility = $request->input('price_visibility', 'show');
        $showInMainCatalog = $request->input('show_in_main_catalog', true) ? 1 : 0;
        $festival = $request->input('festival');
        $occasion = $request->input('occasion');
        $expiresAt = $request->input('expires_at');
        $productIds = $request->input('product_ids', []);

        // Base slug & share token
        $baseSlug = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', $name));
        $slug = $baseSlug . '-' . date('ymd', strtotime($collectionDate));
        $shareToken = 'drop-' . bin2hex(random_bytes(8));

        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO collections (
                    business_id, created_by_user_id, name, slug, description,
                    collection_date, visibility, price_visibility, show_in_main_catalog,
                    festival, occasion, share_token, published_at, expires_at, created_at, updated_at
                ) VALUES (
                    :business_id, 1, :name, :slug, :description,
                    :collection_date, :visibility, :price_visibility, :show_in_main_catalog,
                    :festival, :occasion, :share_token, NOW(), :expires_at, NOW(), NOW()
                )'
            );
            $stmt->execute([
                ':business_id' => $businessId,
                ':name' => $name,
                ':slug' => $slug,
                ':description' => $description,
                ':collection_date' => $collectionDate,
                ':visibility' => $visibility,
                ':price_visibility' => $priceVisibility,
                ':show_in_main_catalog' => $showInMainCatalog,
                ':festival' => $festival,
                ':occasion' => $occasion,
                ':share_token' => $shareToken,
                ':expires_at' => $expiresAt,
            ]);
            $collectionId = (int)$pdo->lastInsertId();

            if (!empty($productIds)) {
                $cpStmt = $pdo->prepare(
                    'INSERT INTO collection_products (business_id, collection_id, product_id, sort_order) VALUES (:business_id, :collection_id, :product_id, :sort_order)'
                );
                foreach ($productIds as $idx => $pid) {
                    $cpStmt->execute([
                        ':business_id' => $businessId,
                        ':collection_id' => $collectionId,
                        ':product_id' => (int)$pid,
                        ':sort_order' => $idx,
                    ]);
                }
            }

            $pdo->commit();

            Response::success([
                'id' => $collectionId,
                'name' => $name,
                'slug' => $slug,
                'share_token' => $shareToken,
                'show_in_main_catalog' => (bool)$showInMainCatalog,
                'expires_at' => $expiresAt,
                'total_products' => count($productIds),
            ], 'Collection created successfully', 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function share(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $collectionId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare(
            'SELECT c.*, b.business_name, b.slug AS business_slug, b.market_name,
                    (SELECT COUNT(*) FROM collection_products cp WHERE cp.collection_id = c.id) AS product_count
             FROM collections c
             JOIN businesses b ON b.id = c.business_id
             WHERE c.id = :id AND c.business_id = :business_id LIMIT 1'
        );
        $stmt->execute([':id' => $collectionId, ':business_id' => $businessId]);
        $collection = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$collection) {
            Response::notFound('Collection not found.');
        }

        $appUrl = $_ENV['CATALOG_PUBLIC_URL'] ?? 'http://localhost/catalog';
        $catalogUrl = rtrim($appUrl, '/') . '/' . $collection['business_slug'] . '/drop/' . $collection['share_token'];

        $shareText = WhatsAppLinkService::generateCollectionShareText(
            $collection['business_name'],
            $collection['name'],
            (int)$collection['product_count'],
            $catalogUrl,
            $collection['market_name']
        );

        Response::success([
            'collection_id' => $collectionId,
            'catalog_url' => $catalogUrl,
            'share_token' => $collection['share_token'],
            'expires_at' => $collection['expires_at'],
            'is_expired' => !empty($collection['expires_at']) && strtotime($collection['expires_at']) < time(),
            'whatsapp_share_text' => $shareText,
            'whatsapp_share_link' => 'https://wa.me/?text=' . rawurlencode($shareText),
            'qr_code_url' => 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=' . rawurlencode($catalogUrl),
        ]);
    }

    public function delete(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $collectionId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare('DELETE FROM collections WHERE id = :id AND business_id = :business_id');
        $stmt->execute([':id' => $collectionId, ':business_id' => $businessId]);

        Response::success(null, 'Collection deleted successfully');
    }
}
