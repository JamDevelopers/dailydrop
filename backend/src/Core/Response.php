<?php

declare(strict_types=1);

namespace TextileDrop\Core;

class Response
{
    public static function json(
        bool $success,
        string $message,
        $data = null,
        int $statusCode = 200,
        ?array $meta = null
    ): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');

        $payload = [
            'success' => $success,
            'message' => $message,
            'data' => $data,
        ];

        if ($meta !== null) {
            $payload['meta'] = $meta;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success($data = null, string $message = 'Success', int $statusCode = 200, ?array $meta = null): void
    {
        self::json(true, $message, $data, $statusCode, $meta);
    }

    public static function error(string $message = 'An error occurred', int $statusCode = 400, $data = null): void
    {
        self::json(false, $message, $data, $statusCode);
    }

    public static function unauthorized(string $message = 'Unauthorized access'): void
    {
        self::json(false, $message, null, 401);
    }

    public static function forbidden(string $message = 'Forbidden'): void
    {
        self::json(false, $message, null, 403);
    }

    public static function notFound(string $message = 'Resource not found'): void
    {
        self::json(false, $message, null, 404);
    }
}

