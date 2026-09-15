# Textile Wholesale SaaS Standards & Conventions

## 1. Product Attributes & Multi-Image Sets
- Always support complete Surat textile specifications:
  - Fabric (Dola Silk, Georgette, Organza, Banarasi Jacquard, Rayon 14kg, Cotton, Velvet, etc.)
  - Set count & label (e.g. "Set of 4 Colors", "Set of 6", "Set of 8", "Single Piece", "Catalog Set")
  - Festivals (Diwali Special, Navratri & Garba, Eid Collection, Raksha Bandhan, Karwa Chauth, Wedding Season)
  - Occasions (Festive, Party Wear, Wedding / Bridal, Daily Wear, Reception, Mehendi & Sangeet)
  - Sizes (Free Size, Unstitched, Semi-Stitched, S to 3XL, Set of All Sizes)
- When a product is a Set or has multiple image variants, render an interactive horizontal swipeable image carousel with pagination indicators on both the catalog cards and detail modals.

## 2. Daily Drops & Limited-Time Links
- Daily drop collections must support expiration (`expires_at`):
  - Options: 24h, 48h, 7d, or Custom Date.
  - Expired links must show an explicit ended notice and redirect buyers to current active drops.
  - Active time-limited drops must display a countdown badge.

## 3. Public vs Private Visibility
- Collections and products must support visibility scopes:
  - `public`: Shown on main business catalog index.
  - `private_link_only`: Hidden from main catalog; accessible only via direct share link / token.

## 4. Public Catalog Layout Hierarchy
- In buyer-facing views, place the **Today's Daily Drop Carousel** above the search and filter bar for maximum buyer engagement.
- Provide 1-tap quick filters for "🔥 Today's Drop", Fabrics, Festivals, and Occasions.
