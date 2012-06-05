use utf8;
package MyApp::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    default_resultset_class => "+MyApp::Base::DBIx::Class::ResultSet",
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-01 00:46:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EI4XaxH+qLloFNOchlaR2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
