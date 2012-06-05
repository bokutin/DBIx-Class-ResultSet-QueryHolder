package DBIx::Class::ResultSet::QueryHolder;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet);

use Carp;
use DBIx::Class::ResultSet::QueryHolder::Object;

sub as_query_holder {
    my $self = shift;

    DBIx::Class::ResultSet::QueryHolder::Object->new(
        sqlbind => $self->as_query, 
        as      => $self->_resolved_attrs->{as},
        dbh     => $self->result_source->schema->storage->dbh,
    );
}

1;
