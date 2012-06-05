package DBIx::Class::ResultSet::QueryHolder::Object;

use strict;
use warnings;
use Carp;
use List::Util qw(first);
use List::MoreUtils qw(firstidx indexes);
use List::Flatten;

use Class::XSAccessor {
    getters     => [qw(as dbh sqlbind)],
    #accessors => [qw(sth)],
};

use Scalar::Util qw(weaken);

sub new {
    my $class = shift;

    my $self = bless { @_ }, __PACKAGE__;

    weaken $self->{dbh};
    $_->[0]{_changed} = 1 for $self->bind_specs;

    $self;
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

sub bind_specs {
    my $self = shift;

    my $sqlbind = $self->sqlbind;

    @{$$sqlbind}[1..$#{$$sqlbind}]
}

sub bind_values {
    my $self = shift;

    my $sqlbind = $self->sqlbind;

    map { $_->[1] } @{$$sqlbind}[1..$#{$$sqlbind}]
}

sub set_bind_value {
    my $self = shift;
    my $cond = (@_ == 1 and ref($_[0]) and ref($_[0]) eq 'HASH') ? shift : die;

    #use Data::Dumper;
    #die Dumper [$self->bind_specs];

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

#sub _bind_changed_bind_values {
#    my $self = shift;
#
#    my $changed = 0;
#    my $p_num = 0;
#    for my $entry ($self->bind_specs) {
#        $p_num++;
#        if ( delete $entry->[0]{_changed} ) {
#            $self->sth->bind_param($p_num, $entry->[1]);
#            $changed++;
#        }
#    }
#
#    $changed;
#}

my @delegate_to_dbi = (
    #"execute",
    "fetchrow_array",
    "fetchrow_arrayref",
    "fetchrow_hashref",
    "fetchall_arrayref",
    "fetchall_hashref",
);

sub execute {
    my $self = shift;

    #$self->_bind_changed_bind_values;
    $self->sth->execute(@_);
}

for my $method (@delegate_to_dbi) {
    my $code = sub {
        my $self = shift;
        $self->execute;
        $self->sth->$method(@_);
    };
    no strict 'refs';
    *{$method} = $code;
}

1;
