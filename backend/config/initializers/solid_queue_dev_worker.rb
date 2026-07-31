# On Windows the Solid Queue Puma plugin can't run (it forks), so recurring
# jobs like ExpireHeldRegistrationsJob only run if `bin/jobs` is started
# alongside the server. That's easy to forget when starting the server
# directly (`rails s`, an IDE run button) instead of via `bin/dev`, and the
# failure is silent: no error, jobs just never process.
#
# To make that impossible to forget, the server itself checks for a live
# Solid Queue process on boot and spawns `bin/jobs` if none is found.
# `bin/dev` sets SOLID_QUEUE_DEV_AUTOSTART=0 on the server it spawns since
# it already starts `bin/jobs` itself — this only kicks in when the server
# is started some other way.
if Gem.win_platform? && Rails.env.development? && defined?(Rails::Server) && ENV["SOLID_QUEUE_DEV_AUTOSTART"] != "0"
  Rails.application.config.after_initialize do
    has_live_worker = SolidQueue::Process.where("last_heartbeat_at > ?", 30.seconds.ago).exists?

    unless has_live_worker
      Rails.logger.info "[solid_queue] No active worker found — starting bin/jobs automatically"
      pid = Process.spawn(RbConfig.ruby, File.join(Rails.root, "bin/jobs"))
      Process.detach(pid)
      at_exit { Process.kill("TERM", pid) rescue nil }
    end
  end
end
