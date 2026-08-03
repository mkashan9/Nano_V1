# junior_home — visual analysis (VIS-01)

## Reference

- Path: `UI_reference/kids/home.jpeg`
- Dimensions: **740 × 1600**
- Aspect: ~0.463 (tall phone)
- Target route: `/screenshot/junior_home`

## Main regions

| Region | Approx box | Notes |
|--------|------------|-------|
| Header | 24,48 → 692×100 | Avatar left, greeting center-left, star badge right |
| Hero | 24,160 → 692×280 | Continue Learning + Animals Adventure + Start + fox |
| Subjects | 24,460 → 692×900 | 2×2 Math / English / Science / Stories |
| Bottom nav | 0,1450 → 740×150 | Home / Learn / Games / Profile |

## Relative measurements (÷ 740 width)

- Page gutter ≈ 24/740 ≈ **3.2%** (use ~20–24 logical at reference width)
- Hero width ≈ 692/740 ≈ **93.5%**
- Subject gap ≈ 16–20 px between cards
- Nav height ≈ 150/1600 ≈ **9.4%** of height

## Typography hierarchy

1. Greeting — large bold white (“Hi Ali,”)
2. Hero title — large bold white (“Animals Adventure”)
3. Hero eyebrow — small white (“Continue Learning”)
4. Subject titles — bold white on colored cards
5. Nav labels — small; active purple

## Main colors

- Canvas: deep navy
- Math: bright blue
- English: bright green
- Science: orange/yellow
- Stories: pink/magenta
- Active nav: purple
- Star badge: dark chip + yellow star

## Radius / spacing

- Large junior card radius (~28–32)
- Pill Start button
- Circular avatar with purple ring

## Required assets

- Avatar (boy hoodie)
- Continue fox + forest scene
- Four subject illustrations

## Uncertain

- Star badge = streak vs level → fixtures use streak **7**
- Exact font family → Nano junior typography tokens
