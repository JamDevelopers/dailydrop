<?php

declare(strict_types=1);

namespace TextileDrop\Core;

use Throwable;

class App
{
    private string $basePath;
    private array $config = [];
    private Database $db;
    private Router $router;

    public function __construct(string $basePath)
    {
        $this->basePath = rtrim($basePath, '/\\');
        $this->loadEnvironment();
        $this->loadConfig();
        $this->initDatabase();
        $this->router = new Router();
    }

    private function loadEnvironment(): void
    {
        $envFile = $this->basePath . '/.env';
        if (file_exists($envFile)) {
            $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || str_starts_with($line, '#')) {
                    continue;
                }
                if (str_contains($line, '=')) {
                    [$key, $value] = explode('=', $line, 2);
                    $key = trim($key);
                    $value = trim($value);
                    $value = trim($value, '"\'');
                    $_ENV[$key] = $value;
                    putenv("{$key}={$value}");
                }
            }
        }
    }

    private function loadConfig(): void
    {
        $this->config['app'] = require $this->basePath . '/config/app.php';
        $this->config['database'] = require $this->basePath . '/config/database.php';
        $this->config['cors'] = require $this->basePath . '/config/cors.php';
    }

    private function initDatabase(): void
    {
        $this->db = new Database($this->config['database']);
    }

    public function router(): Router
    {
        return $this->router;
    }

    public function database(): Database
    {
        return $this->db;
    }

    public function run(): void
    {
        try {
            $this->applyCors();

            $routesFile = $this->basePath . '/routes/api.php';
            if (file_exists($routesFile)) {
                $router = $this->router;
                require $routesFile;
            }

            $request = new Request();
            $this->router->dispatch($request, $this->db);
        } catch (Throwable $e) {
            $isDebug = $this->config['app']['debug'] ?? false;
            $statusCode = 500;

            Response::json(false, $isDebug ? $e->getMessage() : 'Internal Server Error', [
                'error' => $isDebug ? [
                    'message' => $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString(),
                ] : null,
            ], $statusCode);
        }
    }

    private function applyCors(): void
    {
        $cors = $this->config['cors'] ?? [];
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
        $allowedOrigins = $cors['allowed_origins'] ?? ['*'];

        if (in_array('*', $allowedOrigins, true) || in_array($origin, $allowedOrigins, true)) {
            header("Access-Control-Allow-Origin: {$origin}");
        }

        header('Access-Control-Allow-Methods: ' . implode(', ', $cors['allowed_methods'] ?? ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']));
        header('Access-Control-Allow-Headers: ' . implode(', ', $cors['allowed_headers'] ?? ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept']));
        header('Access-Control-Max-Age: ' . ($cors['max_age'] ?? 86400));
        header('Access-Control-Allow-Credentials: true');
    }
}

