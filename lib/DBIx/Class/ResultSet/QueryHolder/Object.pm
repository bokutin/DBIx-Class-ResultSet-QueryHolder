package DBIx::Class::ResultSet::QueryHolder::Object;

use strict;
use warnings;

use Carp;
use List::Flatten;
use List::MoreUtils qw(indexes);
use Scalar::Util qw(weaken);

use Class::XSAccessor {
    getters => [qw(as dbh sqlbind)],
};

sub new {
    my $class = shift;

    my $self = bless { @_ }, __PACKAGE__;

    weaken $self->{dbh};

    $self;
}

sub bind_specs {
    my $self = shift;

    my $sqlbind = $self->sqlbind;
    @{$$sqlbind}[1..$#{$$sqlbind}]
}

sub bind_values {
    my $self = shift;

    map { $_->[1] } $self->bind_specs;
}

sub execute {
    my $self = shift;

    $self->sth->execute(@_);
}

sub set_bind_value {
    my $self = shift;
    my $cond = (@_ == 1 and ref($_[0]) and ref($_[0]) eq 'HASH') ? shift : die;

    for my $name ( keys %$cond ) {
        my @indexes = indexes { $_->[0]{dbic_colname} eq $name } $self->bind_specs;
        my @values  = flat $cond->{$name};
        if (@indexes == @values) {
            for (@indexes) {
                $self->sth->bind_param($_+1, shift @values);
            }
        }
        else {
            if (@indexes == 0) {
                croak "dbic_colname '$name' is not found.";
            }
            else {
                croak sprintf("dbic_colname '$name' bind_values is not same. bind_values:%d != values:%d", 0+@indexes, 0+@values);
            }
        }
    }
    
}

sub statement {
    my $self = shift;

    ${$self->sqlbind}->[0];
}

sub sth {
    my $self = shift;

    $self->{sth} ||= do {
        my $sth = $self->dbh->prepare($self->statement);
        my $p_num = 0;
        for my $value ($self->bind_values) {
            $p_num++;
            $sth->bind_param($p_num, $value);
        }
        $sth;
    };
}

{
    my @delegate_to_dbi = (
        "fetchrow_array",
        "fetchrow_arrayref",
        "fetchrow_hashref",
        "fetchall_arrayref",
        "fetchall_hashref",
    );

    for my $method (@delegate_to_dbi) {
        my $code = sub {
            my $self = shift;
            $self->execute;
            $self->sth->$method(@_);
        };
        no strict 'refs';
        *{$method} = $code;
    }
}

1;
