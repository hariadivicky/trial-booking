require "rails_helper"

RSpec.describe Demo do
  describe ".reset!" do
    it "replaces every record with the seed data" do
      create(:booking, student: create(:student, parent: create(:parent, email: "john@example.com")))
      create(:admin, email: "other-admin@example.com")

      Demo.reset!

      expect(Admin.pluck(:email)).to eq([ "admin@example.com" ])
      expect(Parent.pluck(:email)).to contain_exactly("parent@example.com", "mei@example.com", "raj@example.com", "sarah@example.com")
      expect(TrialClass.pluck(:title)).to contain_exactly("Fractions Fun", "Shapes and Angles", "Intro to Physics", "Plants and Seeds")
      expect(Booking.confirmed.count).to eq(3)
    end

    it "keeps Solid Queue's tables, whose processes stop once their rows are gone" do
      SolidQueue::Process.create!(kind: "Worker", name: "worker-1", pid: 1, last_heartbeat_at: Time.current)

      expect { Demo.reset! }.not_to change(SolidQueue::Process, :count)
    end
  end
end
