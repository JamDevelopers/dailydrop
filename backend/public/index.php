<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

if (file_exists(__DIR__ . '/../vendor/autoload.php')) {
    require_once __DIR__ . '/../vendor/autoload.php';
}

// Fallback PSR-4 Autoloader when Composer vendor is not present
spl_autoload_register(function (string $class): void {
    $prefix = 'TextileDrop\\';
    $baseDir = __DIR__ . '/../src/';
    $len = strlen($prefix);

    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relativeClass = substr($class, $len);
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';

    if (file_exists($file)) {
        require_once $file;
    }
});

use TextileDrop\Core\App;

$app = new App(__DIR__ . '/..');
$app->run();

