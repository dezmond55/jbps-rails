# User Auth Audit — 2026-05-14

Audit of all authentication code currently in the repository. Module 1 Pass 1 (`docs/specs/01-project-management.md`) names user authentication as a prerequisite; this report establishes what's already in place before scoping any further work.

**Bottom line:** the code on disk is essentially the output of `bin/rails generate authentication` — Rails 8's built-in scaffold — wired into `ApplicationController`. Login, logout, and password reset all work. Self-signup, roles, email confirmation, organisation linkage, and most tests are absent.

---

## 1. Migrations

### `db/migrate/20260218133054_create_users.rb`

```ruby
create_table :users do |t|
  t.string :email_address, null: false
  t.string :password_digest, null: false
  t.timestamps
end
add_index :users, :email_address, unique: true
```

- Columns: `email_address` (string, NOT NULL), `password_digest` (string, NOT NULL), `created_at`, `updated_at`.
- One index: unique on `email_address`.
- No `name`, `role`, `admin`, `confirmed_at`, `organisation_id`, or any other column.

### `db/migrate/20260218133102_create_sessions.rb`

```ruby
create_table :sessions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :ip_address
  t.string :user_agent
  t.timestamps
end
```

- Columns: `user_id` (bigint, NOT NULL, FK → users), `ip_address` (string, nullable), `user_agent` (string, nullable), timestamps.
- Index: implicit on `user_id` from `t.references` (confirmed in `db/schema.rb:45` as `index_sessions_on_user_id`, non-unique).
- Foreign key constraint enforced at the DB level (`add_foreign_key "sessions", "users"`, `db/schema.rb:56`).
- Relationship: each `Session` belongs to one `User`; a user can have many sessions (one row per browser/device).

The schema currently sits at version `2026_02_22_085111` (`db/schema.rb:13`) — the auth migrations are followed by the enquiries migration. Both auth migrations are applied.

---

## 2. Models

### `app/models/user.rb` (6 lines)

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
```

- `has_secure_password` — provides `password=`, `password_confirmation=`, `authenticate`, `authenticate_by`, and (Rails 7.1+) registers a `:password_reset` token generator that backs `User#password_reset_token` and `User.find_by_password_reset_token!`. That's why no `generates_token_for` is needed in the model body even though the password-reset flow uses those methods.
- `has_many :sessions, dependent: :destroy` — deleting a user wipes their sessions.
- `normalizes :email_address` — strips whitespace and downcases on assignment, so duplicate-email detection by the unique index is case-insensitive.
- **No explicit validations.** No `validates :email_address, presence: true` and no format check. Presence is enforced only by the DB `null: false`; format isn't enforced at all. `has_secure_password` adds its own validation that `password` is present on create and ≤ 72 bytes.
- No callbacks. No scopes. No `belongs_to :organisation` (notable given the CLAUDE.md multi-tenancy rule).

### `app/models/session.rb` (3 lines)

```ruby
class Session < ApplicationRecord
  belongs_to :user
end
```

- That's the whole model. No expiry, no `last_seen_at`, no scopes for "active" sessions.

### `app/models/current.rb` (4 lines)

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

- Per-request global store. `Current.session` holds the current `Session` record; `Current.user` is delegated through to `session.user`.
- `allow_nil: true` means `Current.user` returns `nil` on unauthenticated requests rather than raising.

There is **no `current_user` controller helper** — code reads `Current.user` directly.

---

## 3. Controllers

### `app/controllers/sessions_controller.rb`

| Action | What it does |
|---|---|
| `new` | Renders the login form. No instance variables set. |
| `create` | `User.authenticate_by(email_address:, password:)` — on success calls `start_new_session_for(user)` then `redirect_to after_authentication_url` (the saved return URL, else `root_url`). On failure: redirect back to `new_session_path` with flash alert "Try another email address or password." |
| `destroy` | Calls `terminate_session` (destroys the `Session` row, clears the cookie) then redirects to `new_session_path`. |

Two class-level declarations:

- `allow_unauthenticated_access only: %i[ new create ]` (line 2) — `destroy` requires an authenticated session.
- `rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }` (line 3) — Rails 8's built-in rate limiter. Cache-backed. 10 POSTs to `/session` per 3-minute window per IP.

### `app/controllers/passwords_controller.rb`

| Action | What it does |
|---|---|
| `new` | Renders the "forgot password" email form. |
| `create` | Looks up `User.find_by(email_address: ...)`. If found, enqueues `PasswordsMailer.reset(user).deliver_later`. **Always** redirects to `new_session_path` with notice "Password reset instructions sent (if user with that email address exists)." — same response whether the email exists or not, so it does not leak account existence. |
| `edit` | Renders the new-password form (set_user_by_token before_action loads `@user`). |
| `update` | `@user.update(params.permit(:password, :password_confirmation))`. On success: redirect to login with "Password has been reset." On failure: redirect back to the edit page with "Passwords did not match." |

- `allow_unauthenticated_access` (line 2, no `only:`) — applies to all four actions.
- `before_action :set_user_by_token, only: %i[ edit update ]` (line 3) — calls `User.find_by_password_reset_token!(params[:token])`, rescuing `ActiveSupport::MessageVerifier::InvalidSignature` to redirect with "Password reset link is invalid or has expired." Token lifetime is 15 minutes (default from `has_secure_password`'s built-in token generator).

### No other auth-related controllers

- No `RegistrationsController`.
- No `UsersController`.
- No `ConfirmationsController`, `UnlocksController`, etc.

Existing app controllers and their auth posture (every controller inherits `before_action :require_authentication` from the concern):

| Controller | Auth posture |
|---|---|
| `PagesController` (home, about) | `allow_unauthenticated_access` — fully public |
| `ContactsController#create` | `allow_unauthenticated_access` — public |
| `EnquiriesController#create` | `allow_unauthenticated_access` — public |
| `ServicesController` | `allow_unauthenticated_access only: [:index]`; `:new/:create/:edit/:update/:destroy` require auth |
| `SessionsController` | `new`/`create` public; `destroy` requires auth |
| `PasswordsController` | all public |

---

## 4. Views

### `app/views/sessions/new.html.erb` (11 lines)

- Flash alert/notice as inline-coloured `div`s (red/green).
- `form_with url: session_path` containing an email field (`email_address`) and password field (`password`, `maxlength: 72`), submit button "Sign in".
- "Forgot password?" link to `new_password_path` below the form.
- No HTML wrapper (no `<h1>`, no styling beyond the inline flash colours) — renders inside the application layout.

### `app/views/passwords/new.html.erb` (8 lines)

- `<h1>Forgot your password?</h1>`.
- Single email field, submits to `passwords_path`. Button label: "Email reset instructions".

### `app/views/passwords/edit.html.erb` (9 lines)

- `<h1>Update your password</h1>`.
- Password + password_confirmation fields, PUT to `password_path(params[:token])`. Button: "Save".

### `app/views/passwords_mailer/reset.{html,text}.erb`

- "You can reset your password within the next 15 minutes on" with a link/URL to `edit_password_url(@user.password_reset_token)`.
- Text version is the URL on its own line.

### **No signup view, no logout link**

- There is no `users/new.html.erb`, no signup form anywhere.
- The application layout (`app/views/layouts/application.html.erb`) has a marketing nav (Services / About / Regions / Contact) but **no Login link and no Logout link**. The login page is reachable only by knowing the URL `/session/new`. Logging out requires issuing a `DELETE /session` request, which no view currently triggers.

---

## 5. Routes (`config/routes.rb`)

```ruby
resource :session
resources :passwords, param: :token
```

That produces:

| Verb | Path | Controller#action | Helper |
|---|---|---|---|
| GET | `/session/new` | `sessions#new` | `new_session_path` |
| POST | `/session` | `sessions#create` | `session_path` |
| DELETE | `/session` | `sessions#destroy` | `session_path` |
| GET | `/passwords/new` | `passwords#new` | `new_password_path` |
| POST | `/passwords` | `passwords#create` | `passwords_path` |
| GET | `/passwords/:token/edit` | `passwords#edit` | `edit_password_path(token)` |
| PATCH/PUT | `/passwords/:token` | `passwords#update` | `password_path(token)` |

Note: `resource :session` is singular — there is no `GET /sessions` index, no `GET /session/:id`, and no edit. Also no `/login` or `/logout` aliases.

`resources :passwords, param: :token` keeps `:token` in the URL instead of the usual numeric id, so reset URLs look like `/passwords/<signed_token>/edit`.

The rest of `routes.rb` is unrelated: `root "pages#home"`, `get "about"`, `post "contact"`, the Services redirect, `resources :services`, `resources :enquiries, only: [:create]`.

---

## 6. Helpers, concerns, current-user plumbing

### `app/controllers/concerns/authentication.rb` (52 lines)

This is the heart of the system. Mixed into `ApplicationController` via `include Authentication` (`app/controllers/application_controller.rb:2`), so **every controller requires authentication by default** unless it opts out with `allow_unauthenticated_access`.

| Method | Visibility | Purpose |
|---|---|---|
| `allow_unauthenticated_access(**options)` | class method | Sugar for `skip_before_action :require_authentication, **options`. Used by controllers to opt out per-action. |
| `authenticated?` | private; also `helper_method` | Returns truthy if a session can be resumed from the cookie. Available in views as `authenticated?`. |
| `require_authentication` | private; runs as `before_action` | Resumes session if possible; otherwise calls `request_authentication`. |
| `resume_session` | private | `Current.session ||= find_session_by_cookie`. |
| `find_session_by_cookie` | private | `Session.find_by(id: cookies.signed[:session_id])`. Returns `nil` if cookie missing or session deleted. |
| `request_authentication` | private | Saves `request.url` to `session[:return_to_after_authenticating]`, redirects to `new_session_path`. |
| `after_authentication_url` | private | Pops the saved `return_to_after_authenticating` (else `root_url`). |
| `start_new_session_for(user)` | private | Creates a `Session` row capturing `user_agent` and `remote_ip`, sets `Current.session`, sets a signed permanent cookie `session_id` (`httponly: true, same_site: :lax`). |
| `terminate_session` | private | `Current.session.destroy` and `cookies.delete(:session_id)`. |

### `app/controllers/application_controller.rb` (5 lines)

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
end
```

That single `include` is what makes auth the default. Any new controller is locked down unless it explicitly calls `allow_unauthenticated_access`.

### "current user" pattern

- There is **no `current_user` method**. Code reads `Current.user` (delegated through `Current.session.user`).
- The view helper exposed is `authenticated?` (returns the session if one can be resumed, else `nil`). No `current_user` view helper.
- Note: `authenticated?` is currently not actually called anywhere in views — it exists but no template branches on it.

---

## 7. Tests

| File | Coverage |
|---|---|
| `test/models/user_test.rb` | **Empty.** Only the commented-out `# test "the truth"` placeholder. |
| `test/fixtures/users.yml` | Two fixtures (`one`, `two`) — `one@example.com` and `two@example.com`, both with bcrypt-hashed password `"password"` (rebuilt at fixture-load time via ERB). |
| `test/controllers/services_controller_test.rb` | Logs in via `post session_path, params: { email_address: users(:one).email_address, password: "password" }` in `setup`, then exercises all CRUD actions of `ServicesController`. This is the **only** test that exercises any part of the auth code path, and it does so incidentally. |
| `test/mailers/previews/passwords_mailer_preview.rb` | `PasswordsMailerPreview#reset` — preview at `/rails/mailers/passwords_mailer/reset`, calls `PasswordsMailer.reset(User.take)`. Not a test, just a dev preview. |

**No tests for:**
- `SessionsController` (login success, login failure, rate limit, logout)
- `PasswordsController` (any of the four actions)
- The `Authentication` concern itself (require_authentication redirect, resume_session, session cookie semantics)
- `User` model (validation behaviour, normalisation, `has_secure_password` integration)
- `Session` model

There are no integration tests (`test/integration/` doesn't exist) and no system tests for auth.

---

## 8. What's NOT there

| Capability | Status |
|---|---|
| **Self-signup / registration** | Absent. No `RegistrationsController`, no signup view, no route, no `User.new`-from-public-form path. Users can only be created via `bin/rails console` or seeds. |
| **Logout UI** | Absent. The layout nav has no logout button. `DELETE /session` exists as a route but no view triggers it. |
| **Login UI entry point** | No header link. `/session/new` is reachable only by knowing the URL. |
| **Email confirmation** | Absent. No `confirmed_at`, no `email_verification_token`, no confirmation flow. New users (when they exist) are immediately usable. |
| **Account lockout / failed-attempt tracking** | Absent. The only brute-force defence is the IP-keyed rate-limit on `SessionsController#create` (10 / 3 minutes). |
| **Roles / admin distinction** | Absent. No `role`, `admin`, or `permissions` column on `users`. No authorisation library (Pundit/CanCan). Every authenticated user has equal privilege. |
| **Organisation linkage** | Absent. `User` has no `belongs_to :organisation` and no `organisation_id` column. **This directly conflicts with the CLAUDE.md non-negotiable rule** that every User belongs to an Organisation. |
| **Password complexity rules** | None beyond `has_secure_password`'s default (present on create, ≤ 72 bytes). No minimum length, no character-class requirement. |
| **Email-address format validation** | Absent. The model doesn't validate format; you could create a user with `email_address: "notanemail"` as long as it's unique. |
| **Session expiry / idle timeout** | Absent. The cookie is `permanent`; sessions live until the user logs out or the row is deleted. |
| **"Remember me" / device management UI** | Absent. Sessions are recorded with `user_agent` and `ip_address` but there's no view that lists or revokes them. |
| **2FA / passkeys / OAuth** | Absent. Email + password only. |
| **Helpful nav/flash plumbing** | The login form uses inline-styled `div`s for flash messages — there's no shared flash partial, no styling. |

---

## 9. Stock Rails 8 generated code, or customised?

This is **stock `bin/rails generate authentication` output**, essentially unmodified. Specifically:

- The two migrations are byte-identical to the Rails 8 generator templates.
- `User`, `Session`, and `Current` are unchanged from the generator.
- The `Authentication` concern, `SessionsController`, `PasswordsController`, and their views are unchanged from the generator.
- `PasswordsMailer` and its templates are unchanged.
- Routes (`resource :session`, `resources :passwords, param: :token`) match the generator.
- `application_controller.rb` adds the generator's `include Authentication`; no further additions.

The only **adjacent customisation** is that other (non-auth) controllers call `allow_unauthenticated_access` to opt themselves out — `PagesController`, `ContactsController`, `EnquiriesController`, and `ServicesController#index`. The fact that these calls exist is itself the signal that the marketing site went up after the auth generator ran (because the generator would otherwise have locked those pages).

I see no deviations in the auth files themselves: no extra validations, no extra columns, no extra actions, no view styling, no organisation scoping.

---

## 10. Practical state

### Users in the development database

`bundle exec rails runner "puts User.count"` returns **1**.

I did not inspect the row's identity (no `puts User.pluck(:email_address)` was run). If needed:

```powershell
bundle exec rails runner "puts User.pluck(:email_address)"
```

### What happens if Derek starts the server right now

- `GET /` → home page, public. No "Login" link in the nav.
- `GET /login` → **404** (no such route — the path is `/session/new`).
- `GET /session/new` → login form. Submits to `POST /session`.
- `POST /session` with valid credentials → session row created, `session_id` cookie set, redirect to `root_url` (or wherever they came from).
- `POST /session` with invalid credentials → redirect back to `/session/new` with red flash "Try another email address or password."
- After 10 failed POSTs to `/session` from the same IP within 3 minutes → "Try again later." until the window resets.
- `GET /services` (dev) → public index. Production redirects this to `/`.
- `GET /services/new` while unauthenticated → redirect to `/session/new`, request URL stashed in the Rails session; logging in then bounces back to `/services/new`.
- `GET /passwords/new` → forgot-password form.
- `DELETE /session` (no UI for this) → destroys current session row, deletes cookie, redirects to `/session/new`.
- There is **no way through the UI** to create a second user. To add one:

  ```powershell
  bundle exec rails runner "User.create!(email_address: 'derek@jbps.com.au', password: 'changeme1234')"
  ```

---

## Implications for Module 1 Pass 1

Not part of the requested scope, but worth flagging while everything is fresh:

1. **The single biggest gap is `User.organisation_id`.** Every other domain model that Pass 1 introduces (Project, Site, …) is meant to belong to an Organisation per CLAUDE.md; `User` was generated before that rule was committed and currently violates it. Adding `belongs_to :organisation` + a default scope on `User` is a one-migration job, but it has to land before the Pass 1 models reference users.
2. **No way to create a user from the UI is fine for Pass 1** (Derek can seed himself), but worth a conscious decision rather than an accident.
3. **No logout button** is harmless but worth a 30-second fix once any signed-in screen exists.
4. **Test coverage for the auth concern is zero** — acceptable for stock generator output, but anything we add on top (org scoping, role checks) deserves tests.
