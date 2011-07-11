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
    $self->app_timeout_sec = $self->app_timeout_sec || 300;
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

Plack::Middleware::AppTimeout

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::AppTimeout" => (
            app_timeout_sec => 120 # 120 sec.
        );
        $app;
    };

=cut
