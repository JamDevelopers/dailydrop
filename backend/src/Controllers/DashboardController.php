<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;

class DashboardController
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function kpis(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $pdo = $this->db->pdo();

        // Total active products
        $pStmt = $pdo->prepare('SELECT COUNT(*) FROM products WHERE business_id = :bid AND stock_status != "discontinued"');
        $pStmt->execute([':bid' => $businessId]);
        $totalProducts = (int)$pStmt->fetchColumn();

        // Total collections
        $cStmt = $pdo->prepare('SELECT COUNT(*) FROM collections WHERE business_id = :bid');
        $cStmt->execute([':bid' => $businessId]);
        $totalCollections = (int)$cStmt->fetchColumn();

        // Total inquiries & converted count
        $iStmt = $pdo->prepare(
            'SELECT 
                COUNT(*) AS total_inquiries,
                SUM(CASE WHEN status = "converted" THEN 1 ELSE 0 END) AS converted_inquiries,
                SUM(CASE WHEN status = "new" THEN 1 ELSE 0 END) AS new_inquiries,
                SUM(CASE WHEN next_follow_up_at IS NOT NULL AND next_follow_up_at <= NOW() AND status NOT IN ("converted", "closed_lost") THEN 1 ELSE 0 END) AS pending_followups
             FROM inquiries WHERE business_id = :bid'
        );
        $iStmt->execute([':bid' => $businessId]);
        $inqMetrics = $iStmt->fetch(PDO::FETCH_ASSOC);

        $totalInquiries = (int)($inqMetrics['total_inquiries'] ?? 0);
        $convertedInquiries = (int)($inqMetrics['converted_inquiries'] ?? 0);
        $newInquiries = (int)($inqMetrics['new_inquiries'] ?? 0);
        $pendingFollowups = (int)($inqMetrics['pending_followups'] ?? 0);

        $conversionRate = $totalInquiries > 0 ? round(($convertedInquiries / $totalInquiries) * 100, 1) : 0.0;

        // Stage breakdown
        $stageStmt = $pdo->prepare('SELECT status, COUNT(*) AS cnt FROM inquiries WHERE business_id = :bid GROUP BY status');
        $stageStmt->execute([':bid' => $businessId]);
        $stageRows = $stageStmt->fetchAll(PDO::FETCH_ASSOC);
        $funnel = [];
        foreach ($stageRows as $r) {
            $funnel[$r['status']] = (int)$r['cnt'];
        }

        // Top designs by inquiry count
        $topStmt = $pdo->prepare(
            'SELECT p.id, p.product_code, p.title, p.fabric_type, p.price, COUNT(i.id) AS inquiry_count,
                    (SELECT file_url FROM media_assets WHERE product_id = p.id AND is_cover = 1 LIMIT 1) AS cover_image
             FROM products p
             JOIN inquiries i ON i.product_id = p.id
             WHERE p.business_id = :bid
             GROUP BY p.id, p.product_code, p.title, p.fabric_type, p.price
             ORDER BY inquiry_count DESC LIMIT 5'
        );
        $topStmt->execute([':bid' => $businessId]);
        $topDesigns = $topStmt->fetchAll(PDO::FETCH_ASSOC);

        // Recent inquiries
        $recentStmt = $pdo->prepare(
            'SELECT i.*, p.title AS product_title, p.fabric_type,
                    (SELECT file_url FROM media_assets WHERE product_id = i.product_id AND is_cover = 1 LIMIT 1) AS product_image
             FROM inquiries i
             LEFT JOIN products p ON p.id = i.product_id
             WHERE i.business_id = :bid
             ORDER BY i.id DESC LIMIT 5'
        );
        $recentStmt->execute([':bid' => $businessId]);
        $recentInquiries = $recentStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success([
            'kpis' => [
                'total_products' => $totalProducts,
                'total_collections' => $totalCollections,
                'total_inquiries' => $totalInquiries,
                'new_inquiries' => $newInquiries,
                'converted_inquiries' => $convertedInquiries,
                'conversion_rate_percentage' => $conversionRate,
                'pending_followups' => $pendingFollowups,
            ],
            'funnel' => $funnel,
            'top_designs' => $topDesigns,
            'recent_inquiries' => $recentInquiries,
        ]);
    }
}

