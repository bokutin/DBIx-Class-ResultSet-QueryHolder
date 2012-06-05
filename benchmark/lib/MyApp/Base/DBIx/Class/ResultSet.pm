package MyApp::Base::DBIx::Class::ResultSet;

use Moose;
extends (
    "DBIx::Class::ResultSet::HashRef",
    "DBIx::Class::ResultSet::QueryHolder",
);

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
