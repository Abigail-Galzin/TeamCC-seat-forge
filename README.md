# TeamCC-seat-forge

SeatForge project repository containing backend and frontend services.

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
