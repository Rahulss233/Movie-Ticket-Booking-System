# CineBook source-grounded audit and roadmap

## Findings from the existing source

- Stack: Java 17, Spring Boot 3.2.5, Maven, Spring Security, Spring Data JPA, MySQL.
- Frontend is a single-page app in `src/main/resources/static/app.js`, `index.html`, and `style.css`.
- Homepage already has a hero and movie rails; Top Rated is a placeholder because there is no ratings source.
- Search supports title/cast/genre/language and release status, but initially lacked location autocomplete and genuine ratings sorting.
- Location hierarchy is one self-referencing `locations` table (`STATE -> DISTRICT -> CITY`), not separate `states` and `districts` tables.
- `DataInitializer` seeds all 28 states and 8 Union Territories, but only a partial district/city set. It is not a complete national directory.
- Movie data has a single language string and global poster URL. It does not model separate audio editions or theatre-specific promotional posters.
- Booking uses `MockPaymentGateway` and `app.payment.mode=mock`. Payment attempts are recorded in `payments`; booking rows have commission/payable snapshots, but no full settlement batch workflow exists.
- Notifications are in-app messages with a read flag; rich categories, priority, deep links, per-category preferences and delivery retries are not implemented.
- Theatre status history, audit records, commission policy, show scheduling, seat holds, QR tickets and CSV exports already exist and should be preserved.

## Changes made in this update

1. Added `GET /api/public/locations/search?q=...` for typed location autocomplete.
2. Search page accepts state, district or city text, displays selectable matches, and filters movies to future scheduled shows at approved theatres within the selected location hierarchy.
3. Theatre Admin can propose a missing movie. The server forces `PENDING_REVIEW`; it stays out of the public catalogue and direct movie details until Super Admin reviews it.
4. Super Admin movie management reads the administrative catalogue, including pending records, and can edit status to publish, keep upcoming or archive.
5. Removed the Theatre Admin route that directly edits shared catalogue records; theatre users can propose instead of silently changing global metadata.
6. Added optional TMDB upcoming-movie import. Imported records are deduplicated by provider ID and always enter `PENDING_REVIEW`; the scheduled import is disabled by default. Super Admin has a manual sync action.
7. Added an admin payment-ledger view over recorded payment attempts. It is explicitly test-mode data, not a payout statement.
8. Release-date status promotion is persisted when catalogue records are queried.

## Remaining requirements and limitations

### Movie provider
- Configure `TMDB_API_KEY` and `TMDB_IMPORT_ENABLED=true` to enable the daily scheduled import. Manual sync requires `TMDB_API_KEY`.
- The current importer reads only the first page of upcoming movies in India. Runtime, certification, cast, genre names and regional language editions need reviewer verification or additional provider calls.
- TMDB states free API use is for non-commercial use with attribution; commercial use requires a separate written agreement. Confirm licensing before using this for a revenue-generating deployment. See TMDB's official FAQ and API terms.
- Import runs daily at 03:30 server time when enabled; it is not a guaranteed real-time feed.

### Locations
- All state/UT entries are seeded. Districts/cities remain partially seeded; the complete, current official district/city directory still needs to be imported and verified. Super Admin can add missing records manually.
- Autocomplete can only return locations present in the database.

### Payments and settlements
- Payments remain mock/test mode by design. The ledger shows attempts only.
- Settlement batches, payout authorisation, reconciliation, payout references, disputes and settlement state transitions remain to be implemented.

### Movie model and discovery
- Separate language/audio editions, subtitles and per-show language are not yet normalized into dedicated entities; the existing comma-separated language field remains for compatibility.
- Theatre-specific promotional poster overrides are not implemented; poster editing still changes the shared movie record for Super Admin. Theatre Admin can upload a poster when proposing a new movie.
- Customer ratings/reviews, moderation and genuine Top Rated rail are not implemented. Do not display fabricated scores.

### Notifications and dashboards
- Role-specific notification categories, priorities, deep links, per-item read state, delivery retries and preferences remain incomplete.
- Dashboards still need a complete role-specific operational redesign and usability review.

### Verification
- JavaScript syntax passed `node --check`.
- Maven tests could not run here because Maven Wrapper could not download Maven 3.9.9 from Maven Central. On Windows, run `mvnw.cmd test` from a Windows terminal (or `./mvnw test` in a compatible shell) from the project folder, or use an installed Maven distribution.
- Test against a backup/test database before changing an existing installation. Hibernate `ddl-auto=update` can add fields, but it is not a replacement for database migrations.

## Recommended next phases

1. Complete and verify the Indian district/city directory; add location list/edit/deactivate UI and duplicate/parent validation.
2. Normalize movie editions, show language/subtitles, external source metadata and theatre-specific promotional assets.
3. Add role-specific notification categories, priorities, deep links and separate task queues.
4. Add settlement entities and workflow while retaining mock payments.
5. Improve dashboards with actionable queues, mobile layout and keyboard accessibility.
6. Add integration tests for location filters, pending movie visibility, importer deduplication, payment-ledger permissions and theatre-role restrictions.
