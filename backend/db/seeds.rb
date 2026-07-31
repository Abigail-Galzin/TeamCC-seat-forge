# Deterministic demo dataset.
#
# Safe to re-run: wipes attendees/workshops/sessions/registrations and
# rebuilds them from scratch in a fixed order (and resets the primary key
# sequences), so IDs and content are identical every time this runs -
# whether via `bin/rails db:seed` or after a full `bin/rails db:reset`.
#
# Includes a dedicated "Client Demo Workshop" with two sessions running in
# parallel on the next upcoming Monday - one already has a confirmed
# attendee, the other a held attendee - plus a third, cancelled session
# later the same day. Use these to demonstrate live, during the demo, that
# the API rejects registering the same attendee into two overlapping
# sessions and rejects registering into a cancelled session.

def register!(attendee, session, status:, hold_expires_at: nil, confirmed_at: nil, cancelled_at: nil)
  Registration.create!(
    attendee: attendee,
    session: session,
    status: status,
    hold_expires_at: hold_expires_at,
    confirmed_at: confirmed_at,
    cancelled_at: cancelled_at
  )
end

ActiveRecord::Base.transaction do
  puts "Clearing existing data..."
  Registration.delete_all
  Session.delete_all
  Workshop.delete_all
  Attendee.delete_all

  %w[registrations sessions workshops attendees].each do |table|
    ActiveRecord::Base.connection.reset_pk_sequence!(table)
  end

  puts "Creating attendees..."
  attendees = {
    alice: Attendee.create!(name: "Alice Anderson", email: "alice.anderson@example.com"),
    ben: Attendee.create!(name: "Ben Baker", email: "ben.baker@example.com"),
    carla: Attendee.create!(name: "Carla Cruz", email: "carla.cruz@example.com"),
    diego: Attendee.create!(name: "Diego Duarte", email: "diego.duarte@example.com"),
    elena: Attendee.create!(name: "Elena Espinoza", email: "elena.espinoza@example.com"),
    fabian: Attendee.create!(name: "Fabian Flores", email: "fabian.flores@example.com"),
    gina: Attendee.create!(name: "Gina Gutierrez", email: "gina.gutierrez@example.com"),
    hugo: Attendee.create!(name: "Hugo Herrera", email: "hugo.herrera@example.com"),
    ivana: Attendee.create!(name: "Ivana Ibanez", email: "ivana.ibanez@example.com"),
    javier: Attendee.create!(name: "Javier Jimenez", email: "javier.jimenez@example.com"),
  }

  puts "Creating workshops and sessions..."

  kubernetes = Workshop.create!(
    title: "Introduction to Kubernetes",
    topic: "DevOps",
    description: "Hands-on fundamentals of container orchestration with Kubernetes.",
    active: true
  )
  react = Workshop.create!(
    title: "Modern React Patterns",
    topic: "Frontend Engineering",
    description: "Deep dive into hooks, state management, and component design in React.",
    active: true
  )
  spark = Workshop.create!(
    title: "Data Engineering with Spark",
    topic: "Data Engineering",
    description: "Building scalable ETL pipelines using Apache Spark.",
    active: true
  )
  demo = Workshop.create!(
    title: "Client Demo Workshop",
    topic: "Product Demo",
    description: "Dedicated workshop used to rehearse the upcoming client demo scenario.",
    active: true
  )

  k8s_intro = Session.create!(workshop: kubernetes, capacity: 20,
    starts_at: 3.days.from_now.change(hour: 9, min: 0), ends_at: 3.days.from_now.change(hour: 11, min: 0))
  k8s_advanced = Session.create!(workshop: kubernetes, capacity: 3,
    starts_at: 5.days.from_now.change(hour: 14, min: 0), ends_at: 5.days.from_now.change(hour: 15, min: 0))

  react_basics = Session.create!(workshop: react, capacity: 15,
    starts_at: 2.days.from_now.change(hour: 10, min: 0), ends_at: 2.days.from_now.change(hour: 11, min: 30))
  react_hooks = Session.create!(workshop: react, capacity: 4,
    starts_at: 6.days.from_now.change(hour: 16, min: 0), ends_at: 6.days.from_now.change(hour: 17, min: 0))

  spark_fundamentals = Session.create!(workshop: spark, capacity: 25,
    starts_at: 4.days.from_now.change(hour: 8, min: 30), ends_at: 4.days.from_now.change(hour: 11, min: 30))
  spark_streaming = Session.create!(workshop: spark, capacity: 10,
    starts_at: 7.days.from_now.change(hour: 13, min: 0), ends_at: 7.days.from_now.change(hour: 15, min: 0))

  demo_monday = Date.current.next_occurring(:monday)
  demo_track_a = Session.create!(workshop: demo, capacity: 12,
    starts_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 15, 0),
    ends_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 16, 0))
  demo_track_b = Session.create!(workshop: demo, capacity: 8,
    starts_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 15, 0),
    ends_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 16, 0))
  demo_backup_slot = Session.create!(workshop: demo, capacity: 10, status: "cancelled",
    starts_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 19, 0),
    ends_at: Time.utc(demo_monday.year, demo_monday.month, demo_monday.day, 20, 0))

  puts "Creating registrations..."

  # Kubernetes intro: healthy mix of statuses, plenty of open seats
  register!(attendees[:alice], k8s_intro, status: "held", hold_expires_at: 8.minutes.from_now)
  register!(attendees[:ben], k8s_intro, status: "confirmed", confirmed_at: 2.hours.ago)
  register!(attendees[:carla], k8s_intro, status: "expired", hold_expires_at: 1.hour.ago)
  register!(attendees[:diego], k8s_intro, status: "cancelled", cancelled_at: 3.hours.ago)

  # Kubernetes advanced: FULL - capacity 3, 3 confirmed seats, 0 available
  register!(attendees[:elena], k8s_advanced, status: "confirmed", confirmed_at: 1.day.ago)
  register!(attendees[:fabian], k8s_advanced, status: "confirmed", confirmed_at: 1.day.ago)
  register!(attendees[:gina], k8s_advanced, status: "confirmed", confirmed_at: 1.day.ago)

  # React basics: another healthy mix
  register!(attendees[:diego], react_basics, status: "held", hold_expires_at: 9.minutes.from_now)
  register!(attendees[:elena], react_basics, status: "held", hold_expires_at: 5.minutes.from_now)
  register!(attendees[:fabian], react_basics, status: "cancelled", cancelled_at: 4.hours.ago)
  register!(attendees[:gina], react_basics, status: "expired", hold_expires_at: 30.minutes.ago)

  # React hooks: FULL with a visible waitlist - capacity 4, 4 confirmed + 2 waitlisted
  register!(attendees[:hugo], react_hooks, status: "confirmed", confirmed_at: 6.hours.ago)
  register!(attendees[:ivana], react_hooks, status: "confirmed", confirmed_at: 6.hours.ago)
  register!(attendees[:javier], react_hooks, status: "confirmed", confirmed_at: 6.hours.ago)
  register!(attendees[:alice], react_hooks, status: "confirmed", confirmed_at: 6.hours.ago)
  register!(attendees[:ben], react_hooks, status: "waitlisted")
  register!(attendees[:carla], react_hooks, status: "waitlisted")

  # Spark fundamentals
  register!(attendees[:alice], spark_fundamentals, status: "confirmed", confirmed_at: 12.hours.ago)
  register!(attendees[:ben], spark_fundamentals, status: "held", hold_expires_at: 7.minutes.from_now)
  register!(attendees[:hugo], spark_fundamentals, status: "cancelled", cancelled_at: 1.day.ago)
  register!(attendees[:ivana], spark_fundamentals, status: "expired", hold_expires_at: 45.minutes.ago)

  # Spark streaming
  register!(attendees[:carla], spark_streaming, status: "held", hold_expires_at: 6.minutes.from_now)
  register!(attendees[:diego], spark_streaming, status: "confirmed", confirmed_at: 2.days.ago)

  # Client demo: Track A already has a confirmed attendee, Track B (same
  # hour, parallel track) has its own held attendee - different people, so
  # no overlap conflict between them. The backup slot is cancelled.
  register!(attendees[:javier], demo_track_a, status: "confirmed", confirmed_at: 1.hour.ago)
  register!(attendees[:gina], demo_track_b, status: "held", hold_expires_at: 9.minutes.from_now)

  puts "Seed complete:"
  puts "  Workshops: #{Workshop.count}"
  puts "  Sessions: #{Session.count} (#{Session.scheduled.count} scheduled, #{Session.cancelled.count} cancelled)"
  puts "  Attendees: #{Attendee.count}"
  puts "  Registrations: #{Registration.count} by status -> #{Registration.group(:status).count}"
  puts "  Demo workshop ##{demo.id} on #{demo_monday}:"
  puts "    Track A (session ##{demo_track_a.id}) - confirmed: #{attendees[:javier].name}"
  puts "    Track B (session ##{demo_track_b.id}, overlaps Track A) - held: #{attendees[:gina].name}"
  puts "    Backup slot (session ##{demo_backup_slot.id}) - cancelled"
end
