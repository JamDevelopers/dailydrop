<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Auth;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;

class AuthController
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function login(Request $request): void
    {
        $validator = Validator::make($request->all(), [
            'login' => 'required',
            'password' => 'required|min:6',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $login = trim((string)$request->input('login'));
        $password = (string)$request->input('password');

        $stmt = $this->db->pdo()->prepare(
            'SELECT u.*, b.business_name, b.slug AS business_slug, b.status AS business_status, b.plan_id
             FROM users u
             JOIN businesses b ON b.id = u.business_id
             WHERE (u.phone = :login_phone OR u.email = :login_email)
             LIMIT 1'
        );
        $stmt->execute([
            ':login_phone' => $login,
            ':login_email' => $login,
        ]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user || !Auth::verifyPassword($password, $user['password_hash'])) {
            Response::error('Invalid credentials. Please verify your phone/email and password.', 401);
        }

        if ((int)$user['is_active'] !== 1) {
            Response::forbidden('Your user account is currently deactivated.');
        }

        if ($user['business_status'] === 'suspended') {
            Response::forbidden('Your business account is currently suspended.');
        }

        // Generate token
        $token = Auth::createApiToken($this->db, (int)$user['id'], 'mobile_or_web_client');

        // Fetch settings
        $settingsStmt = $this->db->pdo()->prepare(
            'SELECT * FROM business_settings WHERE business_id = :business_id LIMIT 1'
        );
        $settingsStmt->execute([':business_id' => $user['business_id']]);
        $settings = $settingsStmt->fetch(PDO::FETCH_ASSOC) ?: [];

        Response::success([
            'token' => $token,
            'user' => [
                'id' => (int)$user['id'],
                'business_id' => (int)$user['business_id'],
                'name' => $user['name'],
                'phone' => $user['phone'],
                'email' => $user['email'],
                'role' => $user['role'],
                'avatar_url' => $user['avatar_url'],
            ],
            'business' => [
                'id' => (int)$user['business_id'],
                'name' => $user['business_name'],
                'slug' => $user['business_slug'],
                'plan_id' => (int)$user['plan_id'],
                'status' => $user['business_status'],
            ],
            'settings' => $settings,
        ], 'Login successful');
    }

    public function register(Request $request): void
    {
        $validator = Validator::make($request->all(), [
            'business_name' => 'required|min:3|max:150',
            'name' => 'required|min:2|max:100',
            'phone' => 'required|min:10|max:20',
            'password' => 'required|min:6',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $businessName = trim((string)$request->input('business_name'));
        $name = trim((string)$request->input('name'));
        $phone = trim((string)$request->input('phone'));
        $email = $request->input('email') ? trim((string)$request->input('email')) : null;
        $marketName = $request->input('market_name') ? trim((string)$request->input('market_name')) : 'Ring Road Market, Surat';
        $shopNumber = $request->input('shop_number') ? trim((string)$request->input('shop_number')) : null;
        $password = (string)$request->input('password');

        $pdo = $this->db->pdo();

        // Check if phone or email is already registered
        $checkStmt = $pdo->prepare('SELECT id FROM users WHERE phone = :phone OR (email IS NOT NULL AND email = :email) LIMIT 1');
        $checkStmt->execute([':phone' => $phone, ':email' => $email]);
        if ($checkStmt->fetch()) {
            Response::error('A user with this phone number or email already exists.', 409);
        }

        // Generate slug
        $baseSlug = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', $businessName));
        $baseSlug = trim($baseSlug, '-');
        $slug = $baseSlug;
        $counter = 1;
        while (true) {
            $slugStmt = $pdo->prepare('SELECT id FROM businesses WHERE slug = :slug LIMIT 1');
            $slugStmt->execute([':slug' => $slug]);
            if (!$slugStmt->fetch()) {
                break;
            }
            $slug = "{$baseSlug}-" . (++$counter);
        }

        $pdo->beginTransaction();
        try {
            // 1. Create Business
            $bStmt = $pdo->prepare(
                'INSERT INTO businesses (business_name, slug, market_name, shop_number, city, state, primary_phone, primary_email, plan_id, status, created_at, updated_at)
                 VALUES (:business_name, :slug, :market_name, :shop_number, "Surat", "Gujarat", :phone, :email, 1, "trial", NOW(), NOW())'
            );
            $bStmt->execute([
                ':business_name' => $businessName,
                ':slug' => $slug,
                ':market_name' => $marketName,
                ':shop_number' => $shopNumber,
                ':phone' => $phone,
                ':email' => $email,
            ]);
            $businessId = (int)$pdo->lastInsertId();

            // 2. Generate SKU Prefix
            $words = preg_split('/\s+/', $businessName);
            $skuPrefix = count($words) >= 2
                ? strtoupper(substr($words[0], 0, 1) . substr($words[1], 0, 1))
                : strtoupper(substr($businessName, 0, 2));

            // 3. Create Settings
            $sStmt = $pdo->prepare(
                'INSERT INTO business_settings (business_id, sku_prefix, show_prices_publicly, enable_watermark, watermark_text, whatsapp_phone, created_at, updated_at)
                 VALUES (:business_id, :sku_prefix, 1, 1, :watermark_text, :whatsapp_phone, NOW(), NOW())'
            );
            $sStmt->execute([
                ':business_id' => $businessId,
                ':sku_prefix' => $skuPrefix,
                ':watermark_text' => $businessName,
                ':whatsapp_phone' => $phone,
            ]);

            // 4. Create Owner User
            $passwordHash = Auth::hashPassword($password);
            $uStmt = $pdo->prepare(
                'INSERT INTO users (business_id, name, phone, email, password_hash, role, is_active, created_at, updated_at)
                 VALUES (:business_id, :name, :phone, :email, :password_hash, "owner", 1, NOW(), NOW())'
            );
            $uStmt->execute([
                ':business_id' => $businessId,
                ':name' => $name,
                ':phone' => $phone,
                ':email' => $email,
                ':password_hash' => $passwordHash,
            ]);
            $userId = (int)$pdo->lastInsertId();

            // 5. Create Token
            $token = Auth::createApiToken($this->db, $userId, 'registration_device');

            $pdo->commit();

            Response::success([
                'token' => $token,
                'user' => [
                    'id' => $userId,
                    'business_id' => $businessId,
                    'name' => $name,
                    'phone' => $phone,
                    'email' => $email,
                    'role' => 'owner',
                ],
                'business' => [
                    'id' => $businessId,
                    'name' => $businessName,
                    'slug' => $slug,
                    'market_name' => $marketName,
                    'plan_id' => 1,
                    'status' => 'trial',
                ],
            ], 'Business and owner account created successfully', 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function me(Request $request): void
    {
        $currentUser = $request->currentUser();
        $businessId = $request->businessId();

        if (!$currentUser || !$businessId) {
            Response::unauthorized();
        }

        $bStmt = $this->db->pdo()->prepare(
            'SELECT b.*, p.name AS plan_name, p.max_products, p.max_storage_mb
             FROM businesses b
             LEFT JOIN plans p ON p.id = b.plan_id
             WHERE b.id = :id LIMIT 1'
        );
        $bStmt->execute([':id' => $businessId]);
        $business = $bStmt->fetch(PDO::FETCH_ASSOC);

        $sStmt = $this->db->pdo()->prepare('SELECT * FROM business_settings WHERE business_id = :id LIMIT 1');
        $sStmt->execute([':id' => $businessId]);
        $settings = $sStmt->fetch(PDO::FETCH_ASSOC) ?: [];

        Response::success([
            'user' => $currentUser,
            'business' => $business,
            'settings' => $settings,
        ]);
    }

    public function logout(Request $request): void
    {
        $token = $request->bearerToken();
        if ($token) {
            Auth::revokeToken($this->db, $token);
        }
        Response::success(null, 'Logged out successfully');
    }
}

