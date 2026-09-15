<?php

declare(strict_types=1);

namespace TextileDrop\Core;

class Request
{
    private string $method;
    private string $path;
    private array $headers;
    private array $queryParams;
    private array $body;
    private array $context = [];

    public function __construct()
    {
        $this->method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $rawPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
        $this->path = rtrim($rawPath, '/') ?: '/';
        $this->headers = getallheaders() ?: [];
        $this->queryParams = $_GET;

        $rawBody = file_get_contents('php://input');
        $jsonBody = json_decode($rawBody, true);
        $this->body = is_array($jsonBody) ? $jsonBody : $_POST;
    }

    public function method(): string
    {
        return $this->method;
    }

    public function path(): string
    {
        return $this->path;
    }

    public function headers(): array
    {
        return $this->headers;
    }

    public function header(string $key, ?string $default = null): ?string
    {
        $normalized = strtolower($key);
        foreach ($this->headers as $k => $v) {
            if (strtolower($k) === $normalized) {
                return (string)$v;
            }
        }
        return $default;
    }

    public function bearerToken(): ?string
    {
        $auth = $this->header('Authorization');
        if ($auth && preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            return $matches[1];
        }
        return null;
    }

    public function query(string $key, $default = null)
    {
        return $this->queryParams[$key] ?? $default;
    }

    public function input(string $key, $default = null)
    {
        return $this->body[$key] ?? $default;
    }

    public function all(): array
    {
        return $this->body;
    }

    public function setContext(string $key, $value): void
    {
        $this->context[$key] = $value;
    }

    public function getContext(string $key, $default = null)
    {
        return $this->context[$key] ?? $default;
    }

    public function businessId(): ?int
    {
        return $this->getContext('business_id');
    }

    public function currentUser(): ?array
    {
        return $this->getContext('current_user');
    }
}

