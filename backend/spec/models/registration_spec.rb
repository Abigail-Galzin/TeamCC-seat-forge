require 'rails_helper'

RSpec.describe Registration, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:registration)).to be_valid
    end

    it "requires a status" do
      registration = build(:registration, status: nil)
      expect(registration).not_to be_valid
      expect(registration.errors[:status]).to be_present
    end

    it "rejects a status outside the allowed enum values" do
      registration = build(:registration)
      registration.status = "bogus"

      expect(registration).not_to be_valid
      expect(registration.errors[:status]).to include("is not included in the list")
    end

    it "rejects registering for a cancelled session" do
      session = create(:session, status: "cancelled")
      registration = build(:registration, session: session)

      expect(registration).not_to be_valid
      expect(registration.errors[:session]).to include("is not open for registration")
    end

    it "rejects registering for a completed session" do
      session = create(:session, status: "completed")
      registration = build(:registration, session: session)

      expect(registration).not_to be_valid
      expect(registration.errors[:session]).to include("is not open for registration")
    end

    it "rejects registering for a session that has already started" do
      session = create(:session)
      session.update_columns(starts_at: 1.hour.ago)
      registration = build(:registration, session: session)

      expect(registration).not_to be_valid
      expect(registration.errors[:session]).to include("has already started")
    end

    it "rejects a duplicate active registration for the same attendee and session" do
      attendee = create(:attendee)
      session = create(:session, capacity: 5)
      create(:registration, attendee: attendee, session: session, status: "held")

      registration = build(:registration, attendee: attendee, session: session, status: "held")

      expect(registration).not_to be_valid
      expect(registration.errors[:base]).to include(Registration::DUPLICATE_ACTIVE_REGISTRATION_MESSAGE)
    end

    it "allows a new registration when the attendee's prior registration for the session was cancelled" do
      attendee = create(:attendee)
      session = create(:session, capacity: 5)
      create(:registration, attendee: attendee, session: session, status: "cancelled")

      registration = build(:registration, attendee: attendee, session: session, status: "held")

      expect(registration).to be_valid
    end

    it "rejects an overlapping registration for a different session at the same time" do
      attendee = create(:attendee)
      first_session = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
      overlapping_session = create(:session, starts_at: 1.day.from_now + 1.hour, ends_at: 1.day.from_now + 3.hours)
      create(:registration, attendee: attendee, session: first_session, status: "held")

      registration = build(:registration, attendee: attendee, session: overlapping_session, status: "held")

      expect(registration).not_to be_valid
      expect(registration.errors[:base]).to include("attendee has an overlapping registration for this time")
    end

    it "allows a non-overlapping registration for a different session at a different time" do
      attendee = create(:attendee)
      first_session = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      other_session = create(:session, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour)
      create(:registration, attendee: attendee, session: first_session, status: "held")

      registration = build(:registration, attendee: attendee, session: other_session, status: "held")

      expect(registration).to be_valid
    end

    it "does not count a waitlisted registration on another session as overlapping" do
      attendee = create(:attendee)
      full_session = create(:session, capacity: 1, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
      create(:registration, session: full_session, status: "held")
      create(:registration, attendee: attendee, session: full_session, status: "waitlisted")
      overlapping_session = create(:session, starts_at: 1.day.from_now + 1.hour, ends_at: 1.day.from_now + 3.hours)

      registration = build(:registration, attendee: attendee, session: overlapping_session, status: "held")

      expect(registration).to be_valid
    end
  end

  describe ".register" do
    it "holds the seat when the session has capacity" do
      attendee = create(:attendee)
      session = create(:session, capacity: 5)

      registration = Registration.register(attendee: attendee, session: session)

      expect(registration).to be_persisted
      expect(registration.status).to eq("held")
      expect(registration.hold_expires_at).to be_within(1.second).of(10.minutes.from_now)
    end

    it "waitlists the registration once held and confirmed registrations reach capacity" do
      session = create(:session, capacity: 2)
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "confirmed")
      attendee = create(:attendee)

      registration = Registration.register(attendee: attendee, session: session)

      expect(registration).to be_persisted
      expect(registration.status).to eq("waitlisted")
      expect(registration.hold_expires_at).to be_nil
    end

    it "does not count waitlisted registrations against capacity" do
      session = create(:session, capacity: 2)
      create(:registration, session: session, status: "waitlisted")
      attendee = create(:attendee)

      registration = Registration.register(attendee: attendee, session: session)

      expect(registration.status).to eq("held")
    end

    it "returns an unpersisted registration with errors when validation fails" do
      session = create(:session, status: "cancelled")
      attendee = create(:attendee)

      registration = Registration.register(attendee: attendee, session: session)

      expect(registration).not_to be_persisted
      expect(registration.errors[:session]).to include("is not open for registration")
    end
  end

  describe ".expire_overdue_holds" do
    it "expires held registrations whose hold has lapsed" do
      registration = create(:registration, status: "held", hold_expires_at: 1.minute.ago)

      Registration.expire_overdue_holds

      expect(registration.reload.status).to eq("expired")
    end

    it "leaves held registrations whose hold has not lapsed" do
      registration = create(:registration, status: "held", hold_expires_at: 5.minutes.from_now)

      Registration.expire_overdue_holds

      expect(registration.reload.status).to eq("held")
    end

    it "promotes the oldest waitlisted registration for the freed session" do
      session = create(:session, capacity: 1)
      held = create(:registration, session: session, status: "held", hold_expires_at: 1.minute.ago)
      waitlisted = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      Registration.expire_overdue_holds

      expect(held.reload.status).to eq("expired")
      expect(waitlisted.reload.status).to eq("held")
      expect(waitlisted.hold_expires_at).to be_present
    end
  end

  describe ".promote_oldest_waitlisted" do
    it "promotes the earliest-created waitlisted registration to held and notifies it" do
      session = create(:session, capacity: 1)
      older = create(:registration, session: session, status: "waitlisted", created_at: 2.hours.ago)
      newer = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      expect {
        Registration.promote_oldest_waitlisted(Session.lock.find(session.id))
      }.to have_enqueued_job(RegistrationNotificationJob).with(older.id, "waitlist_promoted")

      expect(older.reload.status).to eq("held")
      expect(older.hold_expires_at).to be_present
      expect(newer.reload.status).to eq("waitlisted")
    end

    it "does nothing when there is no waitlisted registration" do
      session = create(:session, capacity: 1)

      expect {
        Registration.promote_oldest_waitlisted(Session.lock.find(session.id))
      }.not_to have_enqueued_job(RegistrationNotificationJob)
    end
  end

  describe "#expired?" do
    it "is true when hold_expires_at is in the past" do
      registration = build(:registration, hold_expires_at: 1.minute.ago)
      expect(registration.expired?).to be true
    end

    it "is false when hold_expires_at is in the future" do
      registration = build(:registration, hold_expires_at: 1.minute.from_now)
      expect(registration.expired?).to be false
    end

    it "is false when hold_expires_at is nil" do
      registration = build(:registration, hold_expires_at: nil)
      expect(registration.expired?).to be false
    end
  end

  describe "#confirm" do
    it "confirms a non-expired held registration and notifies it" do
      registration = create(:registration, status: "held", hold_expires_at: 5.minutes.from_now)

      expect {
        expect(registration.confirm).to be true
      }.to have_enqueued_job(RegistrationNotificationJob).with(registration.id, "confirmed")

      registration.reload
      expect(registration.status).to eq("confirmed")
      expect(registration.confirmed_at).to be_present
      expect(registration.hold_expires_at).to be_nil
    end

    it "is idempotent for an already-confirmed registration and does not re-notify" do
      registration = create(:registration, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)

      expect {
        expect(registration.confirm).to be true
      }.not_to have_enqueued_job(RegistrationNotificationJob)
    end

    it "fails for a waitlisted registration" do
      registration = create(:registration, status: "waitlisted", hold_expires_at: nil)

      expect(registration.confirm).to be false
      expect(registration.reload.status).to eq("waitlisted")
    end

    it "fails for a held registration whose hold has expired" do
      registration = create(:registration, status: "held", hold_expires_at: 1.minute.ago)

      expect(registration.confirm).to be false
      expect(registration.reload.status).to eq("held")
    end

    it "fails for a cancelled registration" do
      registration = create(:registration, status: "cancelled", cancelled_at: 1.hour.ago, hold_expires_at: nil)

      expect(registration.confirm).to be false
    end
  end

  describe "#cancel" do
    it "cancels a held registration" do
      registration = create(:registration, status: "held")

      expect(registration.cancel).to be true
      registration.reload
      expect(registration.status).to eq("cancelled")
      expect(registration.cancelled_at).to be_present
      expect(registration.hold_expires_at).to be_nil
    end

    it "cancels a confirmed registration" do
      registration = create(:registration, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)

      expect(registration.cancel).to be true
      expect(registration.reload.status).to eq("cancelled")
    end

    it "cancels a waitlisted registration" do
      registration = create(:registration, status: "waitlisted", hold_expires_at: nil)

      expect(registration.cancel).to be true
      expect(registration.reload.status).to eq("cancelled")
    end

    it "is idempotent for an already-cancelled registration" do
      registration = create(:registration, status: "cancelled", cancelled_at: 1.hour.ago, hold_expires_at: nil)

      expect(registration.cancel).to be true
    end

    it "fails for an expired registration" do
      registration = create(:registration, status: "expired", hold_expires_at: nil)

      expect(registration.cancel).to be false
      expect(registration.reload.status).to eq("expired")
    end

    it "releases the seat and promotes the oldest waitlisted registration when cancelling a held registration" do
      session = create(:session, capacity: 1)
      held = create(:registration, session: session, status: "held")
      waitlisted = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      expect(held.cancel).to be true

      expect(waitlisted.reload.status).to eq("held")
      expect(waitlisted.hold_expires_at).to be_present
    end

    it "releases the seat and promotes the oldest waitlisted registration when cancelling a confirmed registration" do
      session = create(:session, capacity: 1)
      confirmed = create(:registration, session: session, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)
      waitlisted = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      expect(confirmed.cancel).to be true

      expect(waitlisted.reload.status).to eq("held")
    end

    it "does not promote anyone when cancelling a waitlisted registration" do
      session = create(:session, capacity: 1)
      create(:registration, session: session, status: "held")
      waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil, created_at: 1.hour.ago)
      other_waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil, created_at: 30.minutes.ago)

      expect(waitlisted.cancel).to be true

      expect(other_waitlisted.reload.status).to eq("waitlisted")
    end
  end

  describe "#expire_hold" do
    it "is a no-op for a registration that is not held" do
      registration = create(:registration, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)

      expect(registration.expire_hold).to be true
      expect(registration.reload.status).to eq("confirmed")
    end

    it "is a no-op when the hold has not lapsed yet" do
      registration = create(:registration, status: "held", hold_expires_at: 5.minutes.from_now)

      expect(registration.expire_hold).to be true
      expect(registration.reload.status).to eq("held")
    end

    it "expires an overdue held registration" do
      registration = create(:registration, status: "held", hold_expires_at: 1.minute.ago)

      expect(registration.expire_hold).to be true
      expect(registration.reload.status).to eq("expired")
    end

    it "promotes the oldest waitlisted registration on the same session" do
      session = create(:session, capacity: 1)
      held = create(:registration, session: session, status: "held", hold_expires_at: 1.minute.ago)
      waitlisted = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      held.expire_hold

      expect(waitlisted.reload.status).to eq("held")
    end
  end
end
