TEAM CODE CHALLENGE
SeatForge
Limited-Capacity Workshop Booking and Waitlist Platform
IMPLEMENTATION WINDOW
July 29-31, 2026
TEAM SIZE
3 engineers
REQUIRED BACKEND
Ruby on Rails API
FRONTEND CHOICE
Vue or React


Build from scratch. Protect data integrity. Coordinate under pressure. Defend every important decision.
Challenge level: ADVANCED

1. Challenge Overview
Your team will design and build SeatForge, a small platform for publishing technical workshops and managing registrations for sessions with limited capacity. The product must handle temporary seat holds, confirmations, cancellations, waitlists, hold expiration, and seat promotion without overbooking.
This challenge is intentionally more demanding than a standard CRUD exercise. The main assessment is not visual polish: it is the team’s ability to model a non-trivial domain, protect consistency across multiple records, build maintainable Rails workflows, test critical behavior, organize the work, and explain the final solution.
Core assessment principle
A smaller solution that correctly protects capacity, state transitions, and data consistency is stronger than a broad interface with unreliable business behavior.


Success at a glance
Area
Expected result
Product
A usable workshop catalog and registration flow backed by a Rails JSON API.
Data integrity
No session may be overbooked, including near-concurrent registration attempts.
Lifecycle
Held, confirmed, waitlisted, cancelled, and expired registrations behave consistently.
Engineering
Transactions, locking, service-oriented workflow design, ActiveRecord queries, jobs, and tests are visible.
Team delivery
Planning, ownership, pull requests, reviews, checkpoints, and scope decisions are documented.
Individual ownership
Every engineer implements and tests at least one business-critical Rails endpoint.
Final activity
Live product demo, Rails code walkthrough, and individual technical defense.


2. Business Scenario
A technology community runs short workshops with a limited number of seats. Registrations are currently tracked in spreadsheets, which leads to duplicate entries, unclear availability, and occasional overbooking. Organizers also spend time manually moving people from a waitlist when seats become available.
SeatForge must provide a reliable first release that allows organizers and attendees to:
Publish workshops and scheduled sessions.
Browse upcoming sessions and view current seat availability.
Temporarily hold a seat before confirming a registration.
Join a waitlist when a session is full.
Confirm or cancel a registration.
Expire abandoned holds and promote the oldest eligible waitlist entry.
Review operational metrics through a small dashboard.
3. Delivery Window and Team Rules
Item
Requirement
Start
Wednesday, July 29, 2026.
Final submission
Monday, August 1st, 2026, at 9:00 AM.
Team size
Three engineers working in one repository.
Build approach
The repository, Rails application, frontend application, database, tests, seeds, and documentation must be created from scratch.
Scope change
A mandatory change request may be released on Thursday. The team must update its plan and document the impact.
Defense
The team presents after the implementation window. Each engineer must defend their own Rails contribution.


Mandatory individual contribution
Every engineer must own Rails behavior
Each team member must personally implement at least one business-critical backend endpoint in Ruby on Rails, including routing, controller behavior, domain/service logic, persistence, error handling, and automated request/API tests. Ownership must be visible in commits and pull requests.


No engineer may work exclusively on the frontend, documentation, or project coordination.
Each engineer must contribute to at least one model, migration, service, query, job, or other backend component beyond the controller.
Each engineer must review at least one meaningful pull request created by another team member.
Each engineer must be prepared to trace their endpoint from the HTTP request to the database and back to the JSON response.
4. Required Technology and Constraints
Layer
Required technology / expectation
Backend
Ruby 3.x and Ruby on Rails 7.x, preferably API mode.
Frontend
Vue 3 or React. JavaScript or TypeScript may be used.
Database
PostgreSQL is required because the solution must address transactional capacity control and locking.
Testing
RSpec or Minitest for backend model, service/job, and request/API tests.
API
Versioned REST-style JSON API under /api/v1.
Background work
ActiveJob or an equivalent Rails job abstraction for hold expiration and notifications.
Version control
Git repository with issues/tasks, feature branches, pull requests, meaningful commits, and peer review.


Explicit scope boundaries
Authentication and authorization are not required.
A real payment provider, email provider, SMS provider, or production deployment is not required.
The notification integration must be represented by a replaceable adapter or job, but it may log or persist a fake notification locally.
Availability must be derived from registration state; do not store a manually editable available_seats field.
The Rails backend is the source of truth for capacity and state transitions. Frontend checks alone are not acceptable.

5. Domain Model
The following entities and fields are the minimum expected domain. Teams may add fields when the reason is documented.
Entity
Minimum fields
Key relationships
Workshop
title, description, topic, active
has_many sessions
Session
starts_at, ends_at, capacity, status
belongs_to workshop; has_many registrations
Attendee
name, email
has_many registrations
Registration
status, hold_expires_at, confirmed_at, cancelled_at
belongs_to session and attendee


Allowed statuses
Entity
Allowed values
Session
scheduled, cancelled, completed
Registration
held, confirmed, waitlisted, cancelled, expired


Minimum data rules
Workshop: title and topic are required.
Session: capacity must be greater than zero; starts_at must be earlier than ends_at; both values must be valid ISO 8601 timestamps.
Attendee: name and email are required; email must be unique without case sensitivity.
Registration: must belong to one attendee and one session; an attendee may not have more than one active registration for the same session.
Referential behavior: teams must explicitly decide and document deletion or archival behavior for records with dependencies.
6. Mandatory Registration Lifecycle
The lifecycle below is the central technical challenge. It must be implemented in Rails and protected by automated tests.
6.1 Create a registration
Reject the request when the session is cancelled, completed, or has already started.
Reject a duplicate active registration for the same attendee and session.
Reject the registration when the attendee already has a held or confirmed registration that overlaps the requested session time.
Evaluate capacity inside a database transaction and use an explicit locking or equivalent consistency strategy.
When a seat is available, create a held registration with hold_expires_at set to ten minutes after creation.
When the session is full, create a waitlisted registration instead of failing the request.
6.2 Confirm a held registration
Only a held registration that has not expired may be confirmed.
Confirmation sets confirmed_at and clears hold_expires_at.
Repeated confirmation of an already confirmed registration must be safe and return a consistent result rather than creating duplicate effects.
A successful confirmation must enqueue a notification job using a replaceable notification adapter.
6.3 Cancel a registration
Held, confirmed, and waitlisted registrations may be cancelled.
Cancellation records cancelled_at and must be idempotent.
When a held or confirmed seat is released, the oldest eligible waitlisted registration must be promoted to held and receive a new ten-minute hold.
Waitlist promotion must be part of the same consistent workflow and must enqueue a notification job.
6.4 Expire abandoned holds
A Rails job or documented task must find held registrations whose hold_expires_at is in the past.
Expired registrations change to expired and no longer consume capacity.
Every released seat must trigger promotion of the oldest eligible waitlisted registration.
The expiration process must be safe to execute more than once.
Data-integrity requirement
The implementation must prevent active held + confirmed registrations from exceeding session capacity. The team must explain how transactions, locks, constraints, or other safeguards protect this invariant.


7. Mandatory API
Use JSON requests and responses under the base path /api/v1. Equivalent endpoint naming is acceptable only when it is clearly documented and preserves the required behavior.
Method
Endpoint
Required behavior
GET
/api/v1/workshops
List active workshops with upcoming-session summary.
POST
/api/v1/workshops
Create a workshop.
GET
/api/v1/workshops/:id
Return workshop details and upcoming sessions.
POST
/api/v1/workshops/:workshop_id/sessions
Create a scheduled session.
GET
/api/v1/sessions
List sessions with filters, sorting, and pagination.
GET
/api/v1/sessions/:id
Return session details, workshop, availability, and relevant registration counts.
GET
/api/v1/sessions/:id/availability
Return capacity, held seats, confirmed seats, waitlist size, and available seats.
POST
/api/v1/sessions/:session_id/registrations
Create a held or waitlisted registration using attendee identity.
POST
/api/v1/registrations/:id/confirm
Confirm an eligible held registration.
POST
/api/v1/registrations/:id/cancel
Cancel a registration and promote the waitlist when necessary.
GET
/api/v1/attendees/:attendee_id/registrations
List an attendee’s registrations and statuses.
GET
/api/v1/dashboard
Return operational metrics.


Required session list capabilities
Filter by date range.
Filter by workshop topic.
Filter to sessions with available seats.
Sort by start time and optionally by available seats.
Paginate results with a documented maximum page size.
GET /api/v1/sessions?from=2026-08-01T00:00:00Z&to=2026-08-07T23:59:59Z
GET /api/v1/sessions?topic=rails&available=true&sort=starts_at&page=1&per_page=10
Required dashboard metrics
Upcoming scheduled sessions.
Total held registrations.
Total confirmed registrations.
Total waitlisted registrations.
Expired holds during the current day.
Sessions that are full.
Top three sessions by waitlist size.
Error contract
Errors must use appropriate status codes and a consistent body. Conflict situations such as duplicate registration or unavailable transitions should be distinguishable from validation errors.
{
  "error": {
    "code": "registration_conflict",
    "message": "The attendee already has an active registration for this session.",
    "details": []
  }
}

8. Frontend Requirements - Vue or React
The interface must make the lifecycle understandable. Advanced styling is welcome, but correctness, state visibility, and clear API integration are more important than decorative design.
View
Minimum behavior
Workshop catalog
Display active workshops and upcoming sessions. Support date/topic/availability filters.
Session detail
Display schedule, capacity, available seats, held/confirmed counts, and waitlist size.
Registration flow
Collect attendee name/email, create a registration, and clearly show held or waitlisted status.
Hold confirmation
Allow confirmation before expiration and show the backend-provided hold expiration time.
My registrations
Find and display an attendee’s registrations with actions allowed by current status.
Operations dashboard
Display the required metrics and top waitlisted sessions.


Frontend quality expectations
Display loading, empty, success, and error states.
Do not hide backend conflicts or replace them with generic messages.
Refresh or reconcile the displayed availability after registration, confirmation, cancellation, and expiration-related actions.
Keep API access organized outside of large page components.
A countdown may be displayed for held seats, but the Rails timestamp remains the source of truth.
The application must remain usable after a browser refresh using persisted backend data.
9. Advanced Rails Engineering Requirements
The following requirements distinguish this challenge from a basic CRUD implementation and are mandatory unless explicitly marked optional.
Requirement
Expectation
Transactional workflow
Registration creation, cancellation, expiration, and promotion must protect multi-record consistency.
Concurrency strategy
Use row locking, advisory locking, constraints, or another justified strategy to prevent overbooking.
Service-oriented design
At least one business workflow must be extracted from controllers into a service/command object or equivalent domain abstraction.
Query organization
Session search and dashboard calculations must use clear scopes, query objects, or well-structured ActiveRecord logic.
Background jobs
Hold expiration and notifications must use ActiveJob or an equivalent Rails job abstraction.
Integration boundary
The notification implementation must be replaceable and testable without real credentials.
Performance awareness
Avoid obvious N+1 queries in list/detail responses and explain the chosen eager-loading strategy.
Idempotency
Confirmation, cancellation, and expiration behavior must tolerate repeated execution safely.
Time handling
Persist and exchange timestamps consistently; document the use of UTC and ISO 8601.


Design freedom
The challenge does not prescribe a gem or pattern for state transitions, serialization, pagination, or service objects. The team should select an approach it can justify, test, and maintain. Unnecessary abstraction will not receive extra credit.
10. Automated Testing Requirements
The backend suite must run with one documented command and cover both successful and unsuccessful paths. Tests should protect business behavior rather than merely execute lines.
Test category
Mandatory coverage
Model tests
Validations, associations, uniqueness, session time rules, and status constraints.
Service/domain tests
Seat allocation, full-session waitlisting, overlap rejection, confirmation, cancellation, expiration, and waitlist promotion.
Request/API tests
Required endpoints, status codes, JSON structure, filters, pagination, invalid transitions, and conflicts.
Job tests
Expired holds are processed safely; confirmation/promotion notifications are enqueued.
Capacity protection
At least one automated test demonstrates that active registrations cannot exceed capacity under repeated or near-concurrent attempts.
Individual endpoint tests
Each engineer adds request/API tests for the endpoint they personally own.


Minimum testing baseline
At least 10 model/service/job examples.
At least 10 request/API examples.
Every critical lifecycle rule covered by at least one test.
A deterministic test strategy for time-dependent behavior, such as travel helpers or injected clock behavior.
A documented command that passes from a clean setup.
Quality over percentage
A coverage percentage alone is not accepted as evidence of quality. Reviewers will inspect whether tests protect the invariants that matter.



11. Repository, Planning, and Collaboration
The team is evaluated on how it delivers, not only on the final code. The repository must make the team’s decisions and contribution history understandable.
Required repository setup
seatforge/
├── backend/
├── frontend/
├── README.md
├── DECISIONS.md
├── .gitignore
└── .env.example
Create the repository and applications from scratch.
Use a task board, issues, or a documented task table before significant implementation begins.
Identify dependencies and integration points, not only isolated tasks.
Use feature branches and pull requests for meaningful changes.
Each engineer must complete at least one peer review with a useful comment, question, or approval rationale.
Keep the main branch in a reviewable and runnable condition.
Do not commit credentials, local environment files, or generated dependency folders.
Required ownership matrix
Engineer
Primary scope
Owned Rails endpoint(s)
Reviewed PR
Engineer 1
Defined by team
Complete in README
PR link / reference
Engineer 2
Defined by team
Complete in README
PR link / reference
Engineer 3
Defined by team
Complete in README
PR link / reference


Checkpoint evidence
Checkpoint
Evidence expected
Wednesday
Repository, initial README, domain sketch, task breakdown, owners, Rails/Frontend setup, first migration or endpoint PR.
Thursday
Core lifecycle working in Rails, tests running, frontend integration started, PR reviews visible, change request impact documented.
Friday
Stable main branch, clean-clone validation, completed documentation, known limitations, demo plan, and ownership matrix.


12. Required Documentation
README.md
Product overview and business problem.
Technology versions and prerequisites.
Installation, database setup, seed setup, and environment variables.
Commands to start the Rails API and frontend.
Command to execute the complete backend test suite.
API endpoint summary and example requests.
Domain relationship diagram or clear textual model description.
Explanation of the capacity/concurrency strategy.
Explanation of hold expiration and notification processing.
Team plan, ownership matrix, and contribution summary.
Known limitations, unfinished items, and future improvements.
Brief disclosure of significant AI-assisted work, when applicable.
DECISIONS.md
Document at least four meaningful technical decisions. For each decision, include:
The context or problem.
The selected decision.
Alternatives considered.
Why the approach was selected.
Trade-offs, risks, or limitations.
At least two decisions must address the registration lifecycle, data consistency, locking, jobs, or time handling.
13. Seed Data and Reproducibility
At least 4 workshops across different topics.
At least 8 upcoming sessions with different capacities and schedules.
At least 8 attendees.
A mix of held, confirmed, waitlisted, cancelled, and expired registrations.
At least one full session and one session with a visible waitlist.
A deterministic way to reproduce demo scenarios without manual database editing.
Clean-clone requirement
A reviewer must be able to clone the repository, follow the README, load the database, run the tests, and explore the main flows without direct assistance from the team.


14. Final Submission
Repository URL and final main-branch commit hash.
Complete Rails backend and Vue/React frontend source code.
README.md and DECISIONS.md.
Database migrations and seed data.
Passing backend test suite.
Planning board, issues, or task breakdown evidence.
Pull requests and peer-review evidence.
Final ownership matrix.
Known limitations and unfinished requirements.
15. Final Demo and Technical Defense
The final defense is mandatory and verifies both team delivery and individual understanding. The team should prepare a concise narrative rather than three disconnected presentations.
Activity
Recommended time
Expectation
Team overview
5 minutes
Explain the product, architecture, plan, scope decisions, and contribution model.
Live demo
15 minutes
Demonstrate seat hold, waitlisting, confirmation, cancellation, promotion, expiration, filters, and dashboard.
Rails walkthrough
10 minutes
Show routes, services, transactions/locks, models, jobs, queries, and tests.
Individual defense
6-8 minutes each
Each engineer defends their endpoint, tests, decisions, reviewed PR, and lessons learned.
Reviewer questions
As needed
Trace behavior, discuss trade-offs, and explain unfinished scope honestly.


Each engineer must be prepared to explain
The endpoint they personally implemented and the complete request flow.
The Rails components they changed outside the controller.
The tests they added and the production failure each test protects against.
How the team prevents overbooking and race conditions.
How idempotency is handled for repeated actions.
One important trade-off or shortcut made because of the deadline.
One PR from another engineer that they reviewed and what they evaluated.
How the team responded to blockers or the Thursday change request.

16. Evaluation Rubric
Assessment area
Weight
What reviewers will look for
Functional lifecycle
20%
Required flows work and status transitions are correct.
Rails/API design
15%
Routes, controllers, service boundaries, JSON contracts, errors, and Rails conventions.
Data integrity and concurrency
15%
Transactions, locking/constraints, no overbooking, safe promotions, and idempotency.
ActiveRecord and domain modeling
10%
Migrations, associations, validations, queries, time handling, and derived availability.
Automated testing and quality
15%
Critical behavior, edge cases, job tests, request tests, capacity protection, and stable suite.
Frontend integration
10%
Clear lifecycle, correct API integration, state/error handling, and usable flows.
Team organization and collaboration
10%
Planning, balanced ownership, commits, pull requests, reviews, checkpoints, and scope control.
Demo and individual defense
5%
Clarity, ownership, technical understanding, and honest trade-off discussion.


Individual scoring note
The product receives a shared team score. An individual score may be adjusted when commits, pull requests, automated tests, backend ownership, or the final defense do not demonstrate the required personal contribution.
17. Definition of Done
Done
Item
Acceptance condition
☐
Repository
Created from scratch with clear planning, commit, PR, and review history.
☐
Setup
A reviewer can run the complete solution by following the README.
☐
Domain
Required entities, relationships, validations, and statuses are implemented.
☐
Lifecycle
Hold, confirm, waitlist, cancel, expire, and promote behavior works.
☐
Capacity
The system prevents overbooking and the strategy is tested and documented.
☐
Individual Rails ownership
Each engineer implemented and tested at least one business-critical Rails endpoint.
☐
Jobs/integration
Expiration and fake notification processing are implemented and testable.
☐
Frontend
Vue or React supports the required user flows and displays backend states.
☐
Tests
The documented backend test command passes.
☐
Documentation
README.md and DECISIONS.md are complete.
☐
Defense
The team can demonstrate and explain the final solution.


18. Optional Enhancements
Optional work may strengthen the solution only after mandatory behavior is reliable:
Docker Compose for PostgreSQL, Rails, and frontend setup.
GitHub Actions or another CI workflow.
OpenAPI/Swagger documentation and RuboCop quality checks.
SimpleCov interpreted alongside meaningful tests.
Frontend component or integration tests.
Real-time availability updates or a structured transition audit history.
Organizer controls, additional lifecycle features, or production deployment.
19. Use of Documentation and AI-Assisted Tools
Documentation, search engines, and AI-assisted tools may be used.
The team remains responsible for reviewing, adapting, and testing all submitted code.
Every engineer must be able to explain and modify the code they claim as their contribution.
Significant AI assistance must be disclosed briefly in the README.
Inability to explain submitted code may reduce the individual assessment result.
Final reminder: Do not optimize for the largest feature list. Optimize for a reliable lifecycle, visible team ownership, meaningful tests, and decisions you can defend.
