<?php

declare(strict_types=1);

namespace TextileDrop\Middleware;

use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;

class TenantMiddleware
{
    public function handle(Request $request, Database $db): void
    {
        $businessId = $request->businessId();
        if (!$businessId) {
            Response::forbidden('Tenant context not established.');
        }

        $business = $request->getContext('business');
        if ($business && ($business['status'] ?? '') === 'suspended') {
            Response::forbidden('This business account is currently suspended. Please contact support.');
        }
    }
}

