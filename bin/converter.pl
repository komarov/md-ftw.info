#!/usr/bin/perl


=head1 NAME

converter.pl

=head1 DESCRIPTION

Processes task queue with the help of pandoc.
Started by ubic.

=cut


use 5.010;
use strict;
use warnings;

use Linux::Inotify2;
use POSIX qw/strftime/;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Task;
use subs 'msg';
$| = 1;


my $QUEUE_DIR = $Task::QUEUE_DIR = $ENV{QUEUE_DIR};
my $DATA_DIR  = $Task::DATA_DIR  = $ENV{DATA_DIR};
my ($PANDOC_BIN) = `which pandoc`;
chomp $PANDOC_BIN;

die "couldn't find pandoc" unless $PANDOC_BIN && -x $PANDOC_BIN;
die "no queue dir $QUEUE_DIR" unless -d $QUEUE_DIR;
die "no data dir $DATA_DIR" unless -d $DATA_DIR;

my $inotify = Linux::Inotify2->new or die $!;
$inotify->watch($QUEUE_DIR, IN_CREATE) or die 'watch creation failed';
opendir(my $dh, $QUEUE_DIR) or die $!;
# process all tasks we already have
process($dh);
# then dive into main loop
while ($inotify->read()) {
    process($dh);
}
warn $!;
closedir $dh;
exit 0;


sub process
{
    my $dh = shift;

    seekdir $dh, 0;
    my @task_ids = grep {-f "$QUEUE_DIR/$_"} readdir($dh);

    for my $task_id (@task_ids) {
        msg "start $task_id";
        process_task($task_id);
        unlink "$QUEUE_DIR/$task_id" or die $!;
        msg "finish $task_id";
    }
}


sub process_task
{
    my $task_id = shift;

    my $src = Task::get_src_path($task_id);
    my $dst = Task::get_dst_path($task_id);

    if (-f $src) {
        system($PANDOC_BIN, $src, '-o', $dst);
        if (-f $dst) {
            msg "created $dst";
        } else {
            msg "failed to create $dst";
        }
    } else {
        msg "not found src file $src";
    }
}


sub msg($)
{
    my $msg = shift;
    say sprintf "%s\t%s", strftime("%Y-%m-%d %H-%M-%S", localtime), $msg;
}
