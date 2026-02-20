# Copilot Instructions for jbps-rails

This is a **Rails 8.0 landing page application** with a Service management feature. The app uses **Hotwire (Turbo + Stimulus)** for interactivity, **PostgreSQL** for persistence, and **Docker + Kamal** for deployment. Services are hidden behind a development-only flag to control feature rollout.

## Architecture Overview

- **Controllers**: `PagesController` (static pages) and `ServicesController` (CRUD operations). Both inherit from `ApplicationController` which enforces modern browser support via `allow_browser`.
- **Models**: Minimal `Service` model with name/description fields. No validations yet—add as needed.
- **Views**: ERB templates with Hotwire integration. Layout at `app/views/layouts/application.html.erb` yields child view content.
- **Routes**: Services are **hidden in production** (`unless: -> { Rails.env.development? }`); see `config/routes.rb` for conditional routing pattern.
- **Database**: PostgreSQL with migrations in `db/migrate/`. Schema auto-generated in `db/schema.rb`.

## Key Development Workflows

### Running the Server
```bash
./bin/dev        # Starts Puma (port 3000) with hot reload
rails server     # Alternative: direct server start
```

### Database Management
```bash
rails db:migrate          # Apply pending migrations
rails db:create          # Create database
rails db:seed            # Load seeds from db/seeds.rb
```

### Testing
```bash
rails test               # Run all tests (uses Minitest)
rails test test/models/service_test.rb  # Run specific model test
```

**Convention**: Tests live in `test/` with same structure as `app/` (e.g., `test/controllers/services_controller_test.rb`). Use `ActionDispatch::IntegrationTest` for controller tests with assertions like `assert_response :success` and `assert_difference("Model.count")`.

### Linting & Security
```bash
bin/rubocop              # Lint Ruby code
bin/brakeman             # Scan for Rails security vulnerabilities
bin/importmap audit      # Check JavaScript dependencies
```

### Deployment
The project uses **Kamal** (`config/deploy.yml`) for containerized deployment. Docker image built from `Dockerfile` (production-optimized). Environment-specific configs in `config/environments/`.

## Project-Specific Patterns & Conventions

### Service Feature Flag
Services are only accessible in development mode:
```ruby
# config/routes.rb
get "/services", to: redirect("/"), unless: -> { Rails.env.development? }
```
When removing this gate, ensure you add validations to the `Service` model and test the feature thoroughly.

### Browser Restrictions
The app enforces modern browser support:
```ruby
# app/controllers/application_controller.rb
allow_browser versions: :modern
```
This rejects outdated browsers automatically. Modify `versions` only if legacy support is needed.

### Controller Pattern
All CRUD controllers follow REST conventions with `service_params` private method:
```ruby
def service_params
  params.require(:service).permit(:name, :description)
end
```
**Always add permitted params** when adding fields to `Service`. Update views and migrations accordingly.

### Views & Hotwire
- All views use **Turbo** (imported in `app/javascript/application.js`) for SPA-like page navigation.
- **Stimulus controllers** live in `app/javascript/controllers/`. Import using standard ES6: `import HelloController from "./hello_controller"`
- Forms automatically submit via Turbo. Test with `assert_redirected_to` in controller tests.

### Asset Pipeline
- Uses **Propshaft** (modern asset pipeline, not Sprockets).
- CSS: `app/assets/stylesheets/application.css`
- JS: `app/javascript/` with **Import Maps** (no bundler needed).

## Testing Approach

Tests use **Rails Minitest** with fixture-free patterns:
- Create test data inline: `Service.create(name: "Test", description: "...")`
- Assert HTTP responses: `assert_response :success`
- Assert counts: `assert_difference("Service.count", 1) { post services_path, params: {...} }`
- Check redirects & flash messages: `assert_redirected_to services_path` + `assert_equal "...", flash[:notice]`

Run full CI locally before pushing (see `.github/workflows/ci.yml`):
- Ruby security scan (Brakeman)
- JS dependency audit (Importmap)
- Style lint (RuboCop)
- Full test suite with PostgreSQL

## Configuration & Environment

- **Ruby**: 3.3.9 (see `Gemfile`)
- **Rails**: 8.0.2+
- **Database**: PostgreSQL (configured in `config/database.yml`)
- **Development**: Hot reload enabled (`config.enable_reloading = true` in `config/environments/development.rb`)
- **Credentials**: Encrypted in `config/credentials.yml.enc` with `config/master.key`

## Common Tasks

- **Add a new Service field**: (1) Update migration & schema, (2) Add to `service_params`, (3) Update views, (4) Test with controller test.
- **Add JS interactivity**: Create `app/javascript/controllers/my_controller.js` and wire in HTML with `data-controller="my"`.
- **Modify routes**: Edit `config/routes.rb`. Remember the production service gate.
- **Environment-specific code**: Use `Rails.env.development?`, `Rails.env.production?`, etc. Service feature uses this pattern.

## What NOT to do

- Don't use Sprockets or old `asset_path` helpers; use Propshaft's standard approach.
- Don't add gems without updating `Gemfile.lock` (run `bundle install`).
- Don't modify `db/schema.rb` directly; use migrations.
- Don't bypass browser validation unless explicitly needed.
