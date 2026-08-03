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
