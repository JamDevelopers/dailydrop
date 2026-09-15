<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;
use TextileDrop\Services\InquiryService;
use TextileDrop\Services\WhatsAppLinkService;

class InquiryController
{
    private Database $db;
    private InquiryService $inquiryService;

    public function __construct(Database $db)
    {
        $this->db = $db;
        $this->inquiryService = new InquiryService($db);
    }

    public function index(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $status = $request->query('status');
        $query = $request->query('query');

        $sql = 'SELECT i.*, p.title AS product_title, p.fabric_type, p.price,
                       (SELECT file_url FROM media_assets WHERE product_id = i.product_id AND is_cover = 1 LIMIT 1) AS product_image,
                       c.name AS contact_name, c.city AS contact_city, c.tags AS contact_tags
                FROM inquiries i
                LEFT JOIN products p ON p.id = i.product_id
                LEFT JOIN contacts c ON c.id = i.contact_id
                WHERE i.business_id = :business_id';

        $params = [':business_id' => $businessId];

        if (!empty($status)) {
            $sql .= ' AND i.status = :status';
            $params[':status'] = $status;
        }

        if (!empty($query)) {
            $sql .= ' AND (i.buyer_name LIKE :q OR i.buyer_phone LIKE :q OR i.product_code LIKE :q OR i.buyer_city LIKE :q)';
            $params[':q'] = "%{$query}%";
        }

        $sql .= ' ORDER BY i.id DESC';

        $stmt = $this->db->pdo()->prepare($sql);
        $stmt->execute($params);
        $inquiries = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($inquiries as &$inq) {
            $inq['id'] = (int)$inq['id'];
            $inq['business_id'] = (int)$inq['business_id'];
            $inq['product_id'] = $inq['product_id'] !== null ? (int)$inq['product_id'] : null;
            $inq['price'] = $inq['price'] !== null ? (float)$inq['price'] : null;
            $inq['contact_tags'] = !empty($inq['contact_tags']) ? json_decode($inq['contact_tags'], true) : [];
        }

        Response::success($inquiries);
    }

    public function kanban(Request $request): void
    {
        $businessId = (int)$request->businessId();

        $stmt = $this->db->pdo()->prepare(
            'SELECT i.*, p.title AS product_title, p.fabric_type, p.price,
                    (SELECT file_url FROM media_assets WHERE product_id = i.product_id AND is_cover = 1 LIMIT 1) AS product_image
             FROM inquiries i
             LEFT JOIN products p ON p.id = i.product_id
             WHERE i.business_id = :business_id
             ORDER BY i.updated_at DESC'
        );
        $stmt->execute([':business_id' => $businessId]);
        $all = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $stages = [
            'new' => [],
            'contacted' => [],
            'sample_sent' => [],
            'negotiating' => [],
            'converted' => [],
            'closed_lost' => [],
        ];

        foreach ($all as $item) {
            $item['id'] = (int)$item['id'];
            $item['price'] = $item['price'] !== null ? (float)$item['price'] : null;
            $status = $item['status'] ?? 'new';
            if (isset($stages[$status])) {
                $stages[$status][] = $item;
            } else {
                $stages['new'][] = $item;
            }
        }

        Response::success($stages);
    }

    public function show(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $inquiryId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare(
            'SELECT i.*, p.title AS product_title, p.fabric_type, p.price, p.moq,
                    (SELECT file_url FROM media_assets WHERE product_id = i.product_id AND is_cover = 1 LIMIT 1) AS product_image,
                    c.name AS contact_name, c.phone AS contact_phone, c.city AS contact_city, c.state AS contact_state, c.total_inquiries
             FROM inquiries i
             LEFT JOIN products p ON p.id = i.product_id
             LEFT JOIN contacts c ON c.id = i.contact_id
             WHERE i.id = :id AND i.business_id = :business_id LIMIT 1'
        );
        $stmt->execute([':id' => $inquiryId, ':business_id' => $businessId]);
        $inquiry = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$inquiry) {
            Response::notFound('Inquiry not found.');
        }

        $inquiry['id'] = (int)$inquiry['id'];
        $inquiry['price'] = $inquiry['price'] !== null ? (float)$inquiry['price'] : null;

        // Fetch activity timeline
        $actStmt = $this->db->pdo()->prepare(
            'SELECT a.*, u.name AS user_name 
             FROM inquiry_activities a
             LEFT JOIN users u ON u.id = a.user_id
             WHERE a.inquiry_id = :inquiry_id
             ORDER BY a.id ASC'
        );
        $actStmt->execute([':inquiry_id' => $inquiryId]);
        $inquiry['activities'] = $actStmt->fetchAll(PDO::FETCH_ASSOC);

        // WhatsApp direct follow up link
        $inquiry['whatsapp_direct_link'] = WhatsAppLinkService::buildLink(
            $inquiry['buyer_phone'],
            "Namaste {$inquiry['buyer_name']}, regarding your inquiry for Design {$inquiry['product_code']}..."
        );

        Response::success($inquiry);
    }

    public function store(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $validator = Validator::make($request->all(), [
            'buyer_name' => 'required|min:2|max:100',
            'buyer_phone' => 'required|min:10|max:20',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $result = $this->inquiryService->createInquiry(
            $businessId,
            trim((string)$request->input('buyer_name')),
            trim((string)$request->input('buyer_phone')),
            $request->input('buyer_city'),
            $request->input('product_id') ? (int)$request->input('product_id') : null,
            $request->input('collection_id') ? (int)$request->input('collection_id') : null,
            $request->input('notes'),
            $request->input('source', 'manual_entry'),
            $request->input('product_code')
        );

        Response::success($result, 'Inquiry created successfully', 201);
    }

    public function updateStatus(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $inquiryId = (int)($params['id'] ?? 0);
        $currentUser = $request->currentUser();

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:new,contacted,sample_sent,negotiating,converted,closed_lost',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $newStatus = (string)$request->input('status');
        $note = $request->input('note');

        $stmt = $this->db->pdo()->prepare('SELECT status FROM inquiries WHERE id = :id AND business_id = :business_id LIMIT 1');
        $stmt->execute([':id' => $inquiryId, ':business_id' => $businessId]);
        $oldStatus = $stmt->fetchColumn();

        if ($oldStatus === false) {
            Response::notFound('Inquiry not found.');
        }

        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            $upStmt = $pdo->prepare('UPDATE inquiries SET status = :status, updated_at = NOW() WHERE id = :id');
            $upStmt->execute([':status' => $newStatus, ':id' => $inquiryId]);

            // Add activity entry
            $activityNote = $note ?: "Status updated from '{$oldStatus}' to '{$newStatus}'.";
            $actStmt = $pdo->prepare(
                'INSERT INTO inquiry_activities (inquiry_id, user_id, activity_type, note, metadata, created_at)
                 VALUES (:inquiry_id, :user_id, "status_change", :note, :meta, NOW())'
            );
            $actStmt->execute([
                ':inquiry_id' => $inquiryId,
                ':user_id' => $currentUser['id'] ?? null,
                ':note' => $activityNote,
                ':meta' => json_encode(['old_status' => $oldStatus, 'new_status' => $newStatus]),
            ]);

            $pdo->commit();

            Response::success(['id' => $inquiryId, 'status' => $newStatus], 'Status updated successfully');
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function addActivity(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $inquiryId = (int)($params['id'] ?? 0);
        $currentUser = $request->currentUser();

        $validator = Validator::make($request->all(), [
            'activity_type' => 'required|in:call,whatsapp,note,sample_sent,deal_won,deal_lost',
            'note' => 'required|min:2',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $activityType = (string)$request->input('activity_type');
        $note = trim((string)$request->input('note'));
        $nextFollowUpAt = $request->input('next_follow_up_at');

        $pdo = $this->db->pdo();
        $pdo->beginTransaction();

        try {
            $actStmt = $pdo->prepare(
                'INSERT INTO inquiry_activities (inquiry_id, user_id, activity_type, note, next_follow_up_at, created_at)
                 VALUES (:inquiry_id, :user_id, :activity_type, :note, :next_follow_up_at, NOW())'
            );
            $actStmt->execute([
                ':inquiry_id' => $inquiryId,
                ':user_id' => $currentUser['id'] ?? null,
                ':activity_type' => $activityType,
                ':note' => $note,
                ':next_follow_up_at' => $nextFollowUpAt,
            ]);
            $actId = (int)$pdo->lastInsertId();

            if ($nextFollowUpAt) {
                $upInq = $pdo->prepare('UPDATE inquiries SET next_follow_up_at = :nfu, updated_at = NOW() WHERE id = :id');
                $upInq->execute([':nfu' => $nextFollowUpAt, ':id' => $inquiryId]);
            }

            $pdo->commit();

            Response::success(['id' => $actId, 'activity_type' => $activityType, 'note' => $note], 'Activity logged successfully', 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
}

