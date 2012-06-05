package MyApp::Base::DBIx::Class::Core;

use Moose;
use MooseX::NonMoose;
extends 'DBIx::Class::Core';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
