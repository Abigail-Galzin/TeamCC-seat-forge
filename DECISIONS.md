# Technical Decisions

This document records the meaningful technical decisions behind SeatForge: the context that
prompted each one, the alternatives considered, why the chosen approach won, and the trade-offs
we accepted.

## 1. Frontend framework: Vue 3 (Composition API) over React and Angular

**Context.** The challenge allowed Vue or React for the frontend. The UI is state-heavy rather
than visually complex: seat counts, hold countdowns, and registration statuses (held / confirmed
/ waitlisted / cancelled / expired) all need to re-render consistently as backend state changes,
and the team had three days to build it.

**Decision.** Vue 3 with the Composition API, TypeScript, and Vite.

**Alternatives considered.**
- React (function components + hooks).
- Angular — not offered by the requirements (Vue or React only), and its DI/module ceremony adds
  setup overhead that doesn't pay off on a 3-day build.

**Why selected.** Vue's single-file components keep template, script, and style together, so
reviewing or changing a view doesn't require jumping across files under time pressure. Its
built-in reactivity (`ref`/`reactive`/`computed`) expresses derived, frequently-refreshed state
(available seats, hold countdowns) with less ceremony than React's `useState`/`useEffect`
dependency tracking. Vite's dev server start-up and HMR are fast, which mattered for iteration
speed across a 3-person team working in parallel.

**Trade-offs / risks.** Smaller ecosystem and hiring pool than React. The team commits to
Vue-specific idioms (Composition API, SFCs) that a contributor coming from React would need to
learn before contributing productively.

## 2. Component library: PrimeVue 4 over Vuetify, Quasar, and headless UI

**Context.** The product needs a lot of CRUD-shaped UI quickly — paginated/sortable tables,
forms, dialogs, status tags/badges — without spending scarce engineering time hand-building and
styling each component, while still looking presentable for the live demo.

**Decision.** PrimeVue 4 (`primevue`, `@primeuix/themes` with the Aura preset, `primeicons`),
with components auto-imported via `unplugin-vue-components` /
`@primevue/auto-import-resolver`.

**Alternatives considered.**
- Vuetify — Material Design components, but more opinionated theming to fight against for a
  non-Material look.
- Quasar — a full application framework (CLI, build system, mobile/desktop targets), more than
  this project needs.
- Headless UI + Tailwind (or plain HTML/CSS) — maximum visual control, but every component's
  behavior, keyboard handling, and accessibility would need to be built from scratch, which is
  too slow for the timeline.

**Why selected.** PrimeVue ships the exact primitives this app needed out of the box —
`DataTable` (sortable/paginated session and attendee lists), `Tag`/`Badge` (registration and
session status), `Dialog`, `Select`, `Checkbox` — cutting UI implementation time substantially.
The Aura theme gives a professional look with almost no custom CSS, and the auto-import resolver
removes per-component import boilerplate so screens stay focused on business logic rather than
markup plumbing.

**Trade-offs / risks.** Larger bundle size than a headless-only approach. The visual identity is
recognizably "PrimeVue," not fully custom. Restyling later means learning PrimeVue's design-token
system rather than writing plain CSS.

## 3. Database: PostgreSQL

**Context.** The requirements mandate PostgreSQL specifically because of the transactional
capacity-control and locking needs of the registration lifecycle: preventing a session from
being overbooked under near-concurrent registration attempts.

**Decision.** PostgreSQL for the primary database, and for Solid Queue's job database
(`config/database.yml`'s `queue` connection), instead of introducing Redis.

**Alternatives considered.**
- MySQL — also supports row-level locking, but Postgres was the explicit requirement and has
  better-tested `SELECT ... FOR UPDATE` semantics under Rails/ActiveRecord.
- SQLite — no real concurrent row locking, which is disqualifying for the overbooking-prevention
  requirement.
- A NoSQL store — no multi-row transactional guarantees, which the seat/waitlist invariant
  depends on.

**Why selected.** Beyond being required, Postgres's row-level locking (`lock!` / `with_lock`) is
used directly in `Registration#register`, `Registration#cancel`, `Registration#expire_hold`, and
`Session#cancel` to serialize capacity checks and waitlist promotion — this is the mechanism that
keeps `held + confirmed` registrations from exceeding `capacity`. Running Solid Queue against the
same Postgres instance (rather than adding Redis/Sidekiq) kept the local setup to a single
datastore during a 3-day build.

**Trade-offs / risks.** Requires a running Postgres instance locally (vs. SQLite's zero-setup),
which adds a setup step documented in the README. Sharing Postgres between the primary and queue
databases is simple to operate at this scale, but wouldn't scale job throughput as well as a
dedicated queue backend in a production deployment.

## 4. Backend framework: Ruby on Rails (API mode)

**Context.** Ruby on Rails was a fixed requirement. The decision that remained was how to use it:
full Rails vs. API-only mode, and which pieces of "Rails-the-framework" to lean on for the
hardest part of the domain — protecting the capacity invariant under concurrency.

**Decision.** Rails 7.2 in `--api` mode, using ActiveRecord for persistence and locking,
ActiveJob (Solid Queue adapter) for background work, and RSpec for tests.

**Alternatives considered.**
- Full (non-API) Rails — unnecessary, since there are no server-rendered views; the Vue SPA
  consumes a pure JSON API.
- Sidekiq + Redis for background jobs — works well, but Solid Queue (Postgres-backed) avoids
  standing up a second datastore for a 3-day build (see Decision 3).

**Why selected.** Rails' conventions — migrations, validations, `enum`, associations,
transactions, pessimistic locking — map directly onto the hardest requirement in the brief:
serializing capacity checks across concurrent requests without overbooking. That logic lives in
`Registration.register`/`#confirm`/`#cancel`/`#expire_hold` and `Session#cancel`, each wrapped in
a transaction with an explicit row lock. RSpec's `expect { }.to change { }` style was a good fit
for asserting on state transitions (held → confirmed → cancelled, waitlist promotion, etc.).

**Trade-offs / risks.** Rails' "batteries included" surface area is large for a 3-day build; some
time went into framework/tooling setup (Solid Queue, Pagy) rather than only business logic.
API-only mode means there's no server-rendered view layer, so the JSON contract between backend
and frontend needs discipline — handled here via a consistent response envelope
(`Response::ResponseData` / `Response::ResponseError`) shared across controllers.

## 5. Authentication & authorization: opaque bearer tokens + single `User` table with roles

**Context.** The API was greenfield for security: no user model, no auth gems, and every endpoint —
including admin write operations (create/update workshops, create/cancel sessions, confirm/cancel
registrations) — was public. The frontend is a Vue SPA backed by an API-only Rails app
(`config.api_only = true`, so no cookie/session middleware). We needed to protect admin operations,
add self-service registration for attendees, and keep the change small enough to land in a few
days.

**Decision.**
- **Identity:** a single `users` table (`email`, `name`, `password_digest`, timestamps) with a
  `role` enum (`admin | attendee`). Attendee accounts carry an optional `belongs_to :attendee`,
  linking the login identity to the existing `Attendee` record that registrations hang off.
  Passwords are hashed with `bcrypt` (`has_secure_password`). Admins are seeded via
  `db:seeds`/rake with a password from the environment — there is no public admin signup. Attendee
  accounts are created at first seat reservation: sign up with email/password creates the `User`
  and links (or creates) the matching `Attendee`.
- **Authentication:** opaque bearer tokens, not JWT. A dedicated `auth_tokens` table stores a
  SHA-256 digest of the token (never the plaintext), the owning `user_id`, `expires_at`, and
  `revoked_at`. Login (`POST /api/v1/auth/login`) issues a token; logout revokes it; the client
  sends it as `Authorization: Bearer <token>`. A new `Api::V1::BaseController` provides
  `authenticate_user!` / `authenticate_admin!` filters, returning 401/403 in the existing
  `Response::ResponseError` envelope so the frontend's error parser needs no changes.
- **Authorization:** role-based filters plus ownership checks, no authorization gem. Attendees may
  only read their own registration history; registration **confirm/cancel is admin-only** (per team
  decision); attendees cannot mutate registrations from their own account.

**Endpoint protection matrix.**

| Public (no auth) | Attendee only | Admin only |
|---|---|---|
| GET workshops, workshop/:id | POST registration (reserve) | POST/PATCH workshops, POST sessions |
| GET sessions, session/:id, availability | GET attendees/:id/registrations (own) | POST session/:id/cancel, POST registrations confirm/cancel |
| GET dashboard overview | | GET registrations index, attendees index/search, per-workshop dashboard |

**Frontend integration.** A Pinia `auth` store (token + user, persisted to `localStorage`), an
axios request interceptor injecting the `Authorization` header, and a 401 response interceptor that
clears the session and redirects to `/login`. Vue Router `beforeEach` guards read route
`meta: { requiresAuth, roles }`; the admin navigation link is shown only to `admin` users.

**Alternatives considered.**
- **JWT bearer tokens** — stateless (no DB lookup per request), but requires managing a signing
  secret and a revocation strategy (blacklist/expiry) for logout and token invalidation. For a
  single-instance, short-lived build, opaque tokens avoid that machinery entirely.
- **Cookie/session auth** — idiomatic for server-rendered Rails but requires re-enabling the
  session/cookie middleware in an API-only app and fighting CORS/CSRF for an SPA.
- **Separate admin table** — cleaner separation, but duplicates auth plumbing; two roles on one
  table is simpler here.
- **Authorization gem (Pundit/CanCanCan)** — arguably nicer at scale, but 6 controllers and 2 roles
  are served by simple filters + ownership checks without adding a dependency.

**Trade-offs / risks.** Opaque tokens mean one DB query per authenticated request (token lookup by
digest); irrelevant at this scale, but a point in JWT's favor later. A single `User` table couples
admin and attendee identities, so a future "admin" needs an attendee-less user (handled via the
optional association). Token expiry/rotation and password policy are kept minimal (default bcrypt
cost, reasonable `expires_at`) — acceptable for a demo build, must be hardened before real
deployment. `request.params` says `sessions` is already the workshop-session feature name, so the
auth routes live under `/api/v1/auth/*` and token state lives in `AuthToken`, avoiding any naming
collision with `Session`.
