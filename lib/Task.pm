package Task;

use Digest::MD5 qw/md5_hex/;
use File::Copy qw/move/;
use File::Slurp qw/read_file/;
use File::Touch qw/touch/;
use Modern::Perl;

our $DATA_DIR;
our $QUEUE_DIR;


=head2 create($path)

$path is path to tmp file with content to process

=cut

sub create
{
    my $path = shift;

    my $task_id = md5_hex($path.rand(time));
    my $task_dir = "$DATA_DIR/$task_id";

    return create($path) if -d $task_dir;

    mkdir $task_dir;
    move($path, get_src_path($task_id));
    touch("$QUEUE_DIR/$task_id");

    return $task_id;
}


sub get_status
{
    my $task_id = shift;

    my $status;
    if (-d "$DATA_DIR/$task_id") {
        $status = -f get_dst_path($task_id) ? 'ready' : 'wait';
    } else {
        $status = 'error';
    }
}


sub get_result
{
    my $task_id = shift;

    return scalar read_file(get_dst_path($task_id), {binmode => ':raw'});
}


sub get_src_path
{
    my $task_id = shift;

    return "$DATA_DIR/$task_id/src.md";
}


sub get_dst_path
{
    my $task_id = shift;

    return "$DATA_DIR/$task_id/dst.pdf";
}

1;
