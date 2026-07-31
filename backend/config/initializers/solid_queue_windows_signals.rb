# Native Windows Ruby builds (mingw-ucrt) don't support Signal::QUIT, so
# Solid Queue's standalone supervisor (bin/jobs) crashes with
# `ArgumentError: unsupported signal 'QUIT'` before it can boot. Only trap
# signals this platform actually understands.
if Gem.win_platform?
  SolidQueue::Supervisor::Signals::SIGNALS.replace(
    SolidQueue::Supervisor::Signals::SIGNALS & Signal.list.keys.map(&:to_sym)
  )
end
