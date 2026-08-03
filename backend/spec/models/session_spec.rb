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

  describe "#cancel" do
    it "cancels held, confirmed, and waitlisted registrations and marks the session cancelled" do
      session = create(:session, capacity: 5)
      held = create(:registration, session: session, status: "held")
      confirmed = create(:registration, session: session, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)
      waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)

      ok, counts = session.cancel("Instructor unavailable")

      expect(ok).to be true
      expect(counts).to eq("held" => 1, "confirmed" => 1, "waitlisted" => 1)

      session.reload
      expect(session.status).to eq("cancelled")
      expect(session.cancellation_reason).to eq("Instructor unavailable")
      expect(session.cancelled_at).to be_present

      expect(held.reload.status).to eq("cancelled")
      expect(held.hold_expires_at).to be_nil
      expect(confirmed.reload.status).to eq("cancelled")
      expect(waitlisted.reload.status).to eq("cancelled")
    end

    it "leaves expired and already-cancelled registrations unchanged" do
      session = create(:session, capacity: 5)
      expired = create(:registration, session: session, status: "expired", hold_expires_at: nil)
      original_cancelled_at = 2.hours.ago
      already_cancelled = create(
        :registration, session: session, status: "cancelled", cancelled_at: original_cancelled_at, hold_expires_at: nil
      )

      ok, counts = session.cancel("Instructor unavailable")

      expect(ok).to be true
      expect(counts).to eq("held" => 0, "confirmed" => 0, "waitlisted" => 0)
      expect(expired.reload.status).to eq("expired")
      expect(already_cancelled.reload.cancelled_at).to be_within(1.second).of(original_cancelled_at)
    end

    it "is idempotent for an already-cancelled session and does not re-touch its registrations" do
      session = create(:session, capacity: 5)
      held = create(:registration, session: session, status: "held")
      session.update_columns(status: "cancelled", cancellation_reason: "Original reason", cancelled_at: 2.hours.ago)

      ok, counts = session.cancel("New reason")

      expect(ok).to be true
      expect(counts).to eq("held" => 0, "confirmed" => 0, "waitlisted" => 0)
      expect(session.reload.cancellation_reason).to eq("Original reason")
      expect(held.reload.status).to eq("held")
    end

    it "does not re-enqueue notifications when cancelling an already-cancelled session" do
      session = create(:session, capacity: 5)
      create(:registration, session: session, status: "held")
      session.cancel("Instructor unavailable")

      expect {
        session.cancel("Instructor unavailable")
      }.not_to have_enqueued_job(RegistrationNotificationJob)
    end

    it "enqueues a notification job for held and confirmed attendees" do
      session = create(:session, capacity: 5)
      held = create(:registration, session: session, status: "held")
      confirmed = create(:registration, session: session, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)

      expect {
        session.cancel("Instructor unavailable")
      }.to have_enqueued_job(RegistrationNotificationJob).with(held.id, "session_cancelled")
        .and have_enqueued_job(RegistrationNotificationJob).with(confirmed.id, "session_cancelled")
    end

    it "does not enqueue a notification job for a waitlisted attendee" do
      session = create(:session, capacity: 5)
      waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)

      expect {
        session.cancel("Instructor unavailable")
      }.not_to have_enqueued_job(RegistrationNotificationJob).with(waitlisted.id, "session_cancelled")
    end

    it "does not promote waitlisted registrations" do
      session = create(:session, capacity: 1)
      create(:registration, session: session, status: "held")
      waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)

      session.cancel("Instructor unavailable")

      expect(waitlisted.reload.status).to eq("cancelled")
    end
  end
end
