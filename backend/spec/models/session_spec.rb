require 'rails_helper'

RSpec.describe Session, type: :model do
  describe "associations" do
    it "destroys dependent registrations when destroyed" do
      session = create(:session)
      registration = create(:registration, session: session)

      expect { session.destroy }.to change { Registration.exists?(registration.id) }.from(true).to(false)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:session)).to be_valid
    end

    it "requires a workshop" do
      session = build(:session, workshop: nil)
      expect(session).not_to be_valid
      expect(session.errors[:workshop]).to be_present
    end

    it "requires a capacity" do
      session = build(:session, capacity: nil)
      expect(session).not_to be_valid
    end

    it "rejects a zero or negative capacity" do
      expect(build(:session, capacity: 0)).not_to be_valid
      expect(build(:session, capacity: -1)).not_to be_valid
    end

    it "rejects a non-integer capacity" do
      expect(build(:session, capacity: 1.5)).not_to be_valid
    end

    it "requires starts_at and ends_at" do
      expect(build(:session, starts_at: nil)).not_to be_valid
      expect(build(:session, ends_at: nil)).not_to be_valid
    end

    it "rejects a starts_at that is not a valid ISO 8601 timestamp" do
      session = build(:session)
      session.starts_at = "not-a-date"

      expect(session).not_to be_valid
      expect(session.errors[:starts_at]).to include("must be a valid ISO 8601 timestamp")
    end

    it "rejects starts_at at or after ends_at" do
      session = build(:session, starts_at: 2.days.from_now, ends_at: 1.day.from_now)
      expect(session).not_to be_valid
      expect(session.errors[:starts_at]).to include("must be earlier than ends_at")
    end

    it "rejects a starts_at that is not in the future when creating" do
      session = build(:session, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
      expect(session).not_to be_valid
      expect(session.errors[:starts_at]).to include("must be in the future")
    end

    it "allows starts_at to move into the past on update (future check only applies on create)" do
      session = create(:session)

      expect(session.update(starts_at: 2.days.ago, ends_at: 1.day.ago)).to be true
    end

    it "rejects a status outside the allowed enum values" do
      session = build(:session)
      session.status = "bogus"

      expect(session).not_to be_valid
      expect(session.errors[:status]).to include("is not included in the list")
    end
  end

  describe "seat counters" do
    let(:session) { create(:session, capacity: 5) }

    it "counts held, confirmed, and waitlisted registrations independently" do
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "confirmed")
      create(:registration, session: session, status: "waitlisted")
      create(:registration, session: session, status: "cancelled")

      expect(session.held_seats).to eq(2)
      expect(session.confirmed_seats).to eq(1)
      expect(session.waitlist_size).to eq(1)
    end

    it "computes available_seats as capacity minus confirmed seats" do
      create(:registration, session: session, status: "confirmed")
      create(:registration, session: session, status: "confirmed")

      expect(session.available_seats).to eq(3)
    end

    it "clamps available_seats at zero rather than going negative" do
      allow(session).to receive(:confirmed_seats).and_return(session.capacity + 5)

      expect(session.available_seats).to eq(0)
    end
  end

  describe "#in_progress?" do
    it "is true when the current time falls between starts_at and ends_at" do
      session = create(:session)
      session.update_columns(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

      expect(session.in_progress?).to be true
    end

    it "is false when the session has not started yet" do
      session = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      expect(session.in_progress?).to be false
    end

    it "is false when the session has already ended" do
      session = create(:session)
      session.update_columns(starts_at: 2.hours.ago, ends_at: 1.hour.ago)

      expect(session.in_progress?).to be false
    end
  end
end
