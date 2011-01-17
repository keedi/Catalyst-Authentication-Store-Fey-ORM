package Catalyst::Authentication::Store::Fey::ORM;
# ABSTRACT: A storage class for Catalyst Authentication using L<Fey::ORM>

use strict;
use warnings;
use Catalyst::Authentication::Store::Fey::ORM::User;

use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config/);
}

sub new {
    my ( $class, $config, $app ) = @_;

    my $self = {
        config => $config,
    };

    return bless $self, $class;
}

sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

    my $user = Catalyst::Authentication::Store::Fey::ORM::User->new(
        $self->config,
        $c,
    );

    return $user->from_session($frozenuser, $c);
}

sub for_session {
    my ( $self, $c, $user ) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $user = Catalyst::Authentication::Store::Fey::ORM::User->new(
        $self->config,
        $c,
    );

    return $user->load($authinfo, $c);
}

1;
