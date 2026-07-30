# Native Windows Ruby doesn't implement every POSIX signal Solid Queue's
# Supervisor tries to trap (e.g. SIGQUIT), which crashes `bin/jobs` with
# `ArgumentError: unsupported signal 'SIGQUIT'` before it can boot. Restrict
# the list to signals this Ruby build actually supports.
supported_signals = Signal.list.keys.map(&:to_sym)

SolidQueue::Supervisor::Signals.send(:remove_const, :SIGNALS)
SolidQueue::Supervisor::Signals.const_set(
  :SIGNALS,
  %i[QUIT INT TERM] & supported_signals
)
