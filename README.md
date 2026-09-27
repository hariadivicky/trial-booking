# Trial Booking

## Backend design

### Data model

```
parents 1──* students 1──* bookings *──1 trial_classes *──1 class_subjects
                               │
                               1──* payment_attempts
admins (separate sign-in, sees rosters and payments)
```

| Table | Key fields |
|---|---|
| `trial_classes` | `capacity` (default 4, `> 0`), `price_cents` |
| `bookings` | `student_id`, `trial_class_id`, `status`, `payment_status`, `amount_cents` (price snapshot), `expires_at` (seat hold deadline) |
| `payment_attempts` | `booking_id`, `status`, `failure_reason`, `amount_cents`, `idempotency_key` |

A booking holds a seat when it is `confirmed`, or `pending` with `expires_at` still in the future.

### Key endpoints and backend functions

| Route | Backend | Does |
|---|---|---|
| `POST /checkout/:trial_class_id` | `Checkout#save` → `Booking.hold_seat!` | Picks or adds a child, holds a seat for 30s |
| `POST /pay/:booking_id` | `Payment#save` → `MockPaymentGateway#charge` | Charges the card, confirms the booking or records the failure |
| `GET /bookings/:id` | `BookingsController#show` | Live booking status |
| `GET /trial_classes/:trial_class_id/roster` | `TrialClass#roster` | Admin roster: confirmed students and live holds |
| `GET /payment_attempts`, `GET /bookings/:id/payment_attempts` | `PaymentAttempt.log` | Admin payment log |
| background | `ExpireBookingJob`, `Booking.expire_stale!` | Expire unpaid holds |

### Booking statuses

- `bookings.status`: `pending` (seat held, awaiting payment) → `confirmed` or `expired`. `canceled` is allowed by the schema but no flow sets it yet.
- `bookings.payment_status`: `pending` → `paid` or `failed`.
- `payment_attempts.status`: `succeeded` or `failed`, one row per charge.

### Duplicate bookings

- A partial unique index on `(student_id, trial_class_id) WHERE status IN ('pending', 'confirmed')` stops a second live booking for the same child and class. A model validation gives the friendly error first.
- `hold_seat!` expires the child's own lapsed hold before inserting, because the index only sees `status`, not `expires_at`.
- Double-submitted payments reuse the attempt with the same `idempotency_key` (a UUID per pay form) instead of charging again. A partial unique index allows only one `succeeded` attempt per booking.

### Payment failure

A declined card records a `failed` attempt with its reason and sets `payment_status: failed`. The booking stays `pending`, so the child is never on the confirmed roster, and the parent can retry with another card until the hold expires. When it expires, the seat goes back to the class. Only a succeeded attempt confirms a booking.

### Last-seat race

**Approach:** the seat is taken at checkout, not at payment. `Booking.hold_seat!` locks the class row (`SELECT … FOR UPDATE`), counts seat-holding bookings and inserts a 30s hold. `Payment#save` and `Booking#expire!` take the same lock, so a hold can't expire halfway through a payment.

For the brief's scenario: when A moves to payment, A already holds the last seat. B sees "fully booked" and can't book, so B can only get the seat after A's hold lapses. If B then pays first, A's payment finds its hold lapsed, marks it `expired` and is rejected without charging. Only B is confirmed. See `spec/models/payment_spec.rb` and the threaded test in `spec/models/booking_spec.rb`.

**Why:** No parent is charged for a seat they can't get, so no refunds are needed. A row lock on the class is the simplest correct option in Postgres, and with 4 seats per class there is little lock contention.

**Tradeoffs:**
- An abandoned checkout blocks the seat until its hold expires. 30s is for the demo; production would use ~10 minutes.
- Capacity is enforced by the lock plus a count in `hold_seat!`, not by a database constraint. Code that creates bookings any other way could overbook.
- The mock gateway is called inside the lock. A real gateway should be called outside the transaction, or confirmed by webhook, so a slow network call doesn't hold the class lock.

### Where each check lives

| Layer | Checks |
|---|---|
| UI | Book button disabled when full (live over Turbo Streams), hold countdown on the pay page, idempotency key per pay form. For convenience only; the backend re-checks everything. |
| Backend | Seat count under the class lock, duplicate booking validation, rejecting payment for lapsed or settled holds, idempotent payment, card rules in the mock gateway |
| Database | Partial unique indexes (one live booking per child and class, one successful payment per booking), unique `idempotency_key`, check constraints on statuses, amounts and capacity, foreign keys |
| Background job | `ExpireBookingJob` runs at each hold's `expires_at`; a 30s recurring `Booking.expire_stale!` sweep catches any missed job. Reads trust `expires_at` over `status`, so a late job never frees or blocks a seat wrongly. |
