require 'rails_helper'

RSpec.describe Workshop, type: :model do
  describe "associations" do
    it "destroys dependent sessions when destroyed" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)

      expect { workshop.destroy }.to change { Session.exists?(session.id) }.from(true).to(false)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      workshop = build(:workshop, title: "Intro to Rails", topic: "Web Development", active: true)
      expect(workshop).to be_valid
    end

    it "requires a title" do
      workshop = build(:workshop, title: nil)
      expect(workshop).not_to be_valid
      expect(workshop.errors[:title]).to be_present
    end

    it "rejects a title shorter than 3 characters" do
      workshop = build(:workshop, title: "ab")
      expect(workshop).not_to be_valid
    end

    it "rejects a title longer than 150 characters" do
      workshop = build(:workshop, title: "a" * 151)
      expect(workshop).not_to be_valid
    end

    it "requires a topic" do
      workshop = build(:workshop, topic: nil)
      expect(workshop).not_to be_valid
      expect(workshop.errors[:topic]).to be_present
    end

    it "rejects a topic shorter than 2 characters" do
      workshop = build(:workshop, topic: "a")
      expect(workshop).not_to be_valid
    end

    it "rejects a topic longer than 100 characters" do
      workshop = build(:workshop, topic: "a" * 101)
      expect(workshop).not_to be_valid
    end

    it "requires active to be true or false" do
      workshop = build(:workshop, active: nil)
      expect(workshop).not_to be_valid
      expect(workshop.errors[:active]).to be_present
    end

    it "rejects a description longer than 1000 characters" do
      workshop = build(:workshop, description: "a" * 1001)
      expect(workshop).not_to be_valid
    end

    it "allows a blank description" do
      workshop = build(:workshop, description: nil)
      expect(workshop).to be_valid
    end

    it "rejects a title with invalid characters" do
      workshop = build(:workshop, title: "Rails <script>")
      expect(workshop).not_to be_valid
    end

    it "rejects a title made up of only digits" do
      workshop = build(:workshop, title: "12345")
      expect(workshop).not_to be_valid
    end

    it "rejects a description made up of only digits" do
      workshop = build(:workshop, description: "12345")
      expect(workshop).not_to be_valid
    end

    it "accepts a title with accented characters, punctuation, and spaces" do
      workshop = build(:workshop, title: "Introducción a Ruby, Fase 1.0")
      expect(workshop).to be_valid
    end
  end

  describe "#current_or_next_session" do
    it "returns the in-progress scheduled session when one is happening now" do
      workshop = create(:workshop)
      in_progress = create(:session, workshop: workshop, status: "scheduled",
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      in_progress.update_columns(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

      expect(workshop.current_or_next_session).to eq(in_progress)
    end

    it "returns the earliest future scheduled session when none is in progress" do
      workshop = create(:workshop)
      later = create(:session, workshop: workshop, status: "scheduled",
        starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour)
      sooner = create(:session, workshop: workshop, status: "scheduled",
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      expect(workshop.current_or_next_session).to eq(sooner)
      expect(workshop.current_or_next_session).not_to eq(later)
    end

    it "ignores cancelled and completed sessions" do
      workshop = create(:workshop)
      cancelled = create(:session, workshop: workshop, status: "cancelled",
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      cancelled.update_columns(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

      expect(workshop.current_or_next_session).to be_nil
    end

    it "returns nil when there are no upcoming or in-progress sessions" do
      workshop = create(:workshop)
      completed = create(:session, workshop: workshop, status: "completed",
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      completed.update_columns(starts_at: 2.days.ago, ends_at: 2.days.ago + 1.hour)

      expect(workshop.current_or_next_session).to be_nil
    end
  end
end
