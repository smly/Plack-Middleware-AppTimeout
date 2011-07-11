package Plack::Middleware::AppTimeout;
use 5.008;
use strict;
use warnings;
use parent qw(
    Plack::Middleware
);
use Plack::Util::Accessor qw(
    app_timeout_sec
);

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;
    $self->set_app_timeout_sec($self->app_timeout_sec || 300);
}

sub call {
    my ($self, $env) = @_;

    my $res;
    eval {
        local $SIG{ALRM} = sub { die };
        alarm($self->app_timeout_sec);
        $res = $self->app->($env);
        my $timeleft = alarm(0);
    }; 

    if ($@) {
        # todo
        $res = [ 503, [ 'Content-Type' => 'text/plain' ], [ '503' ] ];
    }

    return $res;
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::SizeLimit - Terminate processes if they grow too large

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable SizeLimit => (
            max_unshared_size_in_kb => '4096', # 4MB
            # min_shared_size_in_kb => '8192', # 8MB
            # max_process_size_in_kb => '16384', # 16MB
            check_every_n_requests => 2
        );
        $app;
    };

=head1 DESCRIPTION

This middleware is a port of the excellent L<Apache::SizeLimit> module
for multi-process Plack servers, such as L<Starman>, L<Starlet> and C<uWSGI>.

This middleware only works when the environment C<psgix.harakiri> is
set to a true value by the Plack server.  If it's set to false, then this
middleware simply does nothing.

=head1 CONFIGURATIONS

=over 4

=item max_unshared_size_in_kb

The maximum amount of I<unshared> memory the process can use;
usually this option is all one needs.

Experience on one heavily trafficked L<mod_perl> site showed that
setting this option and leaving the others unset is the most effective
policy.

This is because it only kills off processes that are truly using too much
physical RAM, allowing most processes to live longer and reducing the
process churn rate.

=item min_shared_size_in_kb

Sets the minimum amount of shared memory the process must have.

=item max_process_size_in_kb

The maximum size of the process, including both shared and unshared memory.

=item check_every_n_requests

Since checking the process size can take a few system calls on some
platforms (e.g. linux), you may specify this option to check the process
size every I<N> requests.

=back

=head1 SEE ALSO

L<Starman>, L<Starlet>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Plack::Middleware::SizeLimit>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
