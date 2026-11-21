# Catalog roadmap: 45 designs to about 200 (2026-11-20)

Ledger for the `catalog` branch. Each row's status moves planned, built, verified, photographed; or dropped
with the reason. "Verified" means every check below passed and the design is committed; "photographed" also
needs its photo accepted twice (my read, then a Sonnet judge that has not seen my verdict).

## Where the ranking comes from

- Ravelry top 100 (Aug 2026): neckwear 27, hats 26, socks 25, sweaters 16 (`project-docs/research/2026-11-popular-designs.md`).
- Etsy bestsellers read 2026-11-17: beginner sweaters, hoods, triangle scarves, slippers, booties, simple beanies, baby cardigans and textured blankets (same file).
- Craft-fair sellers: beanies, cowls, ear warmers and dishcloth sets outsell big pieces (same file).
- Knitter research 2026-11-20 (`project-docs/audit/raw/2026-11-20-fable/research-knitters.md`): gift knitters pay for children's sizes in Nov and Dec; accessories are free everywhere, so they fill the catalog but sell nothing alone.
- A web look on 2026-11-20 found no newer category counts than these.

Gaps in the 45 the list fills first: toe-up and ankle socks, mitts with a thumb gusset, baby cardigan and
sweater, baby hats and mittens, a top-down hat, headbands, shawl shapes beyond the triangle and crescent,
ponchos and capelets, home items (washcloths, coasters, cozies, bags), holiday pieces, and the classic
stitch patterns (double moss, broken rib, waffle, honeycomb, linen, rope cable, feather and fan, chevron and
eyelet lace, seeded rib) across scarves, cowls, hats, blankets and cloths.

## How each gets built

- **New shape**: a `Design` case and an engine in `Shared/Patterns`, so it needs a build.
- **Stitch**: a stitch pattern from `Shared/Patterns/Stitches.swift` worked over an existing shape's main
  fabric, as a record (`"stitch"`, record format 2). The stitch is engine code; which shape wears it is data.
- **Colorwork**: a chart or stripes on a shape in `Topical.bases`, as a record (format 1).

A recolor of an existing design is never added. Seed stitch already has a scarf and a cowl, so the moss
family here is double moss (2 by 2), which reads as a small check, not as seed.

## Checks every design passes

`PatternTests` and `TopicalTests` (every size, both ends of every measurement, every allowed weight);
`scripts/topical-check.sh` for records; `scripts/catalog/golden.sh --check` (the 2,229 plans of the 45
existing designs, hashed at commit 598a5fb, must not change); a read of the printed pattern at the smallest
and largest size; the title in every listing language; `LibrarySearch` finding it under the words a knitter
types.

Fisherman's rib was left out of the stitch set: it is worked into the row below, which the fabric check
cannot prove, so the four rows planned for it became seeded rib (2026-11-20).

## Photos

Prompts are queued in `project-docs/sample-photos/subjects.json` and `shots.json`. No image is generated
until Jack says yes to the image tool. New photos are served from the site (`docs/photos/<id>.jpg`) and
cached on the phone, so the app does not carry them.

## The list

| # | Design | Category | For | Build | Status |
|---|---|---|---|---|---|
| 1 | Toe-Up Socks | Socks & Feet | Adults and children, intermediate | New shape | verified |
| 2 | Fingerless Mitts with Gusset | Hands | Adults, easy | New shape | verified |
| 3 | Double Moss Scarf | Scarves & Cowls | Anyone, beginner | Stitch: double moss on scarf | verified |
| 4 | Baby Cardigan | Baby | Babies 0 to 24 months, easy | New shape: cardigan engine at baby sizes | verified |
| 5 | Top-Down Beanie | Hats | Adults and children, easy | New shape | verified |
| 6 | Twisted Headband | Accessories | Adults, easy | New shape | verified |
| 7 | Poncho | Shawls & Wraps | Adults and children, beginner | New shape: two rectangles | verified |
| 8 | Christmas Stocking | Holiday | Gift, easy | New shape: sock engine at stocking scale | verified |
| 9 | Bordered Washcloth | Home | Anyone, beginner | New shape: square cloth knit straight, garter frame, stockinette middle; base for stitch cloths (renamed: all-garter would be the Dishcloth again) | verified |
| 10 | Waffle Beanie | Hats | Adults and children, easy | Stitch: waffle on ribbed beanie | verified |
| 11 | Ankle Socks | Socks & Feet | Adults, intermediate | New shape | dropped: both sock designs already knit a leg as short as 2 in, so this would be a size, not a design |
| 12 | Snowflake Beanie | Hats | Winter gift, intermediate | Colorwork: chart on ribbed beanie | verified: fingering, sport and DK (the 8-stitch repeat moves a 13 in worsted hat 8 percent) |
| 13 | Baby Knot Hat | Baby | Newborn to toddler, easy | New shape | verified (on the Hats shelf) |
| 14 | Asymmetric Shawl | Shawls & Wraps | Adults, easy | New shape | verified |
| 15 | Broken Rib Cowl | Scarves & Cowls | Anyone, beginner | Stitch: broken rib on cowl | verified |
| 16 | Bandana Cowl | Scarves & Cowls | Adults, easy | New shape | verified |
| 17 | Feather and Fan Scarf | Scarves & Cowls | Adults, easy lace | Stitch: feather and fan on scarf | verified |
| 18 | Double Moss Blanket | Blankets | Baby to throw, beginner | Stitch: double moss on bordered blanket | verified |
| 19 | Basketweave Washcloth | Home | Anyone, beginner | Stitch: basketweave on washcloth | verified |
| 20 | Arm Warmers | Hands | Adults, easy | New shape | verified |
| 21 | Baby Sweater | Baby | Babies 0 to 24 months, easy | New shape: raglan at baby sizes | dropped: the Kids' Raglan already fits an 18 in chest; a true baby pullover needs a buttoned shoulder for the head (added as a later row) |
| 22 | Fir Tree Beanie | Holiday | Gift, intermediate | Colorwork | dropped: the site already publishes a Fir Tree Hat each season (fir-tree-hat) |
| 23 | Honeycomb Cowl | Scarves & Cowls | Adults, easy | Stitch: slip-stitch honeycomb on cowl | verified |
| 24 | Watch Cap | Hats | Adults, easy | New shape: deep fold-up rib | verified |
| 25 | Chevron Lace Blanket | Blankets | Baby to throw, easy lace | Stitch: chevron lace on bordered blanket | verified |
| 26 | Hooded Scarf | Scarves & Cowls | Adults, easy | New shape | verified |
| 27 | Striped Scarf | Scarves & Cowls | Anyone, beginner | Colorwork: wide stripes on garter scarf | verified |
| 28 | Coasters | Home | Gift, easy | New shape: round, center out | verified |
| 29 | Rope Cable Scarf | Scarves & Cowls | Adults, intermediate | Stitch: rope cable on scarf | verified |
| 30 | Baby Mittens | Baby | Babies, easy | New shape: thumbless | verified |
| 31 | Cat Ear Hat | Hats | Children and adults, easy | New shape: tube closed flat at the top with a three-needle bind off | verified |
| 32 | Seeded Rib Beanie | Hats | Adults, easy | Stitch: seeded rib on ribbed beanie | verified |
| 33 | Eyelet Lace Wrap | Shawls & Wraps | Adults, easy lace | Stitch: eyelet rows on wrap (the wrap now takes a stitch) | verified |
| 34 | Tea Cozy | Home | Gift, easy | New shape: two flat sides joined in the round over the lid | verified |
| 35 | Boot Cuffs | Socks & Feet | Adults, beginner | New shape: rib inside the boot, seed stitch above | verified |
| 36 | Striped Beanie | Hats | Anyone, easy | Colorwork | verified |
| 37 | Kids' Cardigan | Sweaters | Children 2 to 12, intermediate | New shape: cardigan engine at child sizes | verified |
| 38 | Linen Stitch Scarf | Scarves & Cowls | Adults, easy | Stitch: linen stitch on scarf | verified |
| 39 | Baby Socks | Baby | Babies, intermediate | New shape: sock engine at baby sizes | verified |
| 40 | Waffle Blanket | Blankets | Baby to throw, beginner | Stitch: waffle on bordered blanket | verified |
| 41 | Mug Cozy | Home | Gift, easy | New shape: seed stitch band buttoned around the handle | verified |
| 42 | Houndstooth Beanie | Hats | Adults, intermediate | Colorwork: 4-wide repeat | verified |
| 43 | Capelet | Shawls & Wraps | Adults, easy | New shape: top-down | verified |
| 44 | Double Moss Cowl | Scarves & Cowls | Anyone, beginner | Stitch | verified |
| 45 | Placemat | Home | Anyone, beginner | New shape | verified |
| 46 | Mini Stocking Ornament | Holiday | Gift, easy | New shape | verified |
| 47 | Rope Cable Mitts | Hands | Adults, intermediate | Stitch: rope cable on handwarmers (stitched mitts get an afterthought thumb) | verified |
| 48 | Short-Sleeve Raglan Tee | Sweaters | Adults, intermediate | New shape: raglan with short sleeves, DK, a narrow band at the sleeve | verified |
| 49 | Honeycomb Beanie | Hats | Adults, easy | Stitch | verified |
| 50 | Waffle Washcloth | Home | Anyone, beginner | Stitch | verified |
| 51 | Feather and Fan Wrap | Shawls & Wraps | Adults, easy lace | Stitch | verified |
| 52 | Drawstring Pouch | Home | Gift, easy | New shape: top down in the round, eyelets, three-needle bind off, twisted cord | verified |
| 53 | Color-Block Beanie | Hats | Anyone, easy | Colorwork: contrast brim, one band, a third color to the crown | verified |
| 54 | Twisted Rib Scarf | Scarves & Cowls | Adults, easy | Stitch | planned |
| 55 | Hot Water Bottle Cover | Home | Gift, easy | New shape | planned |
| 56 | Bandana Kerchief | Scarves & Cowls | Adults, beginner | New shape: small triangle with ties | planned |
| 57 | Snowflake Cowl | Scarves & Cowls | Winter gift, intermediate | Colorwork | planned |
| 58 | Broken Rib Beanie | Hats | Anyone, beginner | Stitch | planned |
| 59 | Rope Cable Blanket | Blankets | Throw, intermediate | Stitch | planned |
| 60 | Turtleneck Pullover | Sweaters | Adults, intermediate | New shape: raglan with a tall collar | planned |
| 61 | Linen Stitch Washcloth | Home | Anyone, easy | Stitch | planned |
| 62 | Star Beanie | Hats | Anyone, intermediate | Colorwork | planned |
| 63 | Shrug | Shawls & Wraps | Adults, easy | New shape | planned |
| 64 | Waffle Cowl | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 65 | Tote Bag | Home | Anyone, easy | New shape | planned |
| 66 | Diamond Brocade Scarf | Scarves & Cowls | Adults, easy | Stitch | planned |
| 67 | Baby Cocoon | Baby | Newborn, easy | New shape | planned |
| 68 | Garter Ridge Beanie | Hats | Anyone, beginner | Stitch | planned |
| 69 | Striped Blanket | Blankets | Baby to throw, beginner | Colorwork | planned |
| 70 | Tube Socks | Socks & Feet | Anyone, easy | New shape: spiral rib, no heel | planned |
| 71 | Honeycomb Blanket | Blankets | Throw, easy | Stitch | planned |
| 72 | Mushroom Beanie | Hats | Anyone, intermediate | Colorwork | planned |
| 73 | Double Moss Ear Warmer | Accessories | Anyone, beginner | Stitch | planned |
| 74 | Knit Basket | Home | Anyone, easy | New shape | planned |
| 75 | Chevron Lace Scarf | Scarves & Cowls | Adults, easy lace | Stitch | planned |
| 76 | Kids' Vest | Sweaters | Children 2 to 12, intermediate | New shape: vest at child sizes | planned |
| 77 | Polka Dot Beanie | Hats | Children, intermediate | Colorwork | planned |
| 78 | Seeded Rib Cowl | Scarves & Cowls | Adults, easy | Stitch | planned |
| 79 | Table Runner | Home | Anyone, beginner | New shape | planned |
| 80 | Strawberry Beanie | Hats | Children, intermediate | Colorwork | planned |
| 81 | Waffle Mitts | Hands | Adults, easy | Stitch | planned |
| 82 | Ruana | Shawls & Wraps | Adults, easy | New shape | planned |
| 83 | Basketweave Beanie | Hats | Anyone, easy | Stitch | planned |
| 84 | Feather and Fan Blanket | Blankets | Baby to throw, easy lace | Stitch | planned |
| 85 | Scrunchie | Accessories | Gift, beginner | New shape | planned |
| 86 | Striped Cowl | Scarves & Cowls | Anyone, beginner | Colorwork | planned |
| 87 | Mistake Rib Scarf | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 88 | Floor Pouf | Home | Anyone, easy | New shape | planned |
| 89 | Zigzag Beanie | Hats | Anyone, intermediate | Colorwork | planned |
| 90 | Rope Cable Cowl | Scarves & Cowls | Adults, intermediate | Stitch | planned |
| 91 | Baby Bib | Baby | Babies, beginner | New shape | planned |
| 92 | Eyelet Slouch Hat | Hats | Adults, easy lace | Stitch | planned |
| 93 | Checkerboard Blanket | Blankets | Baby to throw, intermediate | Colorwork | planned |
| 94 | Honeycomb Washcloth | Home | Anyone, easy | Stitch | planned |
| 95 | Gloves | Hands | Adults, intermediate | New shape | planned |
| 96 | Twisted Rib Beanie | Hats | Adults, easy | Stitch | planned |
| 97 | Bath Mat | Home | Anyone, beginner | New shape | planned |
| 98 | Panda Beanie | Hats | Children, intermediate | Colorwork: ear crown | planned |
| 99 | Rope Cable Pillow | Home | Anyone, intermediate | Stitch | planned |
| 100 | Striped Raglan | Sweaters | Adults, intermediate | Colorwork: stripes on the raglan | planned |
| 101 | Garter Ridge Scarf | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 102 | Nordic Band Beanie | Hats | Adults, intermediate | Colorwork | planned |
| 103 | Laptop Sleeve | Home | Anyone, easy | New shape | planned |
| 104 | Chevron Lace Cowl | Scarves & Cowls | Adults, easy lace | Stitch | planned |
| 105 | Rope Cable Leg Warmers | Accessories | Adults, intermediate | Stitch | planned |
| 106 | Fair Isle Band Cowl | Scarves & Cowls | Adults, intermediate | Colorwork | planned |
| 107 | Linen Stitch Blanket | Blankets | Throw, easy | Stitch | planned |
| 108 | Tree Ornament | Holiday | Gift, beginner | New shape | planned |
| 109 | Double Moss Slouch Hat | Hats | Adults, beginner | Stitch | planned |
| 110 | Button Neck Warmer | Accessories | Adults, easy | New shape | planned |
| 111 | Wave Beanie | Hats | Anyone, intermediate | Colorwork | planned |
| 112 | Waffle Ear Warmer | Accessories | Anyone, beginner | Stitch | planned |
| 113 | Diamond Brocade Blanket | Blankets | Throw, easy | Stitch | planned |
| 114 | Draft Stopper | Home | Anyone, beginner | New shape | planned |
| 115 | Seed Stitch Beanie | Hats | Anyone, beginner | Stitch | planned |
| 116 | Color-Block Scarf | Scarves & Cowls | Anyone, beginner | Colorwork | planned |
| 117 | Basketweave Cowl | Scarves & Cowls | Anyone, easy | Stitch | planned |
| 118 | Hood | Accessories | Adults, easy | New shape | planned |
| 119 | Flower Beanie | Hats | Children, intermediate | Colorwork | planned |
| 120 | Honeycomb Scarf | Scarves & Cowls | Adults, easy | Stitch | planned |
| 121 | Double Moss Pillow | Home | Anyone, beginner | Stitch | planned |
| 122 | Reindeer Beanie | Holiday | Gift, intermediate | Colorwork | planned |
| 123 | Heart Cowl | Scarves & Cowls | Valentine's, intermediate | Colorwork | planned |
| 124 | Garter Ridge Blanket | Blankets | Baby to throw, beginner | Stitch | planned |
| 125 | Feather and Fan Cowl | Scarves & Cowls | Adults, easy lace | Stitch | planned |
| 126 | Striped Vest | Sweaters | Adults, intermediate | Colorwork | planned |
| 127 | Linen Stitch Cowl | Scarves & Cowls | Adults, easy | Stitch | planned |
| 128 | Bunting | Holiday | Parties and nurseries, beginner | New shape | planned |
| 129 | Houndstooth Cowl | Scarves & Cowls | Adults, intermediate | Colorwork | planned |
| 130 | Chevron Lace Slouch Hat | Hats | Adults, easy lace | Stitch | planned |
| 131 | Snowflake Mittens | Hands | Winter gift, intermediate | Colorwork: mittens taught colorwork | planned |
| 132 | Double Moss Wrap | Shawls & Wraps | Adults, beginner | Stitch | dropped: the Rectangular Wrap is already a moss stole, and the wrap shape takes no stitch |
| 133 | Broken Rib Scarf | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 134 | Waffle Scarf | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 135 | Striped Pillow | Home | Anyone, beginner | Colorwork | planned |
| 136 | Diamond Brocade Washcloth | Home | Anyone, easy | Stitch | planned |
| 137 | Seeded Rib Blanket | Blankets | Throw, easy | Stitch | planned |
| 138 | Striped Mitts | Hands | Anyone, easy | Colorwork | planned |
| 139 | Basketweave Pillow | Home | Anyone, easy | Stitch | planned |
| 140 | Linen Stitch Wrap | Shawls & Wraps | Adults, easy | Stitch | planned |
| 141 | Double Moss Mitts | Hands | Anyone, easy | Stitch | planned |
| 142 | Chevron Lace Wrap | Shawls & Wraps | Adults, easy lace | Stitch | planned |
| 143 | Striped Drop-Shoulder | Sweaters | Adults, easy | Colorwork | planned |
| 144 | Seeded Rib Scarf | Scarves & Cowls | Adults, easy | Stitch | planned |
| 145 | Garter Ridge Washcloth | Home | Anyone, beginner | Stitch | planned |
| 146 | Cropped Cardigan | Sweaters | Adults, intermediate | New shape | planned |
| 147 | Yoke Sweater | Sweaters | Adults, intermediate | New shape: circular yoke | planned |
| 148 | Tank Top | Sweaters | Adults, intermediate | New shape | planned |
| 149 | Waffle Leg Warmers | Accessories | Adults, beginner | Stitch | planned |
| 150 | Honeycomb Pillow | Home | Anyone, easy | Stitch | planned |
| 151 | Eyelet Lace Scarf | Scarves & Cowls | Adults, easy lace | Stitch | planned |
| 152 | Pixie Hat | Baby | Babies and children, easy | New shape: pointed top | planned |
| 153 | Bucket Hat | Hats | Adults, intermediate | New shape | planned |
| 154 | Striped Socks | Socks & Feet | Anyone, intermediate | Colorwork: socks taught stripes | planned |
| 155 | Lace Socks | Socks & Feet | Adults, intermediate | Stitch: lace leg | planned |
| 156 | Rib Socks | Socks & Feet | Anyone, intermediate | Stitch: ribbed leg | planned |
| 157 | Hurdle Stitch Scarf | Scarves & Cowls | Anyone, beginner | Stitch | planned |
| 158 | Diamond Brocade Pillow | Home | Anyone, easy | Stitch | planned |
| 159 | Broken Rib Blanket | Blankets | Baby to throw, beginner | Stitch | planned |
| 160 | Double Moss Leg Warmers | Accessories | Anyone, beginner | Stitch | planned |
| 161 | Baby Pullover | Baby | Babies 3 to 24 months, intermediate | New shape: top-down raglan with a buttoned shoulder opening so it passes over a baby's head (replaces #21) | planned |

## Already in the library (45)

Hats: Ribbed Beanie, Slouch Hat, Rolled Brim Hat, Balaclava, Earflap Hat, Cabled Beanie, Pompom Bonnet,
Beret, Heart, Cherry, Checkerboard, Diamond and Bear Beanies, Round Raccoon Beanie (site). Scarves and
cowls: Garter, Ribbed, Seed Stitch and Keyhole Scarves, Ribbed, Seed Stitch, Chunky and Checkerboard Cowls,
Neck Scarf, Rectangular Wrap. Home: Bordered, Garter and Basketweave Blankets, Diagonal Dishcloth, Pillow
Cover, Market Bag. Accessories: Ear Warmer, Handwarmers, Heart Mitts, Leg Warmers, Triangle and Crescent
Shawls, Cabled Headband, Mittens, Cuff-Down Socks, Slippers, Baby Booties. Sweaters: Raglan Pullover,
Raglan Cardigan, Sweater Vest, Kids' Raglan, Drop-Shoulder Sweater.
