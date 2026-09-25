require "rails_helper"
require "turbo/broadcastable/test_helper"

RSpec.describe Booking do
  it "defaults to pending status and pending payment" do
    booking = Booking.new

    expect(booking).to be_pending
    expect(booking).to be_payment_pending
  end

  it "copies the trial class price into the amount" do
    trial_class = create(:trial_class, price_cents: 4200)

    expect(create(:booking, trial_class: trial_class).amount_cents).to eq(4200)
  end

  it "holds the seat for the hold duration" do
    booking = create(:booking)

    expect(booking.expires_at).to be_within(5.seconds).of(Booking::HOLD_DURATION.from_now)
  end

  it "schedules its expiry for when the hold ends" do
    booking = create(:booking)

    expect(ExpireBookingJob).to have_been_enqueued.with(booking).at(booking.expires_at)
  end

  it "requires a student" do
    booking = build(:booking, student: nil)

    expect(booking).not_to be_valid
    expect(booking.errors[:student]).to include("must exist")
  end

  it "requires a trial class" do
    booking = build(:booking, trial_class: nil)

    expect(booking).not_to be_valid
    expect(booking.errors[:trial_class]).to include("must exist")
  end

  it "requires a non-negative amount" do
    booking = build(:booking, amount_cents: -1)

    expect(booking).not_to be_valid
    expect(booking.errors[:amount_cents]).to include("must be greater than or equal to 0")
  end

  it "rejects a second pending or confirmed booking for the same student and class" do
    existing = create(:booking, status: :confirmed)
    booking = build(:booking, student: existing.student, trial_class: existing.trial_class)

    expect(booking).not_to be_valid
    expect(booking.errors[:student_id]).to include("is already booked in this class")
  end

  it "allows rebooking once the earlier booking expired or was canceled" do
    expired = create(:booking, status: :expired)
    create(:booking, student: expired.student, trial_class: expired.trial_class, status: :canceled)
    booking = build(:booking, student: expired.student, trial_class: expired.trial_class)

    expect(booking).to be_valid
  end

  it "rejects a booking once the class is fully booked" do
    trial_class = create(:trial_class, capacity: 1)
    create(:booking, trial_class:, status: :confirmed)
    booking = build(:booking, trial_class:)

    expect(booking).not_to be_valid
    expect(booking.errors[:base]).to include("This class is fully booked")
  end

  it "takes the last seat of a class with 3 confirmed students" do
    trial_class = create(:trial_class)
    create_list(:booking, 3, trial_class:, status: :confirmed)

    expect(build(:booking, trial_class:)).to be_valid
  end

  it "counts unexpired holds against the seats but not expired ones" do
    trial_class = create(:trial_class, capacity: 1)
    hold = create(:booking, trial_class:)
    expect(build(:booking, trial_class:)).not_to be_valid

    hold.update!(expires_at: 1.minute.ago)
    expect(build(:booking, trial_class:)).to be_valid
  end

  it "cannot be destroyed while it has payment attempts" do
    booking = create(:payment_attempt).booking

    expect(booking.destroy).to be_falsey
    expect(Booking.exists?(booking.id)).to be true
  end

  it "is rejected by the database as a duplicate pending or confirmed booking" do
    existing = create(:booking)

    expect { existing.dup.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "is rejected by the database with an unknown status" do
    booking = create(:booking)

    expect { Booking.where(id: booking.id).update_all("status = 'bogus'") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "is rejected by the database with an unknown payment status" do
    booking = create(:booking)

    expect { Booking.where(id: booking.id).update_all("payment_status = 'bogus'") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "is rejected by the database with a negative amount" do
    booking = create(:booking)

    expect { booking.update_column(:amount_cents, -1) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  describe "live updates" do
    include ActiveJob::TestHelper
    include Turbo::Broadcastable::TestHelper
    include ActionView::RecordIdentifier

    def broadcasts_from(stream, &block)
      capture_turbo_stream_broadcasts(stream) { perform_enqueued_jobs(only: Turbo::Streams::ActionBroadcastJob, &block) }
        .to_h { [ _1["target"], _1.at("template").text.squish ] }
    end

    it "pushes the seats left to the class's home item when a seat is held" do
      trial_class = create(:trial_class, title: "Class A")

      broadcasts = broadcasts_from(trial_class) { create(:booking, trial_class:) }

      expect(broadcasts).to include(dom_id(trial_class, :seats) => "3 seats left", dom_id(trial_class) => "Class A · 3 seats left")
    end

    it "pushes the freed seat once a hold expires" do
      trial_class = create(:trial_class, capacity: 1)
      booking = create(:booking, trial_class:, expires_at: 1.second.ago)

      broadcasts = broadcasts_from(trial_class) { booking.expire! }

      expect(broadcasts).to include(dom_id(trial_class, :seats) => "1 seat left")
    end

    it "tells checkout the class is fully booked once its last seat is held" do
      trial_class = create(:trial_class, capacity: 1)

      broadcasts = broadcasts_from(trial_class) { create(:booking, trial_class:) }

      expect(broadcasts).to include(dom_id(trial_class, :availability) => "Sorry, class is fully booked")
    end

    it "pushes the roster on its own stream only, since it names children and parents" do
      trial_class = create(:trial_class)

      roster = broadcasts_from([ trial_class, :roster ]) { create(:booking, trial_class:, student: create(:student, name: "Timmy Doe")) }
      public = broadcasts_from(trial_class) { create(:booking, trial_class:, student: create(:student, name: "Anna Lee")) }

      expect(roster[dom_id(trial_class, :roster)]).to include("Timmy Doe")
      expect(public.values.join).not_to include("Anna Lee")
    end

    it "pushes its status to its own booking page when it changes" do
      booking = create(:booking, expires_at: 1.second.ago)

      broadcasts = broadcasts_from(booking) { booking.expire! }

      expect(broadcasts).to eq(dom_id(booking, :status) => "Status Expired Payment Pending")
    end
  end

  describe ".held" do
    it "finds pending holds still inside their deadline" do
      held = create(:booking)
      create(:booking, expires_at: 1.second.ago)
      create(:booking, status: :confirmed)

      expect(Booking.held).to contain_exactly(held)
    end
  end

  describe ".lapsed" do
    it "finds pending holds past their deadline, whatever the job has done" do
      lapsed = create(:booking, expires_at: 1.second.ago)
      create(:booking)
      create(:booking, status: :confirmed, expires_at: 1.second.ago)

      expect(Booking.lapsed).to contain_exactly(lapsed)
    end
  end

  describe "#lapsed?" do
    it "is true for a pending hold past its deadline" do
      expect(build(:booking, expires_at: 1.second.ago)).to be_lapsed
    end

    it "is false before the deadline or once the booking has left pending" do
      expect(build(:booking, expires_at: 1.minute.from_now)).not_to be_lapsed
      expect(build(:booking, status: :confirmed, expires_at: 1.second.ago)).not_to be_lapsed
    end
  end

  describe "#expire!" do
    it "expires a pending hold once it has passed" do
      booking = create(:booking, expires_at: 1.second.ago)

      booking.expire!

      expect(booking.reload).to be_expired
    end

    it "keeps a hold that hasn't passed yet" do
      booking = create(:booking)

      booking.expire!

      expect(booking.reload).to be_pending
    end

    it "keeps a booking that was paid before the job ran" do
      booking = create(:booking, expires_at: 1.second.ago)
      Booking.where(id: booking.id).update_all(status: "confirmed")

      booking.expire!

      expect(booking.reload).to be_confirmed
    end
  end

  describe ".expire_stale!" do
    it "expires every pending hold that has passed" do
      stale = create_list(:booking, 2, expires_at: 1.second.ago)
      fresh = create(:booking)
      confirmed = create(:booking, status: :confirmed, expires_at: 1.second.ago)

      Booking.expire_stale!

      expect(stale.map { _1.reload.status }).to all(eq("expired"))
      expect(fresh.reload).to be_pending
      expect(confirmed.reload).to be_confirmed
    end
  end

  describe ".hold_seat!" do
    it "holds a pending seat for the student" do
      booking = Booking.hold_seat!(trial_class: create(:trial_class), student: create(:student))

      expect(booking).to be_persisted
      expect(booking).to be_pending
    end

    it "lets the student book again once their hold lapsed, before the job expires it" do
      lapsed = create(:booking, expires_at: 1.second.ago)

      booking = Booking.hold_seat!(trial_class: lapsed.trial_class, student: lapsed.student)

      expect(booking).to be_pending
      expect(lapsed.reload).to be_expired
    end

    context "when parents race for the last seat" do
      self.use_transactional_tests = false

      after { [ Booking, Student, Parent, TrialClass, ClassSubject ].each(&:delete_all) }

      it "lets only one of them hold it" do
        trial_class = create(:trial_class, capacity: 1)
        students = create_list(:student, 3)
        # Widen the gap between counting seats and inserting, so an unlocked check would overbook.
        allow_any_instance_of(Booking).to receive(:seat_available).and_wrap_original { |original| original.call.tap { sleep 0.1 } }

        students.map { |student|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              Booking.hold_seat!(trial_class: TrialClass.find(trial_class.id), student:)
            rescue ActiveRecord::RecordInvalid
              nil
            end
          end
        }.each(&:join)

        expect(trial_class.bookings.count).to eq(1)
      end
    end
  end
end
