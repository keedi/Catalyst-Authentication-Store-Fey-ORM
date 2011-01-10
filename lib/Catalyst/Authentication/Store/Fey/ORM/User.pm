package Catalyst::Authentication::Store::Fey::ORM::User;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Authentication::User';

has 'config' => ( is => 'rw' );
has '_user'  => ( is => 'rw' );
has '_roles' => ( is => 'rw' );

sub new {
    my ( $class, $config, $c ) = @_;

    my $self = {
        config => $config,
        _roles => undef,
        _user  => undef,
    };

    return bless $self, $class;
}

sub supported_features {
    my $self = shift;

    return {
        session => 1,
        roles   => 1,
    };
}

sub load {
    my ( $self, $authinfo, $c ) = @_;

    #
    # search with $authinfo then set $self->_user
    #
    #...

    return $self->get_object ? $self : undef;
}

sub roles {
    my $self = shift;

    return @{$self->_roles} if ref $self->_roles eq 'ARRAY';

    my @roles;
    if (exists($self->config->{role_column})) {
        my $role_data = $self->get( $self->config->{role_column} );
        @roles = split /[\s,\|]+/, $role_data if $role_data;
        $self->_roles(\@roles);
    }
    elsif (exists($self->config->{role_relation})) {
        my $relation = $self->config->{role_relation};
        # ...
    }
    else {
        Catalyst::Exception->throw(
            "user->roles accessed, but no role configuration found"
        );
    }

    return @{$self->_roles};
}

sub for_session {
    my $self = shift;

    #my %userdata = $self->_user->get_columns;
    return \%userdata;
}

sub from_session {
    my ( $self, $frozenuser, $c ) = @_;

    if (ref $frozenuser eq 'HASH') {
        return $self->load(
            {
                map {
                    ($_ => $frozenuser->{$_})
                } @{ $self->config->{id_field} }
            },
            $c,
        );
    }

    return $self->load(
        { $self->config->{id_field} => $frozenuser },
        $c,
    );
}

sub get {
    my ( $self, $field ) = @_;

    if (my $code = $self->_user->can($field)) {
        return $self->_user->$code;
    }
    else {
        return undef;
    }
}

sub get_object {
    my $self = shift;

    return $self->_user;
}

sub can {
    my $self = shift;

    return $self->SUPER::can(@_) || do {
        my ($method) = @_;
        if (my $code = $self->_user->can($method)) {
            return sub { shift->_user->$code(@_) };
        }
        else {
            return;
        }
    };
}

sub AUTOLOAD {
    my $self = shift;

    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    if (my $code = $self->_user->can($method)) {
        return $self->_user->$code(@_);
    }
    else {
        return;
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
user_model
id_field
ignore_fields_in_find
role_column
role_field
role_relation
use_userdata_from_session
