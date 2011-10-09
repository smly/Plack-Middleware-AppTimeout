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

our $VERSION = '0.05';

sub prepare_app {
    my $self = shift;
}

sub call {
    my ($self, $env) = @_;

    my $timeout = $self->app_timeout_sec || 300;
    my $res = undef;
    my $flag = 0;
    eval {
        local $SIG{ALRM} = sub { $flag = 1; die };
        alarm($timeout);
        $res = $self->app->($env);
        alarm(0);
    };
    alarm(0);

    if ($@) {
        if (!$flag) {
            # handling application error
            $res = [ 500, [ 'Content-Type' => 'text/plain' ], [ 'Internal Server Error' ] ];
        } else {
            # handling application timeout
            $res = [ 503, [ 'Content-Type' => 'text/plain' ], [ 'Service Temporarily Unavailable' ] ];
        }
    }

    return $res;
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::AppTimeout

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::AppTimeout" => (
            app_timeout_sec => 120 # 120 sec.
        );
        $app;
    };

=head1 DESCRIPTION

Terminating the application with signal ALRM.

=head1 AUTHOR

eowner<at>gmail<dot>com

=head1 SEE ALSO


=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

=cut
