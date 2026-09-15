<?php

declare(strict_types=1);

namespace TextileDrop\Controllers;

use PDO;
use TextileDrop\Core\Database;
use TextileDrop\Core\Request;
use TextileDrop\Core\Response;
use TextileDrop\Core\Validator;

class ContactController
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function index(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $query = $request->query('query');
        $city = $request->query('city');

        $sql = 'SELECT c.* FROM contacts c WHERE c.business_id = :business_id';
        $params = [':business_id' => $businessId];

        if (!empty($query)) {
            $sql .= ' AND (c.name LIKE :q OR c.phone LIKE :q OR c.company_name LIKE :q OR c.city LIKE :q)';
            $params[':q'] = "%{$query}%";
        }

        if (!empty($city)) {
            $sql .= ' AND c.city = :city';
            $params[':city'] = $city;
        }

        $sql .= ' ORDER BY c.last_inquiry_at DESC, c.id DESC';

        $stmt = $this->db->pdo()->prepare($sql);
        $stmt->execute($params);
        $contacts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($contacts as &$contact) {
            $contact['id'] = (int)$contact['id'];
            $contact['total_inquiries'] = (int)$contact['total_inquiries'];
            $contact['tags'] = !empty($contact['tags']) ? json_decode($contact['tags'], true) : [];
        }

        Response::success($contacts);
    }

    public function show(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $contactId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare(
            'SELECT * FROM contacts WHERE id = :id AND business_id = :business_id LIMIT 1'
        );
        $stmt->execute([':id' => $contactId, ':business_id' => $businessId]);
        $contact = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$contact) {
            Response::notFound('Buyer contact not found.');
        }

        $contact['id'] = (int)$contact['id'];
        $contact['tags'] = !empty($contact['tags']) ? json_decode($contact['tags'], true) : [];

        // Fetch inquiry history
        $inqStmt = $this->db->pdo()->prepare(
            'SELECT i.*, p.title AS product_title, p.fabric_type, p.price
             FROM inquiries i
             LEFT JOIN products p ON p.id = i.product_id
             WHERE i.contact_id = :contact_id
             ORDER BY i.id DESC'
        );
        $inqStmt->execute([':contact_id' => $contactId]);
        $contact['inquiries'] = $inqStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success($contact);
    }

    public function store(Request $request): void
    {
        $businessId = (int)$request->businessId();
        $validator = Validator::make($request->all(), [
            'name' => 'required|min:2|max:100',
            'phone' => 'required|min:10|max:20',
        ]);

        if (!$validator->validate()) {
            Response::error($validator->firstError() ?? 'Validation failed', 422, $validator->errors());
        }

        $name = trim((string)$request->input('name'));
        $phone = trim((string)$request->input('phone'));
        $companyName = $request->input('company_name');
        $city = $request->input('city');
        $state = $request->input('state');
        $lang = $request->input('preferred_language', 'gu');
        $tags = $request->input('tags', []);

        // Check if phone already exists
        $stmt = $this->db->pdo()->prepare('SELECT id FROM contacts WHERE business_id = :bid AND phone = :phone LIMIT 1');
        $stmt->execute([':bid' => $businessId, ':phone' => $phone]);
        if ($stmt->fetch()) {
            Response::error('A contact with this phone number already exists.', 409);
        }

        $insertStmt = $this->db->pdo()->prepare(
            'INSERT INTO contacts (business_id, name, phone, company_name, city, state, preferred_language, tags, created_at, updated_at)
             VALUES (:bid, :name, :phone, :company_name, :city, :state, :lang, :tags, NOW(), NOW())'
        );
        $insertStmt->execute([
            ':bid' => $businessId,
            ':name' => $name,
            ':phone' => $phone,
            ':company_name' => $companyName,
            ':city' => $city,
            ':state' => $state,
            ':lang' => $lang,
            ':tags' => is_array($tags) ? json_encode($tags) : json_encode([]),
        ]);

        $id = (int)$this->db->pdo()->lastInsertId();

        Response::success([
            'id' => $id,
            'name' => $name,
            'phone' => $phone,
            'city' => $city,
            'company_name' => $companyName,
        ], 'Contact created successfully', 201);
    }

    public function update(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $contactId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare('SELECT id FROM contacts WHERE id = :id AND business_id = :bid LIMIT 1');
        $stmt->execute([':id' => $contactId, ':bid' => $businessId]);
        if (!$stmt->fetch()) {
            Response::notFound('Contact not found.');
        }

        $fields = ['name', 'company_name', 'city', 'state', 'preferred_language'];
        $updates = [];
        $bindings = [':id' => $contactId, ':bid' => $businessId];

        foreach ($fields as $field) {
            if ($request->input($field) !== null) {
                $updates[] = "{$field} = :{$field}";
                $bindings[":{$field}"] = $request->input($field);
            }
        }

        if ($request->input('tags') !== null) {
            $updates[] = 'tags = :tags';
            $bindings[':tags'] = json_encode($request->input('tags'));
        }

        if (empty($updates)) {
            Response::error('No update fields provided.', 400);
        }

        $updates[] = 'updated_at = NOW()';
        $sql = 'UPDATE contacts SET ' . implode(', ', $updates) . ' WHERE id = :id AND business_id = :bid';
        $upStmt = $this->db->pdo()->prepare($sql);
        $upStmt->execute($bindings);

        Response::success(null, 'Contact updated successfully');
    }

    public function delete(Request $request, array $params): void
    {
        $businessId = (int)$request->businessId();
        $contactId = (int)($params['id'] ?? 0);

        $stmt = $this->db->pdo()->prepare('DELETE FROM contacts WHERE id = :id AND business_id = :bid');
        $stmt->execute([':id' => $contactId, ':bid' => $businessId]);

        Response::success(null, 'Contact deleted successfully');
    }

    public function exportCsv(Request $request): void
    {
        $businessId = (int)$request->businessId();

        $stmt = $this->db->pdo()->prepare(
            'SELECT name, phone, company_name, city, state, preferred_language, total_inquiries, last_inquiry_at
             FROM contacts WHERE business_id = :bid ORDER BY name ASC'
        );
        $stmt->execute([':bid' => $businessId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename=textiledrop_contacts_' . date('Ymd_His') . '.csv');

        $output = fopen('php://output', 'w');
        fputcsv($output, ['Name', 'Phone', 'Company Name', 'City', 'State', 'Language', 'Total Inquiries', 'Last Inquiry At']);

        foreach ($rows as $r) {
            fputcsv($output, $r);
        }
        fclose($output);
        exit;
    }
}

