#!/bin/bash
# Shared helpers for the loop hooks. Sourced, not executed.

# run_with_timeout <seconds> <shell command>
# Exit 142 on expiry, otherwise the command's own status.
#
# Coreutils `timeout` is absent on stock macOS. `perl -e 'alarm; exec'` is the
# usual stand-in but signals only the shell it replaced, so anything the command
# backgrounded outlives the timeout -- and a loop re-runs its oracle every turn,
# so those orphans accumulate. Forking instead of exec keeps a parent alive to
# hold the SIGALRM handler (exec resets handlers to default), and the child
# leads its own process group so one kill reaches the whole tree.
run_with_timeout() {
  local seconds="$1" command="$2"
  perl -e '
    my $t = shift;
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    $SIG{ALRM} = sub {
      kill("KILL", -$pid) or kill("KILL", $pid);
      waitpid($pid, 0);
      exit 142;
    };
    alarm $t;
    waitpid($pid, 0);
    my $st = $?;
    exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
  ' "$seconds" /bin/bash -c "$command"
}
