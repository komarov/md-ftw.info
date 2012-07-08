#!/usr/bin/perl


=head1 NAME

converter-http.psgi

=head1 DESCRIPTION

Puts tasks in the queue on uploads and services downloads.
Needs CONVERTER_ROOT in ENV.

=cut


use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Modern::Perl;
use Plack::Builder;
use Plack::Request;
use Plack::Response;
use Task;


my $ROOT = $ENV{CONVERTER_ROOT};
$Task::DATA_DIR  = "$ROOT/data";
$Task::QUEUE_DIR = "$ROOT/queue";


my $app = sub {
    my $env = shift;

    my $request = Plack::Request->new($env);

    for ($request->method) {
        when ('GET') {
            my (undef, undef, $task_id, $action) = split '/+', $request->path_info;
            for ($action) {
                when ('status') {
                    return get_task_status($task_id);
                }
                when ('download') {
                    return get_task_result($task_id, $request->param('filename'));
                }
                default {
                    die "unknown action $action for task $task_id";
                }
            }
        }
        when ('POST') {
            return create_task($request);
        }
        default {
            die 'unknown method '.$request->method;
        }
    }
};

builder {
    $app;
};


sub create_task
{
    my $request = shift;

    my $upload = $request->upload('src_file');
    my $task_id = Task::create($upload->path);
    return [200, ['Content-Type' => 'text/plain'], [$task_id]];
}


sub get_task_status
{
    my $task_id = shift;

    return [200, ['Content-Type' => 'text/plain'], [Task::get_status($task_id)]];
}


sub get_task_result
{
    my $task_id = shift;
    my $filename = shift || "$task_id.pdf";

    # prevent possible headers manipulation
    $filename =~ s/[\r\n]//g;
    $filename =~ s/"/\\"/g;

    return [
        200,
        [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => qq[attachment; filename="$filename"],
        ],
        [Task::get_result($task_id)]
    ];
}
