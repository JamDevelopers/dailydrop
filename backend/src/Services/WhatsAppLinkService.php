<?php

declare(strict_types=1);

namespace TextileDrop\Services;

class WhatsAppLinkService
{
    public static function cleanPhoneNumber(string $phone, string $defaultCountryCode = '91'): string
    {
        $cleaned = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($cleaned) === 10) {
            $cleaned = $defaultCountryCode . $cleaned;
        }
        return $cleaned;
    }

    public static function buildLink(string $phone, string $message): string
    {
        $cleanPhone = self::cleanPhoneNumber($phone);
        $encodedText = rawurlencode($message);
        return "https://wa.me/{$cleanPhone}?text={$encodedText}";
    }

    public static function generateInquiryLink(
        string $sellerPhone,
        string $businessName,
        string $productCode,
        ?string $fabricName = null,
        ?float $price = null,
        ?string $buyerName = null
    ): string {
        $msg = "Namaste {$businessName},\n";
        if ($buyerName) {
            $msg .= "I am {$buyerName}.\n";
        }
        $msg .= "I am inquiring about Design *{$productCode}*";
        if ($fabricName) {
            $msg .= " ({$fabricName})";
        }
        if ($price && $price > 0) {
            $msg .= " priced at ₹" . number_format($price, 2) . "/meter";
        }
        $msg .= ".\n\nPlease share wholesale minimum order quantity (MOQ), color card, and stock availability.";

        return self::buildLink($sellerPhone, $msg);
    }

    public static function generateCollectionShareText(
        string $businessName,
        string $collectionTitle,
        int $itemCount,
        string $catalogUrl,
        ?string $marketName = null
    ): string {
        $header = "✨ *NEW COLLECTION DROP* ✨\n*{$businessName}*";
        if ($marketName) {
            $header .= " ({$marketName})";
        }
        $msg = "{$header}\n\n";
        $msg .= "📁 *{$collectionTitle}*\n";
        $msg .= "👗 Total Designs: {$itemCount} Exclusive Patterns\n\n";
        $msg .= "👉 View Live Wholesale Catalog & Place Inquiry:\n{$catalogUrl}\n\n";
        $msg .= "⚡ Limited Stock Ready for Dispatch. Reply to book your order!";

        return $msg;
    }
}

