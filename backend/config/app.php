<?php

return [
    'name' => $_ENV['APP_NAME'] ?? 'TextileDrop API',
    'env' => $_ENV['APP_ENV'] ?? 'production',
    'debug' => filter_var($_ENV['APP_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN),
    'url' => $_ENV['APP_URL'] ?? 'http://localhost',
    'catalog_public_url' => $_ENV['CATALOG_PUBLIC_URL'] ?? 'http://localhost/catalog',
];

