<?php

declare(strict_types=1);

namespace TextileDrop\Core;

use PDO;

class Auth
{
    public static function hashPassword(string $password): string
    {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    public static function verifyPassword(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }

    public static function generateToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }

    public static function createApiToken(Database $db, int $userId, string $name = 'mobile_app', int $daysValid = 30): string
    {
        $rawToken = self::generateToken();
        $tokenHash = self::hashToken($rawToken);
        $expiresAt = date('Y-m-d H:i:s', strtotime("+{$daysValid} days"));

        $stmt = $db->pdo()->prepare(
            'INSERT INTO api_tokens (user_id, token_hash, name, expires_at, created_at) VALUES (:user_id, :token_hash, :name, :expires_at, NOW())'
        );
        $stmt->execute([
            ':user_id' => $userId,
            ':token_hash' => $tokenHash,
            ':name' => $name,
            ':expires_at' => $expiresAt,
        ]);

        return $rawToken;
    }

    public static function validateToken(Database $db, string $token): ?array
    {
        $tokenHash = self::hashToken($token);

        $stmt = $db->pdo()->prepare(
            'SELECT t.id AS token_id, t.user_id, t.expires_at, t.revoked_at,
                    u.business_id, u.name, u.phone, u.email, u.role, u.is_active,
                    b.business_name, b.slug AS business_slug, b.status AS business_status, b.plan_id
             FROM api_tokens t
             JOIN users u ON u.id = t.user_id
             JOIN businesses b ON b.id = u.business_id
             WHERE t.token_hash = :token_hash AND t.revoked_at IS NULL
             LIMIT 1'
        );
        $stmt->execute([':token_hash' => $tokenHash]);
        $record = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$record) {
            return null;
        }

        if ($record['expires_at'] !== null && strtotime($record['expires_at']) < time()) {
            return null;
        }

        if ((int)$record['is_active'] !== 1) {
            return null;
        }

        // Update last_used_at
        $updateStmt = $db->pdo()->prepare('UPDATE api_tokens SET last_used_at = NOW() WHERE id = :id');
        $updateStmt->execute([':id' => $record['token_id']]);

        return $record;
    }

    public static function revokeToken(Database $db, string $token): bool
    {
        $tokenHash = self::hashToken($token);
        $stmt = $db->pdo()->prepare('UPDATE api_tokens SET revoked_at = NOW() WHERE token_hash = :token_hash');
        return $stmt->execute([':token_hash' => $tokenHash]);
    }
}

