require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  include ActionView::RecordIdentifier

  def sign_in_as(user)
    post sign_in_otp_path, params: { email: user.email }
    post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
  end

  let(:trial_class) { create(:trial_class, title: "Intro to Physics", price_cents: 2500) }

  describe "GET /checkout/:trial_class_id" do
    it "summarises the trial class and its price" do
      get checkout_path(trial_class)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Checkout"
      assert_select "dd", "Intro to Physics"
      assert_select "dd", "SGD 25.00"
    end

    it "asks a signed-out parent for their name, email and child's name" do
      get checkout_path(trial_class)

      assert_select "input[type=text][name=?]", "checkout[parent_name]"
      assert_select "input[type=email][name=?]", "checkout[parent_email]"
      assert_select "input[type=text][name=?]", "checkout[student_name]"
      assert_select "select[name=?]", "checkout[student_id]", count: 0
    end

    it "shows a signed-in parent's name instead of asking for it" do
      sign_in_as create(:parent, name: "Jane Doe")

      get checkout_path(trial_class)

      assert_select "main fieldset", text: /Jane Doe/
      assert_select "input[name^=?]", "checkout[parent_", count: 0
    end

    it "lets a signed-in parent pick one of their children or add a new one" do
      parent = create(:parent)
      create(:student, parent:, name: "Timmy Doe")
      create(:student, parent:, name: "Anna Doe")
      create(:student, name: "Someone Else")
      sign_in_as parent

      get checkout_path(trial_class)

      options = css_select("select[name='checkout[student_id]'] option").map(&:text)
      expect(options).to eq([ "Add a new child", "Anna Doe", "Timmy Doe" ])
      assert_select "input[type=text][name=?]", "checkout[student_name]"
    end

    it "hides the child picker from a parent with no children yet" do
      sign_in_as create(:parent)

      get checkout_path(trial_class)

      assert_select "select[name=?]", "checkout[student_id]", count: 0
    end

    it "posts the booking form back to the checkout" do
      get checkout_path(trial_class)

      assert_select "form[action=?][method=post]", checkout_path(trial_class) do
        assert_select "input[type=submit]:not([disabled])[value=?]", "Book trial class"
      end
    end

    it "tells the parent a fully booked class has no seats and disables booking" do
      create_list(:booking, 4, trial_class:, status: :confirmed)

      get checkout_path(trial_class)

      assert_select "main p", "Sorry, class is fully booked"
      assert_select "input[type=submit][disabled]"
    end

    it "subscribes to the class's seat updates around the book button" do
      get checkout_path(trial_class)

      assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name(trial_class)
      assert_select "form ##{dom_id(trial_class, :availability)} input[type=submit]"
    end

    it "returns not found for an unknown class" do
      get checkout_path(trial_class_id: 0)

      expect(response).to have_http_status(:not_found)
    end

    it "sends a signed-in admin home" do
      sign_in_as create(:admin)

      get checkout_path(trial_class)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /checkout/:trial_class_id" do
    def book(**checkout)
      post checkout_path(trial_class), params: { checkout: }
    end

    it "signs up a new parent, adds their child and holds a seat" do
      book(parent_name: "Jane Doe", parent_email: "jane@example.com", student_name: "Timmy Doe")

      booking = Booking.last
      expect(response).to redirect_to(payment_path(booking))
      expect(booking).to be_pending
      expect(booking.trial_class).to eq(trial_class)
      expect(booking.student.name).to eq("Timmy Doe")
      expect(booking.student.parent).to have_attributes(name: "Jane Doe", email: "jane@example.com")

      follow_redirect!
      assert_select "nav", text: /Jane Doe/
    end

    it "adds a new child for a signed-in parent" do
      parent = create(:parent)
      sign_in_as parent

      book(student_name: "Timmy Doe")

      expect(response).to redirect_to(payment_path(Booking.last))
      expect(Booking.last.student).to have_attributes(name: "Timmy Doe", parent:)
    end

    it "books the child a signed-in parent picked" do
      student = create(:student)
      sign_in_as student.parent

      expect { book(student_id: student.id) }.not_to change(Student, :count)
      expect(response).to redirect_to(payment_path(Booking.last))
      expect(Booking.last.student).to eq(student)
    end

    it "rejects a new child named like one the parent already has" do
      student = create(:student, name: "Timmy Doe")
      sign_in_as student.parent

      expect { book(student_name: "Timmy Doe") }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Child's name has already been taken"
    end

    it "rejects picking a child and adding a new one at once" do
      student = create(:student)
      sign_in_as student.parent

      expect { book(student_id: student.id, student_name: "Anna Doe") }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Choose one of your children or add a new one, not both"
    end

    it "rejects another parent's child" do
      sign_in_as create(:parent)

      expect { book(student_id: create(:student).id) }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Choose one of your children"
    end

    it "requires the child's name" do
      sign_in_as create(:parent)

      book(student_name: "")

      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Child's name can't be blank"
    end

    it "requires a signed-out parent's name and email" do
      expect { book(parent_name: "", parent_email: "", student_name: "Timmy Doe") }.not_to change(Parent, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Name can't be blank"
      assert_select "main li", "Email can't be blank"
    end

    it "asks a signed-out parent with an existing account to sign in" do
      create(:parent, email: "jane@example.com")

      expect { book(parent_name: "Jane Doe", parent_email: "jane@example.com", student_name: "Timmy Doe") }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Email has already been taken"
      assert_select "main a[href=?]", sign_in_path
    end

    it "rejects a child already booked in the class" do
      booking = create(:booking, trial_class:, status: :confirmed)
      sign_in_as booking.student.parent

      expect { book(student_id: booking.student.id) }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main li", "Child is already booked in this class"
    end

    it "rejects a fully booked class without saving the new parent or child" do
      create_list(:booking, 4, trial_class:, status: :confirmed)

      expect { book(parent_name: "Jane Doe", parent_email: "jane@example.com", student_name: "Timmy Doe") }
        .not_to change { [ Parent.count, Student.count, Booking.count ] }
      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "main p", "Sorry, class is fully booked"
      assert_select "input[type=submit][disabled]"
    end

    it "does not let an admin book" do
      sign_in_as create(:admin)

      expect { book(student_name: "Timmy Doe") }.not_to change(Booking, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
