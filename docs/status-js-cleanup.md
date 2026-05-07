# JS cleanup investigation

The six untracked files in `app/javascript/` are all standalone scripts that are not imported anywhere — `app/javascript/application.js` imports only `@hotwired/turbo-rails` and `controllers`, and `config/importmap.rb` pins only `application`, the Hotwire packages, and `controllers/*`. None of the six are loaded by any path in production.

The layout (`app/views/layouts/application.html.erb`, lines 79–165) contains an inline `<script>` block that already implements every behaviour these files provide. The standalone files appear to be earlier extraction attempts that were never wired up and never deleted.

**Recommendation across the board: delete.** None are loaded, all are functionally superseded by the inline layout script.

A separate architectural question — whether the inline layout script should itself be ported to Stimulus controllers, since the rest of the JS toolchain is set up for that — is real but out of scope here.

## counter.js

- **Status:** Not referenced. Not in `application.js`, not pinned in `importmap.rb`, not in any view.
- **Type:** Vanilla `IntersectionObserver` driving an animated counter on `[data-count]` elements.
- **Recommendation:** Delete.
- **Reasoning:** Layout lines 138–159 implement the same observer, with `data-suffix` support that this file lacks. The home page's `data-count` element uses `data-suffix="+"` — only the layout version handles it.

## enquiry_form.js

- **Status:** Not referenced.
- **Type:** Rails-UJS-style `ajax:success` / `ajax:error` listeners on `#enquiryForm`.
- **Recommendation:** Delete.
- **Reasoning:** The form uses `form_with` (Turbo, not Rails-UJS), so `ajax:*` events never fire — this script wouldn't work even if it were loaded. The actual success flow is the redirect-based `?sent=1` handler in the layout (lines 111–121).

## nav.js

- **Status:** Not referenced.
- **Type:** Vanilla `scroll` listener that toggles `.scrolled` on `#nav` past 80px.
- **Recommendation:** Delete.
- **Reasoning:** Layout lines 81–87 do the same thing with `passive: true` for better scroll performance. Pure duplicate, slightly worse implementation.

## reveal.js

- **Status:** Not referenced.
- **Type:** Vanilla `scroll` listener using `getBoundingClientRect` to add `.vis` to `.reveal` elements.
- **Recommendation:** Delete.
- **Reasoning:** Layout lines 127–136 do the same job with `IntersectionObserver` — fewer reflows, lower runtime cost. Layout version is the better implementation.

## services.js

- **Status:** Not referenced.
- **Type:** Click-delegation accordion for `.service-strip` elements (single-open behaviour).
- **Recommendation:** Delete.
- **Reasoning:** Layout lines 89–98 are functionally identical. Pure duplicate.

## smooth_scroll.js

- **Status:** Not referenced.
- **Type:** Click-delegation handler for `a[href^="#"]` anchors calling `scrollIntoView({ behavior: 'smooth' })`.
- **Recommendation:** Delete.
- **Reasoning:** Layout lines 100–109 are functionally identical. Pure duplicate.
