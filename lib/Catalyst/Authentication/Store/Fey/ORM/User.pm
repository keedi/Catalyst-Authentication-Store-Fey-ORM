package Catalyst::Authentication::Store::Fey::ORM::User;
# ABSTRACT: The backing user class for the Catalyst::Authentication::Store::Fey::ORM storage module.

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
    bless $self, $class;

    Catalyst::Exception->throw(
        'Did you set user_model correctly?'
    ) unless $self->config->{user_model};

    Catalyst::Exception->throw(
        'Did you set id_field correctly?'
    ) unless $self->config->{id_field};

    return $self;
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
    my $class = $self->config->{user_model};
    my $user = $class->new( %$authinfo );
    $self->_user($user);

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
        my $iter = $self->_user->$relation;
        if ($iter) {
            while ( my $role = $iter->next ) {
                if (my $method = $role->can($self->config->{role_field})) {
                    push @roles, $role->$method;
                }
                else {
                    Catalyst::Exception->throw(
                        'Did you set role_field correctly?'
                    );
                }
            }
        }
        else {
            Catalyst::Exception->throw(
                'Did you set role_relation correctly?'
            );
        }
        $self->_roles(\@roles);
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

    my %userdata;
    for my $column ( $self->_user->Table->columns ) {
        my $method = $column->name;
        $userdata{$column->name} = $self->_user->$method;
    }

    return \%userdata;
}

sub from_session {
    my ( $self, $frozenuser, $c ) = @_;

    if ( exists( $self->config->{'use_userdata_from_session'} )
        && $self->config->{'use_userdata_from_session'} != 0 )
    {
        return $self->load( $frozenuser, $c );
    }

    if (ref $frozenuser eq 'HASH') {
        return $self->load(
            { map { ($_ => $frozenuser->{$_}) } $self->config->{id_field} },
            $c,
        );
    }

    return $self->load( { $self->config->{id_field} => $frozenuser }, $c );
}

sub get {
    my ( $self, $field ) = @_;

    if (my $method = $self->_user->can($field)) {
        return $self->_user->$method;
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
        if (my $method = $self->_user->can($method)) {
            return sub { shift->_user->$method(@_) };
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

    if (my $method = $self->_user->can($method)) {
        return $self->_user->$method(@_);
    }
    else {
        return;
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
__END__
