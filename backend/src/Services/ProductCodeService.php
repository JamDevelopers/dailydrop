<?php

declare(strict_types=1);

namespace TextileDrop\Services;

use PDO;
use TextileDrop\Core\Database;

class ProductCodeService
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function generateNextCode(int $businessId, ?string $customPrefix = null, ?string $date = null): string
    {
        $codes = $this->generateBatchCodes($businessId, 1, $customPrefix, $date);
        return $codes[0];
    }

    /**
     * @return string[]
     */
    public function generateBatchCodes(int $businessId, int $count, ?string $customPrefix = null, ?string $date = null): array
    {
        $prefix = $customPrefix ?: $this->getBusinessPrefix($businessId);
        $datePart = $date ? date('ymd', strtotime($date)) : date('ymd');

        // Pattern: PREFIX-YYMMDD-%
        $searchPattern = "{$prefix}-{$datePart}-%";

        $stmt = $this->db->pdo()->prepare(
            'SELECT product_code FROM products 
             WHERE business_id = :business_id AND product_code LIKE :pattern 
             ORDER BY product_code DESC LIMIT 1'
        );
        $stmt->execute([
            ':business_id' => $businessId,
            ':pattern' => $searchPattern,
        ]);
        $lastCode = $stmt->fetchColumn();

        $lastSeq = 0;
        if ($lastCode) {
            $parts = explode('-', (string)$lastCode);
            $lastPart = end($parts);
            if (is_numeric($lastPart)) {
                $lastSeq = (int)$lastPart;
            }
        }

        $generated = [];
        for ($i = 1; $i <= $count; $i++) {
            $seqNumber = str_pad((string)($lastSeq + $i), 3, '0', STR_PAD_LEFT);
            $generated[] = "{$prefix}-{$datePart}-{$seqNumber}";
        }

        return $generated;
    }

    public function getBusinessPrefix(int $businessId): string
    {
        $stmt = $this->db->pdo()->prepare(
            'SELECT s.sku_prefix, b.business_name 
             FROM businesses b 
             LEFT JOIN business_settings s ON s.business_id = b.id 
             WHERE b.id = :id LIMIT 1'
        );
        $stmt->execute([':id' => $businessId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row && !empty($row['sku_prefix'])) {
            return strtoupper(trim($row['sku_prefix']));
        }

        if ($row && !empty($row['business_name'])) {
            $words = preg_split('/\s+/', trim($row['business_name']));
            if (count($words) >= 2) {
                return strtoupper(substr($words[0], 0, 1) . substr($words[1], 0, 1));
            }
            return strtoupper(substr($row['business_name'], 0, 2));
        }

        return 'TX';
    }
}

