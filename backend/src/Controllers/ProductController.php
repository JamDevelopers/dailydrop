<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;
use TextileDrop\Services\ProductCodeService;

class ProductController
{
    private Database $db;
    private ProductCodeService $codeService;

    public function __construct(Database $db)
    {
        $this->db = $db;
        $this->codeService = new ProductCodeService($db);
    }

    public function index(Request $request): void
    {
        $businessId = $request->businessId();
        $query = $request->query('query', '');
        $status = $request->query('status', '');
        $fabric = $request->query('fabric', '');
        $festival = $request->query('festival', '');
        $occasion = $request->query('occasion', '');
        $categoryId = $request->query('category_id', null);
        $page = max(1, (int)$request->query('page', 1));
        $limit = min(100, max(1, (int)$request->query('limit', 20)));
        $offset = ($page - 1) * $limit;

        $sql = 'SELECT p.*, c.name AS category_name,
                       (SELECT file_url FROM media_assets WHERE product_id = p.id AND is_cover = 1 LIMIT 1) AS cover_image
                FROM products p
                LEFT JOIN categories c ON c.id = p.category_id
                WHERE p.business_id = :business_id';

        $params = [':business_id' => $businessId];

        if (!empty($query)) {
            $sql .= ' AND (p.product_code LIKE :q OR p.title LIKE :q OR p.fabric LIKE :q OR p.festival LIKE :q OR p.occasion LIKE :q)';
            $params[':q'] = "%{$query}%";
        }

        if (!empty($status)) {
            $sql .= ' AND p.stock_status = :status';
            $params[':status'] = $status;
        }

        if (!empty($fabric)) {
            $sql .= ' AND p.fabric = :fabric';
            $params[':fabric'] = $fabric;
        }

        if (!empty($festival)) {
            $sql .= ' AND p.festival = :festival';
            $params[':festival'] = $festival;
        }

        if (!empty($occasion)) {
            $sql .= ' AND p.occasion = :occasion';
            $params[':occasion'] = $occasion;
        }

        if (!empty($categoryId)) {
            $sql .= ' AND p.category_id = :cat_id';
            $params[':cat_id'] = (int)$categoryId;
        }

        // Count total
        $countSql = "SELECT COUNT(*) FROM ({$sql}) AS total_tbl";
        $countStmt = $this->db->pdo()->prepare($countSql);
        $countStmt->execute($params);
        $totalItems = (int)$countStmt->fetchColumn();

        // Fetch records
        $sql .= ' ORDER BY p.id DESC LIMIT :limit OFFSET :offset';
        $stmt = $this->db->pdo()->prepare($sql);
        foreach ($params as $k => $v) {
            $stmt->bindValue($k, $v);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch media assets for each product
        foreach ($products as &$p) {
            $p['id'] = (int)$p['id'];
            $p['business_id'] = (int)$p['business_id'];
            $p['set_count'] = (int)($p['set_count'] ?? 4);
            $p['price'] = $p['price'] !== null ? (float)$p['price'] : null;

            $mStmt = $this->db->pdo()->prepare('SELECT file_url FROM media_assets WHERE product_id = :pid ORDER BY sort_order ASC');
            $mStmt->execute([':pid' => $p['id']]);
            $p['image_urls'] = $mStmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        Response::success($products, 'Products retrieved successfully', 200, [
            'page' => $page,
            'limit' => $limit,
            'total' => $totalItems,
            'total_pages' => (int)ceil($totalItems / $limit),
        ]);
    }

    public function show(Request $request, array $params): void
    {
        $businessId = $request->businessId();
        $productId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare(
            'SELECT p.*, c.name AS category_name
             FROM products p
             LEFT JOIN categories c ON c.id = p.category_id
             WHERE p.id = :id AND p.business_id = :business_id
             LIMIT 1'
        );
        $stmt->execute([':id' => $productId, ':business_id' => $businessId]);
        $product = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$product) {
            Response::notFound('Product not found.');
        }

        $product['id'] = (int)$product['id'];
        $product['set_count'] = (int)($product['set_count'] ?? 4);
        $product['price'] = $product['price'] !== null ? (float)$product['price'] : null;

        // Fetch media assets
        $mediaStmt = $this->db->pdo()->prepare(
            'SELECT * FROM media_assets WHERE product_id = :product_id ORDER BY sort_order ASC, is_cover DESC'
        );
        $mediaStmt->execute([':product_id' => $productId]);
        $product['media'] = $mediaStmt->fetchAll(PDO::FETCH_ASSOC);
        $product['image_urls'] = array_column($product['media'], 'file_url');

        Response::success($product);
    }

    public function generateCode(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $prefix = $request->query('prefix');
        $code = $this->codeService->generateNextCode($businessId, $prefix);

        Response::success(['product_code' => $code]);
    }

    public function store(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $validator = Validator::make($request->all(), [
            'title' => 'required|min:2|max:200',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $title = trim((string)$request->input('title'));
        $productCode = $request->input('product_code')
            ? strtoupper(trim((string)$request->input('product_code')))
            : $this->codeService->generateNextCode($businessId);

        $price = $request->input('price') !== null ? (float)$request->input('price') : null;
        $priceLabel = $request->input('price_label');
        $fabric = $request->input('fabric') ? trim((string)$request->input('fabric')) : null;
        $color = $request->input('color');
        $size = $request->input('size');
        $occasion = $request->input('occasion');
        $festival = $request->input('festival');
        $setCount = (int)($request->input('set_count') ?? 4);
        $setLabel = $request->input('set_label') ?? "Set of {$setCount}";
        $stockStatus = $request->input('stock_status') ?? 'available';
        $stockQuantity = $request->input('stock_quantity') !== null ? (int)$request->input('stock_quantity') : null;
        $description = $request->input('short_description') ?? $request->input('description');
        $internalNotes = $request->input('internal_notes');
        $categoryId = $request->input('category_id') ? (int)$request->input('category_id') : null;
        $images = $request->input('image_urls', []);
        $isPublic = $request->input('is_public', true) ? 1 : 0;

        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO products (
                    business_id, category_id, created_by_user_id, product_code, title,
                    fabric, color, size, occasion, festival, set_count, set_label,
                    price, price_label, stock_status, stock_quantity, short_description,
                    internal_notes, is_public, created_at, updated_at
                ) VALUES (
                    :business_id, :category_id, 1, :product_code, :title,
                    :fabric, :color, :size, :occasion, :festival, :set_count, :set_label,
                    :price, :price_label, :stock_status, :stock_quantity, :short_description,
                    :internal_notes, :is_public, NOW(), NOW()
                )'
            );
            $stmt->execute([
                ':business_id' => $businessId,
                ':category_id' => $categoryId,
                ':product_code' => $productCode,
                ':title' => $title,
                ':fabric' => $fabric,
                ':color' => $color,
                ':size' => $size,
                ':occasion' => $occasion,
                ':festival' => $festival,
                ':set_count' => $setCount,
                ':set_label' => $setLabel,
                ':price' => $price,
                ':price_label' => $priceLabel,
                ':stock_status' => $stockStatus,
                ':stock_quantity' => $stockQuantity,
                ':short_description' => $description,
                ':internal_notes' => $internalNotes,
                ':is_public' => $isPublic,
            ]);
            $productId = (int)$pdo->lastInsertId();

            // Insert media assets for multi-image carousel
            if (is_array($images) && !empty($images)) {
                $mediaStmt = $pdo->prepare(
                    'INSERT INTO media_assets (business_id, product_id, uploaded_by_user_id, original_path, watermarked_path, thumbnail_path, is_cover, sort_order, created_at)
                     VALUES (:business_id, :product_id, 1, :url, :url, :url, :is_cover, :sort_order, NOW())'
                );
                foreach ($images as $idx => $imgUrl) {
                    $mediaStmt->execute([
                        ':business_id' => $businessId,
                        ':product_id' => $productId,
                        ':url' => $imgUrl,
                        ':is_cover' => $idx === 0 ? 1 : 0,
                        ':sort_order' => $idx,
                    ]);
                }
            }

            $pdo->commit();

            Response::success([
                'id' => $productId,
                'product_code' => $productCode,
                'title' => $title,
                'fabric' => $fabric,
                'price' => $price,
                'set_count' => $setCount,
                'festival' => $festival,
                'occasion' => $occasion,
                'stock_status' => $stockStatus,
            ], 'Product created successfully', 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function bulkUpload(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $items = $request->input('items');
        $prefix = $request->input('prefix', 'SR');
        $collectionId = $request->input('collection_id') ? (int)$request->input('collection_id') : null;
        $festival = $request->input('festival', 'Diwali Special');
        $occasion = $request->input('occasion', 'Festive');
        $setCount = (int)($request->input('set_count') ?? 4);

        if (!is_array($items) || empty($items)) {
            Response::error('Please provide an array of items with images to bulk upload.', 422);
        }

        $count = count($items);
        $codes = $this->codeService->generateBatchCodes($businessId, $count, $prefix);

        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            $createdProducts = [];
            $prodStmt = $pdo->prepare(
                'INSERT INTO products (
                    business_id, created_by_user_id, product_code, title, fabric, festival, occasion, set_count, price, price_label, stock_status, created_at, updated_at
                ) VALUES (
                    :business_id, 1, :product_code, :title, :fabric, :festival, :occasion, :set_count, :price, :price_label, "available", NOW(), NOW()
                )'
            );
            $mediaStmt = $pdo->prepare(
                'INSERT INTO media_assets (business_id, product_id, uploaded_by_user_id, original_path, watermarked_path, is_cover, sort_order, created_at)
                 VALUES (:business_id, :product_id, 1, :file_url, :file_url, 1, 0, NOW())'
            );
            $colProdStmt = $pdo->prepare(
                'INSERT INTO collection_products (business_id, collection_id, product_id, sort_order) VALUES (:business_id, :collection_id, :product_id, :sort_order)'
            );

            foreach ($items as $idx => $item) {
                $code = $codes[$idx];
                $title = !empty($item['title']) ? $item['title'] : "Design {$code}";
                $fabric = !empty($item['fabric']) ? $item['fabric'] : 'Dola Silk';
                $price = isset($item['price']) ? (float)$item['price'] : 950.0;
                $imageUrl = $item['image_url'] ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600';

                $prodStmt->execute([
                    ':business_id' => $businessId,
                    ':product_code' => $code,
                    ':title' => $title,
                    ':fabric' => $fabric,
                    ':festival' => $festival,
                    ':occasion' => $occasion,
                    ':set_count' => $setCount,
                    ':price' => $price,
                    ':price_label' => "₹" . number_format($price, 0) . " / Pc (Set of {$setCount})",
                ]);
                $productId = (int)$pdo->lastInsertId();

                $mediaStmt->execute([
                    ':business_id' => $businessId,
                    ':product_id' => $productId,
                    ':file_url' => $imageUrl,
                ]);

                if ($collectionId) {
                    $colProdStmt->execute([
                        ':business_id' => $businessId,
                        ':collection_id' => $collectionId,
                        ':product_id' => $productId,
                        ':sort_order' => $idx,
                    ]);
                }

                $createdProducts[] = [
                    'id' => $productId,
                    'product_code' => $code,
                    'title' => $title,
                    'fabric' => $fabric,
                    'price' => $price,
                    'set_count' => $setCount,
                    'image_url' => $imageUrl,
                ];
            }

            $pdo->commit();

            Response::success([
                'total_created' => $count,
                'products' => $createdProducts,
            ], "Successfully bulk-created {$count} designs with sequential product codes", 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function update(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $productId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare('SELECT id FROM products WHERE id = :id AND business_id = :business_id LIMIT 1');
        $stmt->execute([':id' => $productId, ':business_id' => $businessId]);
        if (!$stmt->fetch()) {
            Response::notFound('Product not found.');
        }

        $fields = ['title', 'fabric', 'color', 'size', 'occasion', 'festival', 'set_count', 'set_label', 'price', 'price_label', 'stock_status', 'short_description', 'internal_notes', 'category_id', 'is_public'];
        $updates = [];
        $bindings = [':id' => $productId, ':business_id' => $businessId];

        foreach ($fields as $field) {
            if ($request->input($field) !== null) {
                $updates[] = "{$field} = :{$field}";
                $bindings[":{$field}"] = $request->input($field);
            }
        }

        if (empty($updates)) {
            Response::error('No update parameters provided.', 400);
        }

        $updates[] = 'updated_at = NOW()';
        $sql = 'UPDATE products SET ' . implode(', ', $updates) . ' WHERE id = :id AND business_id = :business_id';
        $updateStmt = $this->db->pdo()->prepare($sql);
        $updateStmt->execute($bindings);

        Response::success(null, 'Product updated successfully');
    }

    public function delete(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $productId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare('DELETE FROM products WHERE id = :id AND business_id = :business_id');
        $stmt->execute([':id' => $productId, ':business_id' => $businessId]);

        Response::success(null, 'Product deleted successfully');
    }
}
