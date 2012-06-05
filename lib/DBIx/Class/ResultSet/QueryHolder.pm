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

__END__

=encoding utf-8

=head1 NAME

DBIx::Class::ResultSet::QueryHolder - $rs->as_queryを使いまわします

=head1 SYNOPSIS

=head1 AUTHOR

Tomohiro Hosaka E<lt>bokutin@bokut.inE<gt>

=head1 LICENSE

Copyright (C) 2012 Tomohiro Hosaka All Rights Reserved.

=cut
