# TeamCC-seat-forge

SeatForge project repository containing backend and frontend services.

---

## Backend

The backend is a **Ruby on Rails 7.2** API-only application, backed by **PostgreSQL**, using
**Solid Queue** (database-backed, no Redis) for background jobs such as hold expiration and
notifications.

### Tech Stack & Features
- **Language/Framework**: Ruby 3.2.2, Rails 7.2 (`--api` mode).
- **Database**: PostgreSQL, via the `pg` gem.
- **Background jobs**: Solid Queue (ActiveJob adapter), running in its own `queue` database.
- **Pagination**: Pagy (`PAGY_DEFAULT_ITEMS` env var controls the default/max page size).
- **Testing**: RSpec (model, request/API, and job specs).

### Prerequisites
- Ruby 3.2.2 (see `backend/.ruby-version`).
- A running PostgreSQL server (default connection: `localhost:5432`, user/password `postgres`).

### How to Run the Backend (Post-Clone Guide)

1. **Navigate to the backend folder**:
   ```bash
   cd backend
   ```

2. **Environment Setup**:
   Create a `.env` file if it does not exist (or copy from `.env.example`):
   ```bash
   cp .env.example .env
   ```
   Adjust `DATABASE_HOST` / `DATABASE_PORT` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` if your
   local PostgreSQL isn't using the defaults.

3. **Install Dependencies & Prepare the Database**:
   ```bash
   bin/setup
   ```
   This installs gems, runs `bin/rails db:prepare` (creates the databases and loads the schema —
   this app uses a primary database plus a separate Solid Queue `queue` database), and clears
   old logs/tempfiles. Pass `--reset` to drop and recreate the databases from scratch, or
   `--skip-server` to prepare without starting the dev server afterward.

4. **Seed Sample Data** (optional):
   ```bash
   bin/rails db:seed
   ```

5. **Run the Development Server**:
   ```bash
   bin/dev
   ```
   This starts both the Rails API (default: `http://localhost:3000`) and the Solid Queue worker
   (for hold-expiration and notification jobs) together. Use `bin/rails server` instead if you
   only need the API without background jobs.

### Running Tests

From inside the `backend/` folder:

```bash
bundle exec rspec
```

This runs the full model, request/API, and job suite.

### Code Linting

```bash
bin/rubocop
```

---

## Frontend

The frontend application is built using **Vue 3**, **Vite**, **TypeScript**, and **PrimeVue 4** (PrimeTek UI component suite, also referred to as PrimeVue / NG Prime).

### Tech Stack & Features
- **UI Library**: PrimeVue 4 (`primevue`, `@primeuix/themes` with the Aura theme preset, and `primeicons`).
- **Auto Component Import**: Managed with `@primevue/auto-import-resolver` and `unplugin-vue-components`.
- **Environment Variables**: Uses `.env` (`VITE_API_BASE_URL` for backend API configuration).
- **Routing**: `vue-router` configured with a home overview and an interactive PrimeVue component catalog at `/components`.
- **Theme Support**: Light mode by default with dynamic light/dark mode switcher.

---

### How to Run the Frontend (Post-Clone Guide)

Follow these steps once you have cloned the repository to set up and run the frontend:

1. **Navigate to the frontend folder**:
   ```bash
   cd frontend
   ```

2. **Environment Setup**:
   Create a `.env` file if it does not exist (or copy from `.env.example`):
   ```bash
   cp .env.example .env
   ```
   Verify that `VITE_API_BASE_URL` points to your running backend (default: `http://localhost:3000`).

3. **Install Dependencies**:
   ```bash
   npm install
   ```

4. **Run the Development Server**:
   ```bash
   npm run dev
   ```
   Access the web app at `http://localhost:5173`.

5. **Production Build & Type Checking**:
   ```bash
   npm run build
   ```

---

### Running Tests

Execute testing scripts inside the `frontend/` folder:

- **Unit & Component Tests** (Vitest):
  ```bash
  npm run test:unit
  ```

- **End-to-End (E2E) Tests** (Playwright):
  ```bash
  npm run test:e2e
  ```

- **Type Checking**:
  ```bash
  npm run type-check
  ```

- **Code Linting & Formatting**:
  ```bash
  npm run lint
  ```
