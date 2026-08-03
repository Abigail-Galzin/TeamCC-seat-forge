require 'rails_helper'

RSpec.describe Attendee, type: :model do
  describe "associations" do
    it "destroys dependent registrations when destroyed" do
      attendee = create(:attendee)
      registration = create(:registration, attendee: attendee)

      expect { attendee.destroy }.to change { Registration.exists?(registration.id) }.from(true).to(false)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:attendee, name: "Jane Doe", email: "jane@example.com")).to be_valid
    end

    it "requires a name" do
      attendee = build(:attendee, name: nil)
      expect(attendee).not_to be_valid
      expect(attendee.errors[:name]).to be_present
    end

    it "rejects a name containing characters other than letters and spaces" do
      attendee = build(:attendee, name: "Jane123")
      expect(attendee).not_to be_valid
      expect(attendee.errors[:name]).to include("can only contain letters and spaces")
    end

    it "accepts a name with accented letters" do
      expect(build(:attendee, name: "José Núñez")).to be_valid
    end

    it "requires an email" do
      attendee = build(:attendee, email: nil)
      expect(attendee).not_to be_valid
      expect(attendee.errors[:email]).to be_present
    end

    it "rejects a malformed email" do
      attendee = build(:attendee, email: "not-an-email")
      expect(attendee).not_to be_valid
      expect(attendee.errors[:email]).to include("must be a valid email address")
    end

    it "rejects a duplicate email regardless of case" do
      create(:attendee, email: "dup@example.com")
      attendee = build(:attendee, email: "DUP@example.com")

      expect(attendee).not_to be_valid
      expect(attendee.errors[:email]).to include("has already been taken")
    end
  end

  describe ".find_by_email" do
    it "finds an attendee by exact email" do
      attendee = create(:attendee, email: "match@example.com")
      expect(Attendee.find_by_email("match@example.com")).to eq(attendee)
    end

    it "is case-insensitive" do
      attendee = create(:attendee, email: "match@example.com")
      expect(Attendee.find_by_email("MATCH@EXAMPLE.com")).to eq(attendee)
    end

    it "trims surrounding whitespace" do
      attendee = create(:attendee, email: "match@example.com")
      expect(Attendee.find_by_email("  match@example.com  ")).to eq(attendee)
    end

    it "returns nil when no attendee matches" do
      expect(Attendee.find_by_email("missing@example.com")).to be_nil
    end
  end

  describe "#registration_status_counts" do
    it "returns zero counts for every status, overridden by the attendee's actual registrations" do
      attendee = create(:attendee)
      create(:registration, attendee: attendee, status: "held",
        session: create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour))
      create(:registration, attendee: attendee, status: "confirmed",
        session: create(:session, starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour))

      expect(attendee.registration_status_counts).to eq(
        "held" => 1,
        "confirmed" => 1,
        "waitlisted" => 0,
        "cancelled" => 0,
        "expired" => 0
      )
    end

    it "returns all zero counts when the attendee has no registrations" do
      attendee = create(:attendee)

      expect(attendee.registration_status_counts).to eq(
        "held" => 0,
        "confirmed" => 0,
        "waitlisted" => 0,
        "cancelled" => 0,
        "expired" => 0
      )
    end
  end
end
