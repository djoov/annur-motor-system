---
name: annur-flutter-ui
description: UI/UX rules for the Annur Motor Flutter app (mobile, tablet, Windows desktop). Use whenever creating, redesigning, polishing, or auditing any Flutter screen or widget in this project — layouts, cards, forms, lists, POS/kasir flow, dashboards, bottom nav, sidebar, dialogs, empty/loading/error states, or when the user asks to "rapikan UI", "redesign", "percantik tampilan", or audit UX.
---

# Annur Flutter UI

Design + UX guardrails for `mobile/` (Flutter, Material 3, Provider). The app is a POS + inventory tool used by a cashier/mechanic in a busy motorcycle workshop and by the owner on the phone. **Speed, legibility, and zero mis-taps beat decoration.**

## 0. Before touching UI
1. Read `lib/core/theme.dart` (`AppColors`, `AppTheme`) and `DESIGN.md`. They are the token source of truth.
2. Read the target screen fully and note its responsive branch (`ResponsiveLayout`, `LayoutBuilder`, width < 900 = mobile; Windows is always desktop).
3. Only edit the files needed. Keep Provider logic, Firestore field names, and navigation behaviour intact unless asked. State the files you will change before large redesigns.

## 1. Tokens — no improvisation
- Colors: use `AppColors.*` / `Theme.of(context).colorScheme`. Do not add new `Color(0xFF...)` literals in screens. If a color is truly needed, add it to `AppColors` with a semantic name first.
  - primary `#0058BE`, secondary `#6B38D4`, background `#F8FAFC`, surface white, foreground `#131B2E`, mutedForeground `#64748B`, border `#E2E8F0`, accentSoft `#DAE2FD`, destructive `#EF4444`, success `#10B981`.
  - **Logo brand pair**: `brandNavy` `#181828` + `brandYellow` `#F8D840` (from the Annur logo). Use for the one hero block per screen (e.g. Beranda header: navy bg, key number in yellow) and the Kasir nav button (navy, yellow icon). Yellow only as accent/number on navy or as duotone icon fill — never yellow text on white. `primary` blue stays the interactive color (icons, links, selected states). The old blue→violet gradient is retired.
- Font: Plus Jakarta Sans (set globally in theme). Don't set `fontFamily` per widget.
- Type scale (use `Theme.of(context).textTheme` or these sizes): page title 20–22 w700 · section title 16–18 w600 · body 14 w400/500 · caption 12 · grid label 11–12 w500 · money highlight 22–28 w700 with `FontFeature.tabularFigures()`.
- Spacing: 4-pt grid — 4, 8, 12, 16, 20, 24, 32. Screen side padding 16 (mobile) / 24 (desktop).
- Radius: 8 chips/badges · 14 inputs/buttons · 16 cards · 24 bottom sheets · 30 pill nav.
- Shadow: prefer 1px `AppColors.border` + elevation 0. Soft shadow only for floating elements: `0xFF0F172A` @5% blur 20 y4; nav @8% blur 30 y10.
- Icons, two families only (no Material `Icons.*`):
  - **Menu / feature entry points** (quick actions, menu grids, "Semua Menu", empty-state hero icons): the app's own duotone set `DuoIcons` via `DuoIconTile(DuoIcons.x, size: 56|40)` from `lib/ui/duo_icon.dart` — blue outline + logo-yellow (`AppColors.brandYellow`) accent on a `primarySoft` tile. Need a new one? Add a case to the painter on the 24-grid (stroke 1.8, yellow ≈ 30–40% of the glyph, `knock` paint for overlaps). Never use PNG icon assets (breaks Shorebird patching).
  - **Utility icons** (nav bar, chevrons, status rows, inline buttons): `LucideIcons.*`. Size 20 inline, 22–24 nav.
  - **Shorebird patch constraint:** icon fonts are tree-shaken release assets. Until the next full `shorebird release`, only use Lucide/Material icons that already exist in the installed release, or they render blank. Verify with `python tool/check_patch_icons.py <release.apk>` after a `--dry-run` build. Prefer `DuoIcons` (painted, always patchable) for anything new.

## 2. Workshop-grade UX rules
- **Touch targets ≥ 48×48 dp** (POS qty +/-, delete, nav). Put destructive actions away from frequent ones.
- **Money**: always `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`. Right-align amounts in tables/lists; tabular figures.
- **Stock indicators (traffic light)**: stock 0 → destructive; ≤ low-stock threshold → amber `#F59E0B` (add to AppColors as `warning` if missing); else success. Always pair color with text/icon (never color alone).
- **Role masking**: buy price (modal), profit, and admin actions must stay behind `context.watch<AuthProvider>().isAdmin`. Never expose them in a redesign.
- **Every data view ships 4 states**: loading (skeleton or `CircularProgressIndicator.adaptive` centered), empty (icon + one Indonesian sentence + primary action), error (message + "Coba lagi"), content.
- **Feedback**: every write (simpan, bayar, hapus) shows progress (disable button + spinner) and a result (`SnackBar` floating, success/destructive colors). Destructive = confirmation dialog with red confirm button.
- **Forms**: labels above/inside fields, `keyboardType` set (number for price/qty/phone), `textInputAction` next/done, validation messages in Indonesian, submit button disabled while saving.
- **Lists**: search field sticky at top, pull-to-refresh on mobile, `ListView.builder`/`SliverList` (never build large lists eagerly), dividers or 8–12 gap, not both.
- **Copy**: Bahasa Indonesia, short, verb-first on buttons ("Simpan", "Bayar", "Tambah Barang"). No lorem ipsum, no invented numbers.

## 3. Responsive
- Mobile (< 600): single column, floating bottom nav, bottom sheets for filters/actions.
- Tablet (600–900): 2-column grids, menu grid up to 6–8 columns.
- Desktop/Windows (≥ 900 or Windows): persistent `DesktopSidebar`, master–detail/split views, dialogs instead of full-screen pages for forms, hover states (`InkWell`/`MouseRegion`), keyboard shortcuts (POS: F2 search, F4 pay, Esc cancel) — show shortcut hints in button labels/tooltips.
- Use `LayoutBuilder` constraints, not `MediaQuery.size` of the whole window, inside panes. Wrap text that can overflow (`Expanded` + `maxLines` + `TextOverflow.ellipsis`). Test mentally at 360 dp width and 1366×768.

## 4. Accessibility
- Contrast ≥ 4.5:1 for body text (mutedForeground on white is OK; don't go lighter). Don't put white text on `accentSoft`.
- `Semantics`/`tooltip` on icon-only buttons. Respect text scaling — avoid fixed-height containers around text.

## 4b. Reuse the shared components (don't rebuild them per screen)
- Lists: `lib/ui/app_list.dart` → `AppSearchSliverAppBar`, `AppSearchField`, `AppListPanelSliver` (lazy, one bordered panel), `AppEmptyState`, `InitialAvatar`.
- Forms: `lib/ui/app_form.dart` → `AppFormScaffold` (sticky save button, delete icon in app bar), `confirmDestructive()`, `showErrorSnack()`.
- Stock: `StockBadge(stock)` from `lib/ui/stock_badge.dart`. Kasir pieces: `features/pos/widgets/pos_widgets.dart`.
- Tab screens inside HomeScreen: keep content/FABs above the floating nav with `BottomNavMetrics` (`lib/ui/bottom_nav_metrics.dart`).
- Primary "add" action on list screens = `FloatingActionButton.extended` (theme makes it navy + yellow). Don't override its colors.
- Theme TextStyles must include the app font family (`fontFamily: ff` in `AppTheme`) — a TextStyle given to a component theme without it renders in Roboto.
- Stock writes: Firestore transaction, read `stock ?? qty_display ?? qty_warehouse`, write both `stock` and `qty_display`.

## 5. Code shape
- Extract repeated UI into small private widgets (`class _MetricCard extends StatelessWidget`) instead of giant `_buildX()` methods; move shared ones to `lib/ui/`.
- `const` constructors wherever possible. Use `withValues(alpha: x)` (not deprecated `withOpacity`).
- Don't read providers with `listen: true` in callbacks; use `context.read` there.
- After edits run `flutter analyze lib` (run `flutter pub get` first if you see `uri_does_not_exist`).

## 6. Self-check before finishing
Score 1–5: Hierarchy (one clear primary action per screen) · Consistency (only tokens) · Speed (taps for the main task) · States (loading/empty/error) · Responsive (360 dp + desktop) · Role safety. Anything < 4 → fix before reporting. Report to the user in Bahasa Indonesia with the files changed.
