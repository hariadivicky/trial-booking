# AI Usage

## Tools

- **Claude Code** (VS Code extension, Claude Opus 5.5) for design discussion, specs, code, commits and the time log.
- **`CLAUDE.md`** with my working rules: KISS, TDD, small commits, and no data-model or design decisions without asking me.
- **Claude Code memory notes** to carry context between conversations: where the brief is, the commit convention, the Ruby/Node PATH fixes, and time tracking.

## What I used it for

I worked in 15 short conversations, one slice each (see [TIME_LOG.md](TIME_LOG.md)). Each one followed the same loop:

1. I describe the slice, often with a rough markdown sketch of the page or table.
2. If it touches the data model or an invariant, I ask for a proposal or a list of test cases first, with no code. I answer its questions and cut what the brief doesn't need.
3. It writes failing specs, then the code, then runs rspec and rubocop (and brakeman on controller work).
4. I review the diff, try it in the app, and ask for `test:` / `feat:` commit pairs.

The AI wrote almost all of the code. I made the design calls: the tables and columns, booking statuses, seat holds, retrying until the hold expires, the idempotency key, and which pages update live.

## Where it helped me move faster

**Proving the last-seat race.** Before building checkout, I asked for test cases. The list included a concurrency spec: three threads race for a class with one seat, with a short `sleep` between counting seats and inserting the booking. Without the class row lock (`SELECT ... FOR UPDATE`) all three got the seat; with it, exactly one did. A threaded spec needs non-transactional tests and one DB connection per thread, and would have taken me much longer to write by hand. It turned the race from an argument into a red/green test ([booking_spec.rb](spec/models/booking_spec.rb), "when parents race for the last seat").

Live updates were similar: Turbo Streams across five pages, including a headless Chrome spec for the pay page, took one ~20 minute session.

## Where I corrected or rejected it

**It designed before reading the brief.** My first request was a structure for `trial_classes`. It proposed a schema and asked four questions (session or template, teacher, age range, online or in person) that the brief already answers. I asked whether it had read the brief. It hadn't. After reading it, it trimmed the schema, and I cut `starts_at` and `duration_minutes` too. I then had it save a memory note so every later conversation reads the brief before suggesting a design.

**It trusted `status` where it should have trusted `expires_at`.** Unpaid holds were expired by a scheduled job plus a 30-second sweep that flips `pending` to `expired`. I didn't want correctness to depend on a job running on time, so I asked it to review the gaps with `expires_at` as the source of truth. Using throwaway probe specs, it found three real bugs:
- A child couldn't rebook after a lapsed hold until the job ran, or ever, if the worker was down.
- The pay page showed a card form for lapsed and already confirmed bookings.
- The booking page still said "Pending" after the deadline.

It also found four slightly different definitions of "lapsed". The fix was a single `Booking.lapsed` scope and `#lapsed?` used everywhere, so the job now only tidies up the status (`bf50f06`).

**Smaller calls where I went another way:**
- It leaned toward taking the seat only at payment. I chose a pending booking that holds the seat until `expires_at`.
- To choose a child, it proposed matching an existing child by typed name. I asked for a picker of existing children plus a new-name field, with names unique per parent.

## What I would change next time

- **Point it at the brief in `CLAUDE.md` from the first message,** rather than adding a memory note after the miss.
- **Ask for an invariant review right after each seat or payment feature.** The `expires_at` review found bugs in code whose specs were already green.
- **Keep a `TODO.md` for the gaps it flags.** Across 15 short conversations, some flags only lived in chat: no ownership check on `/pay/:id` and `/bookings/:id`, CI not building JS for system specs, and no DB unique index on child names.

## How I verified the final implementation

- **Tests first.** Each feature has a `test:` commit that fails on its own, then a `feat:` commit that makes it pass. The suite has 160 examples, 0 failures, and rubocop reports no offenses.
- **Each brief rule has a spec:**
  - **Duplicate bookings:** a model validation plus a partial unique index on `(student_id, trial_class_id)` for pending and confirmed bookings.
  - **Overbooking and the last-seat race:** the threaded spec above, plus a payment spec where an expired hold loses the last seat and only one booking is confirmed.
  - **Payment failure:** a declined card records a failed `payment_attempt`, keeps the child off the confirmed roster, and allows a retry. A resubmitted form doesn't charge twice.
  - **Hold expiry:** the job, the sweep, and holds that lapse before the job runs.
  - **Seeds:** a class with exactly 3 confirmed students.
- **By hand:** I clicked through sign up, checkout, payment and the admin roster in the dev app. For live updates, the AI also drove a real server with `bin/jobs` in headless Chrome. A hold made from another process switched the home page to "Fully booked" within 3 seconds.
- **Small commits,** so I could read every diff before it went in.
