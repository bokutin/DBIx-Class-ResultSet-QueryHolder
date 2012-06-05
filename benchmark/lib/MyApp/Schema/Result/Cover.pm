use utf8;
package MyApp::Schema::Result::Cover;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'MyApp::Base::DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::Serializer", "TimeStamp");
__PACKAGE__->table("cover");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cover_id_seq",
  },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "created_at",
  {
    data_type     => "timestamp",
    is_nullable   => 0,
    locale        => "ja_JP",
    set_on_create => 1,
    timezone      => "Asia/Tokyo",
  },
  "updated_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    locale        => "ja_JP",
    original      => { default_value => \"now()" },
    timezone      => "Asia/Tokyo",
  },
  "album_id",
  { data_type => "integer", is_nullable => 0 },
  "column1",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "column2",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "column3",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "column4",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "column5",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("album_id", ["album_id", "name"]);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-06 01:18:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QTO85ch4NC0/rUV9FSzr3A

__PACKAGE__->belongs_to( album => "MyApp::Schema::Result::Album", "album_id" );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
