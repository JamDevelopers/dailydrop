<?php

declare(strict_types=1);

namespace TextileDrop\Services;

use PDO;
use TextileDrop\Core\Database;

class InquiryService
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function createInquiry(
        int $businessId,
        string $buyerName,
        string $buyerPhone,
        ?string $buyerCity,
        ?int $productId,
        ?int $collectionId,
        ?string $message,
        string $source = 'public_catalog',
        ?string $productCode = null,
        ?int $assignedUserId = null
    ): array {
        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            // 1. Find or create Contact
            $contactStmt = $pdo->prepare(
                'SELECT id FROM contacts WHERE business_id = :business_id AND phone = :phone LIMIT 1'
            );
            $contactStmt->execute([
                ':business_id' => $businessId,
                ':phone' => $buyerPhone,
            ]);
            $contactId = $contactStmt->fetchColumn();

            if (!$contactId) {
                $createContactStmt = $pdo->prepare(
                    'INSERT INTO contacts (business_id, name, phone, city, total_inquiries, last_inquiry_at, created_at, updated_at) 
                     VALUES (:business_id, :name, :phone, :city, 1, NOW(), NOW(), NOW())'
                );
                $createContactStmt->execute([
                    ':business_id' => $businessId,
                    ':name' => $buyerName,
                    ':phone' => $buyerPhone,
                    ':city' => $buyerCity,
                ]);
                $contactId = (int)$pdo->lastInsertId();
            } else {
                $updateContactStmt = $pdo->prepare(
                    'UPDATE contacts 
                     SET total_inquiries = total_inquiries + 1, 
                         last_inquiry_at = NOW(),
                         name = COALESCE(NULLIF(:name, ""), name),
                         city = COALESCE(NULLIF(:city, ""), city),
                         updated_at = NOW() 
                     WHERE id = :id'
                );
                $updateContactStmt->execute([
                    ':name' => $buyerName,
                    ':city' => $buyerCity,
                    ':id' => $contactId,
                ]);
            }

            // 2. Insert Inquiry
            $inquiryStmt = $pdo->prepare(
                'INSERT INTO inquiries (
                    business_id, contact_id, product_id, collection_id, assigned_user_id,
                    buyer_name, buyer_phone, buyer_city, product_code, source, status,
                    inquiry_type, notes, created_at, updated_at
                ) VALUES (
                    :business_id, :contact_id, :product_id, :collection_id, :assigned_user_id,
                    :buyer_name, :buyer_phone, :buyer_city, :product_code, :source, "new",
                    "price_request", :notes, NOW(), NOW()
                )'
            );
            $inquiryStmt->execute([
                ':business_id' => $businessId,
                ':contact_id' => $contactId,
                ':product_id' => $productId,
                ':collection_id' => $collectionId,
                ':assigned_user_id' => $assignedUserId,
                ':buyer_name' => $buyerName,
                ':buyer_phone' => $buyerPhone,
                ':buyer_city' => $buyerCity,
                ':product_code' => $productCode,
                ':source' => $source,
                ':notes' => $message,
            ]);
            $inquiryId = (int)$pdo->lastInsertId();

            // 3. Log Initial Activity
            $activityStmt = $pdo->prepare(
                'INSERT INTO inquiry_activities (inquiry_id, activity_type, note, metadata, created_at)
                 VALUES (:inquiry_id, "created", :note, :meta, NOW())'
            );
            $activityStmt->execute([
                ':inquiry_id' => $inquiryId,
                ':note' => "Inquiry received from {$buyerName} ({$buyerPhone}) via {$source}.",
                ':meta' => json_encode([
                    'product_code' => $productCode,
                    'city' => $buyerCity,
                    'source' => $source,
                ]),
            ]);

            $pdo->commit();

            return [
                'id' => $inquiryId,
                'business_id' => $businessId,
                'contact_id' => $contactId,
                'product_id' => $productId,
                'product_code' => $productCode,
                'buyer_name' => $buyerName,
                'buyer_phone' => $buyerPhone,
                'buyer_city' => $buyerCity,
                'status' => 'new',
                'source' => $source,
                'notes' => $message,
                'created_at' => date('Y-m-d H:i:s'),
            ];
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
}

