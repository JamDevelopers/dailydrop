<?php

declare(strict_types=1);

namespace TextileDrop\Middleware;

use TextileDrop\Core\Auth;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;

class AuthMiddleware
{
    public function handle(Request $request, Database $db): void
    {
        $token = $request->bearerToken();
        if (!$token) {
            Response::unauthorized('Authorization token is missing.');
        }

        $session = Auth::validateToken($db, $token);
        if (!$session) {
            Response::unauthorized('Invalid or expired authorization token.');
        }

        $request->setContext('token_id', $session['token_id']);
        $request->setContext('current_user', [
            'id' => (int)$session['user_id'],
            'business_id' => (int)$session['business_id'],
            'name' => $session['name'],
            'phone' => $session['phone'],
            'email' => $session['email'],
            'role' => $session['role'],
        ]);
        $request->setContext('business_id', (int)$session['business_id']);
        $request->setContext('business', [
            'id' => (int)$session['business_id'],
            'name' => $session['business_name'],
            'slug' => $session['business_slug'],
            'status' => $session['business_status'],
            'plan_id' => (int)$session['plan_id'],
        ]);
    }
}

