# Time Log

Time spent in each Claude Code conversation, from its first message to its last (WIB). When conversations overlap, the overlapping time is counted once in the total. Time spent outside these conversations is not included.

| # | Date | Time | Duration | Work |
|---|---|---|---|---|
| 1 | 2026-09-25 | 19:15–19:30 | 16 min | Data structure: class_subjects, trial_classes |
| 2 | 2026-09-25 | 19:23–19:27 | 4 min | RSpec + FactoryBot setup (ran alongside #1) |
| 3 | 2026-09-25 | 19:32–19:37 | 5 min | parents and students tables |
| 4 | 2026-09-25 | 19:45–19:53 | 9 min | bookings table, trial class price, time log |
| 5 | 2026-09-25 | 23:04–23:09 | 5 min | payment_attempts design and table |
| 6 | 2026-09-25 | 23:12–23:14 | 2 min | admins table |
| 7 | 2026-09-25 | 23:21–23:40 | 19 min | App shell: navbar, sign in/up/out stubs, fake OTP sign in, parent/admin seeds, parent sign up |
| 8 | 2026-09-25 | 23:44–23:54 | 10 min | Home page trial class list grouped by subject, Math/Science seeds, blank checkout page, seats left |
| 9 | 2026-09-26 | 00:00–00:23 | 23 min | Checkout page, booking submission (seat lock, duplicate/full checks, child picker), blank pay page |
| 10 | 2026-09-26 | 00:28–00:33 | 5 min | Pay page UI: seat hold countdown, card form with test card hints |
| 11 | 2026-09-26 | 00:36–00:48 | 12 min | MockPaymentGateway PORO, pay a held seat (retry, idempotency key, expired hold), booking status page |
| 12 | 2026-09-26 | 00:53–00:56 | 3 min | Checkout shows "Sorry, class is fully booked" and disables booking when no seats are left |
| 13 | 2026-09-26 | 00:58–01:15 | 17 min | Expire unpaid holds: ExpireBookingJob at hold expiry, 30s recurring sweep, Solid Queue on the primary DB; lapsed holds trusted over status (rebook, booking page, pay page redirect) |

**Total: ~126 min**
