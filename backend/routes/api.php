<?php

declare(strict_types=1);

use TextileDrop\Controllers\AuthController;
use TextileDrop\Controllers\CollectionController;
use TextileDrop\Controllers\ContactController;
use TextileDrop\Controllers\DashboardController;
use TextileDrop\Controllers\InquiryController;
use TextileDrop\Controllers\ProductController;
use TextileDrop\Controllers\PublicCatalogController;
use TextileDrop\Core\Router;

/** @var Router $router */

// Health check
$router->get('/api/health', function ($req) {
    \TextileDrop\Core\Response::success(['status' => 'healthy', 'timestamp' => time()], 'TextileDrop Backend API Operational');
});

// Authentication Routes (Public)
$router->post('/api/v1/auth/login', [AuthController::class, 'login']);
$router->post('/api/v1/auth/register', [AuthController::class, 'register']);

// Public Catalog & Buyer Drops Routes
$router->get('/api/v1/public/catalog/{slug}', [PublicCatalogController::class, 'getBusinessBySlug']);
$router->get('/api/v1/public/catalog/{slug}/drop/{drop_slug}', [PublicCatalogController::class, 'getCollectionBySlug']);
$router->post('/api/v1/public/catalog/{slug}/inquire', [PublicCatalogController::class, 'submitInquiry']);
$router->post('/api/v1/public/catalog/{slug}/view', [PublicCatalogController::class, 'trackView']);

// Protected Wholesale Portal Routes (Multi-tenant)
$router->group('/api/v1', ['middleware' => ['auth', 'tenant']], function (Router $api) {
    // Current User & Session
    $api->get('/auth/me', [AuthController::class, 'me']);
    $api->post('/auth/logout', [AuthController::class, 'logout']);

    // Analytics & KPI Dashboard
    $api->get('/dashboard/kpis', [DashboardController::class, 'kpis']);

    // Product Inventory & Bulk Upload
    $api->get('/products', [ProductController::class, 'index']);
    $api->get('/products/generate-code', [ProductController::class, 'generateCode']);
    $api->post('/products', [ProductController::class, 'store']);
    $api->post('/products/bulk', [ProductController::class, 'bulkUpload']);
    $api->get('/products/{id}', [ProductController::class, 'show']);
    $api->patch('/products/{id}', [ProductController::class, 'update']);
    $api->delete('/products/{id}', [ProductController::class, 'delete']);

    // Daily Drop Collections
    $api->get('/collections', [CollectionController::class, 'index']);
    $api->post('/collections', [CollectionController::class, 'store']);
    $api->get('/collections/{id}', [CollectionController::class, 'show']);
    $api->get('/collections/{id}/share', [CollectionController::class, 'share']);
    $api->delete('/collections/{id}', [CollectionController::class, 'delete']);

    // CRM Inquiry Pipeline & Kanban
    $api->get('/inquiries', [InquiryController::class, 'index']);
    $api->get('/inquiries/kanban', [InquiryController::class, 'kanban']);
    $api->post('/inquiries', [InquiryController::class, 'store']);
    $api->get('/inquiries/{id}', [InquiryController::class, 'show']);
    $api->patch('/inquiries/{id}/status', [InquiryController::class, 'updateStatus']);
    $api->post('/inquiries/{id}/activities', [InquiryController::class, 'addActivity']);

    // Buyer Directory CRM
    $api->get('/contacts', [ContactController::class, 'index']);
    $api->post('/contacts', [ContactController::class, 'store']);
    $api->get('/contacts/export', [ContactController::class, 'exportCsv']);
    $api->get('/contacts/{id}', [ContactController::class, 'show']);
    $api->patch('/contacts/{id}', [ContactController::class, 'update']);
    $api->delete('/contacts/{id}', [ContactController::class, 'delete']);
});

