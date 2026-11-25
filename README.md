# CineBook - Multi-Theatre Movie Ticket Booking (Stage 1)

Frontend (HTML/CSS/JS) -> REST API -> Spring Boot -> JPA/Hibernate -> MySQL

## Run it (Windows + VS Code + XAMPP)
1. Needs only **JDK 17+** (check: `java -version`). Maven is NOT required: the project ships `mvnw.cmd`.
2. XAMPP Control Panel -> **Start MySQL** (Apache not needed). Default root user with empty password is already configured. If you set a root password: `$env:DB_PASSWORD="yourpass"`.
3. In VS Code open this folder (the one with `pom.xml`), then either:
   * press **F5** (Run CineBook), or
   * run in the terminal: `.\mvnw.cmd spring-boot:run`, or double-click `run.bat`.
4. Open http://localhost:8080 and log in as `admin@moviebooking.local` / `Admin@12345`.
5. Tests: `.\mvnw.cmd test` (in-memory H2, no XAMPP needed).

The database `moviebooking` is created automatically. Restarts never delete data.

## End-to-end demo (about 5 minutes)
1. Login as Super Admin -> **Movies** -> add a movie with status ACTIVE.
2. Log out -> **Register theatre** (IFSC format `HDFC0001234`, future licence date). Status: PENDING_VERIFICATION.
3. Login as Super Admin -> **Theatres** -> START REVIEW -> APPROVE (try REQUEST CHANGES to see the correction loop). Optionally **Set rate** (theatre) and screen rates under *Screens & history*.
4. Login as the theatre owner -> **Screens** -> create a screen (seats are generated) -> **Shows** -> schedule a show in the future.
5. Sign up as a customer -> pick the theatre's city -> open the movie -> choose a show -> pick seats -> hold -> pay (**mock**) -> e-ticket. Try *simulate failed payment*, and cancelling under **My bookings**.
6. Super Admin dashboard now shows real figures: gross sales, collected, refunds, commission, theatre payable.

## Package layout (`com.moviebooking`)
`controller` thin REST layer - `service` business rules and transactions - `repository` Spring Data JPA - `entity` + `enums` - `dto` validated records - `security` - `config` - `exception` central handler.

OOP in use: abstract `BaseEntity` (inheritance), `CommissionPolicy` and `PaymentGateway` interfaces with swappable implementations (polymorphism/abstraction), `TheatreAction` enum state machine, encapsulated entities and immutable DTO records, DI throughout.

## API summary (test with Postman; log in first, the session cookie is reused)
| Area | Endpoints |
|---|---|
| Auth | `POST /api/auth/register`, `/register-theatre`, `/login`, `/logout`, `GET /api/auth/me` |
| Public | `GET /api/public/locations?parentId=`, `/movies?q=&language=&genre=&status=`, `/movies/{id}`, `/movies/{id}/shows?cityId=&date=`, `/shows/{id}/seats` |
| Customer | `POST /api/customer/bookings/hold`, `/bookings/{ref}/pay`, `/bookings/{ref}/cancel`, `GET /bookings` |
| Theatre admin | `GET/PUT /api/theatre/me`, `GET /history`, `GET/POST /screens`, `GET/POST /shows`, `POST /shows/{id}/cancel`, `GET /bookings` |
| Super admin | `GET /api/admin/dashboard`, `/theatres?status=&q=`, `POST /theatres/{id}/status`, `PUT /theatres/{id}/commission`, `PUT /screens/{id}/commission`, `POST /movies`, `POST /locations`, `GET /users`, `POST /users/{id}/active` |
| Notifications | `GET /api/notifications`, `/unread-count`, `POST /read` |

## Business rules implemented
* **Seat safety**: per-show inventory (`show_seats`), `SELECT ... FOR UPDATE` row locks, `@Version`, hold expiry (5 min, scheduler + lazy check), revalidation before payment.
* **Overlap protection**: show end = start + duration + buffer; overlapping shows on a screen are rejected.
* **Commission**: screen rate > theatre rate > platform default. Basis = ticket amount (no taxes/fees exist yet). Rate, basis, commission and theatre payable are frozen on the booking at payment. On cancellation, commission is recalculated only on the retained amount. Rate changes are written to the audit log (admin, old, new, time).
* **Cancellation policy** (configurable): >=24h before show 100% refund, >=4h 50%, otherwise not allowed.
* **Payments**: **mock/test mode only**, clearly labelled. Idempotency key is UNIQUE, so duplicate callbacks cannot charge twice. Refunds are recorded as PENDING; no real refund is claimed.
* **Security**: BCrypt, server-side role checks per URL prefix, ownership derived from the session (a theatre admin can only touch their own theatre), role never accepted from requests, HttpOnly SameSite cookie, validation and central error handling.

## Honest status and known gaps (next stages)
* **This code was written without being compiled or run in my environment** (no JDK compiler or Maven repository access). Expect to fix a few typos on first `mvn test`; paste any error and I will fix it immediately.
* Not yet built: theatre document/photo upload (secure storage), real payment gateway, settlement batches and reconciliation, reports with CSV export, password reset, complaint/support tickets, licence-expiry alerts, theatre staff accounts, show-level admin booking search with refunds processing, Flyway migrations, CSRF tokens, rate limiting.
* One theatre per owner account in Stage 1.


## CineBook discovery UI updates (October 2026)
- Reworked the application shell into a dark streaming-style layout with a hover/focus expandable left sidebar.
- Homepage now shows a cinematic feature panel and horizontal rails for Latest Releases, Now Showing, Coming Soon, and Explore Movies. The home page no longer has a permanent search bar or location picker.
- Search is its own sidebar page and supports title/cast/description/genre/language keyword search, language and genre filters, release status, release year, and newest/oldest sorting.
- Movie language field accepts comma-separated values (for example `Tamil, Telugu, Hindi`); language filtering now matches within that field.
- Super Admin and Theatre Admin movie forms accept a poster URL or image upload (JPG/PNG/WebP, max 5 MB). Uploads are stored locally in `./uploads/posters` and served under `/uploads/posters/`.
- Startup seeds all 28 states and 8 Union Territories and selected district/city records idempotently. Super Admin can add more locations from **Locations**; remaining districts and cities must be added there before theatre registration in those areas can use them.

## Known limitations that still need a real integration
- The **Top Rated** section intentionally does not invent ratings. The project has no verified customer-rating/review system or external ratings provider yet.
- New-release metadata (posters, cast, descriptions) is not automatically imported. This requires selecting and configuring a licensed movie metadata API.
- Theatre Admin poster upload currently updates the shared movie catalogue poster through the existing movie-edit API. A separate per-theatre poster override and approval workflow is not implemented yet.
- Payment flow remains a test/simulated gateway; connect a real payment provider before production.
- Location seed includes the complete state/UT list plus starter districts for selected states/UTs, not a verified exhaustive current district-and-city directory. Add the remaining entries through Super Admin Locations or load a verified data file.
- Poster files are stored on the local filesystem, suitable for local development only. Production should use persistent object storage/CDN and image scanning.

## Run
Start MySQL in XAMPP, then from this folder run `mvnw.cmd spring-boot:run` in PowerShell. Open `http://localhost:8080`. Keep the terminal open while using the site. If Maven Wrapper needs its distribution and the network is unavailable, it cannot download Maven until connectivity is restored.

## Optional movie metadata import (Super Admin review required)

The project includes an optional TMDB upcoming-movie import. It is disabled unless configured. Set these environment variables before starting Spring Boot:

- `TMDB_API_KEY` — your TMDB API key.
- `TMDB_IMPORT_ENABLED=true` — enables the daily scheduled import (03:30 server time).

Super Admin can also use **Manage Movies → Import upcoming movies** to trigger a manual sync after the API key is configured. Imported records are always stored as `PENDING_REVIEW`; they are not published to customers until Super Admin reviews them. The current importer reads the first page of TMDB's India upcoming-movies endpoint and does not guarantee complete regional-release coverage. Review imported runtime, genres, cast, certification, languages and dates before publishing.

**Licensing:** TMDB's published FAQ says free API use is for non-commercial applications with attribution; commercial use requires a separate written agreement. Check the current [TMDB FAQ](https://developer.themoviedb.org/docs/faq) and [API terms](https://www.themoviedb.org/api-terms-of-use) before any revenue-generating deployment. Never commit API keys to source control.

## Location search

The public movie search page has a location autocomplete. It searches state, district and city entries present in the `locations` table, then filters movies to those with future scheduled shows at approved theatres in that selected location or its descendants. The initializer currently seeds all state/UT names and a partial district/city list; add or import the remaining verified official locations before treating this as a complete India directory.

## Payment ledger

Super Admin Reports includes a read-only view of recorded payment attempts. Payments intentionally remain in mock/test mode. This is not a settlement or payout system; do not treat it as evidence of real money collected or transferred.


## Theatre console update (November 2026)
* **Dashboard**: today's shows, bookings, revenue and seat occupancy, upcoming shows, and alerts (pending refunds, open complaints). "Today" means shows playing today.
* **Shows** has two tabs: *Create shows* and *Edit existing shows*. A show's movie, screen, time and prices can be edited until someone books it (a screen change rebuilds the seat inventory and carries prices over by section name). A movie's run can be extended from the Edit tab.
* **Movies > History**: every movie screened per screen with from/to dates (`GET /api/theatre/screen-history`), plus the old add/remove log.
* **Booking window**: each theatre chooses 4-7 days (`PUT /api/theatre/booking-window`, default 7). Customers see real dates from `GET /api/public/movies/{id}/booking-dates?locationId=`; the window slides forward every day and stops at the run's end date. Holds outside the window are refused by the server.
* Not compiled in the authoring environment: run `.\mvnw.cmd test` first (new test: `BookingWindowTest`).
