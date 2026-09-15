<?php

declare(strict_types=1);

namespace TextileDrop\Core;

class Router
{
    private array $routes = [];
    private string $groupPrefix = '';
    private array $groupMiddleware = [];

    public function group(string $prefix, array $options, callable $callback): void
    {
        $prevPrefix = $this->groupPrefix;
        $prevMiddleware = $this->groupMiddleware;

        $this->groupPrefix = rtrim($prevPrefix . '/' . trim($prefix, '/'), '/');
        $this->groupMiddleware = array_merge($prevMiddleware, $options['middleware'] ?? []);

        $callback($this);

        $this->groupPrefix = $prevPrefix;
        $this->groupMiddleware = $prevMiddleware;
    }

    public function addRoute(string $method, string $path, $handler, array $middleware = []): void
    {
        $fullPath = rtrim($this->groupPrefix . '/' . trim($path, '/'), '/') ?: '/';
        $combinedMiddleware = array_merge($this->groupMiddleware, $middleware);

        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $fullPath,
            'handler' => $handler,
            'middleware' => $combinedMiddleware,
        ];
    }

    public function get(string $path, $handler, array $middleware = []): void
    {
        $this->addRoute('GET', $path, $handler, $middleware);
    }

    public function post(string $path, $handler, array $middleware = []): void
    {
        $this->addRoute('POST', $path, $handler, $middleware);
    }

    public function patch(string $path, $handler, array $middleware = []): void
    {
        $this->addRoute('PATCH', $path, $handler, $middleware);
    }

    public function delete(string $path, $handler, array $middleware = []): void
    {
        $this->addRoute('DELETE', $path, $handler, $middleware);
    }

    public function dispatch(Request $request, Database $db): void
    {
        $reqMethod = $request->method();
        $reqPath = $request->path();

        if ($reqMethod === 'OPTIONS') {
            http_response_code(200);
            exit;
        }

        foreach ($this->routes as $route) {
            if ($route['method'] !== $reqMethod) {
                continue;
            }

            $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[^/]+)', $route['path']);
            $pattern = '#^' . $pattern . '$#';

            if (preg_match($pattern, $reqPath, $matches)) {
                $params = [];
                foreach ($matches as $k => $v) {
                    if (is_string($k)) {
                        $params[$k] = $v;
                    }
                }

                // Execute Middleware
                foreach ($route['middleware'] as $mw) {
                    $mwClass = "\\TextileDrop\\Middleware\\" . ucfirst($mw) . "Middleware";
                    if (class_exists($mwClass)) {
                        $instance = new $mwClass();
                        $instance->handle($request, $db);
                    }
                }

                // Execute Handler
                $handler = $route['handler'];
                if (is_array($handler)) {
                    [$controllerClass, $action] = $handler;
                    $controller = new $controllerClass($db);
                    $controller->$action($request, $params);
                    return;
                } elseif (is_callable($handler)) {
                    $handler($request, $params);
                    return;
                }
            }
        }

        Response::notFound('API Route not found: ' . $reqMethod . ' ' . $reqPath);
    }
}

