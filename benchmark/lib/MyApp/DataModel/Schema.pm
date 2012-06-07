package MyApp::DataModel::Schema;

use strict;
use warnings;
use DBIx::DataModel;

DBIx::DataModel  # no semicolon (intentional)

#---------------------------------------------------------------------#
#                         SCHEMA DECLARATION                          #
#---------------------------------------------------------------------#
->Schema('MyApp::DataModel::Schema')

#---------------------------------------------------------------------#
#                         TABLE DECLARATIONS                          #
#---------------------------------------------------------------------#
#          Class  Table  PK
#          =====  =====  ==
->Table(qw/Album  album  id/)
->Table(qw/Cover  cover  id/)
->Table(qw/Artist artist id/)

#---------------------------------------------------------------------#
#                      ASSOCIATION DECLARATIONS                       #
#---------------------------------------------------------------------#
#     Class  Role    Mult Join     
#     =====  ====    ==== ====     
->Association(
  [qw/Artist artist  1    id       /],
  [qw/Album  albums  *    artist_id/])

->Association(
  [qw/Album  album   1    id       /],
  [qw/Cover  covers  *    album_id /])

;

#---------------------------------------------------------------------#
#                             COLUMN TYPES                            #
#---------------------------------------------------------------------#
# MyApp::DataModel::Schema->ColumnType(ColType_Example =>
#   fromDB => sub {...},
#   toDB   => sub {...});

# MyApp::DataModel::Schema::SomeTable->ColumnType(ColType_Example =>
#   qw/column1 column2 .../);

# timestamp
#MyApp::DataModel::Schema->ColumnType(timestamp =>
#  fromDB => sub {},   # SKELETON .. PLEASE FILL IN
#  toDB   => sub {});
#MyApp::DataModel::Schema::Album->ColumnType(timestamp => qw/created_at updated_at/);
#MyApp::DataModel::Schema::Cover->ColumnType(timestamp => qw/created_at updated_at/);
#MyApp::DataModel::Schema::Artist->ColumnType(timestamp => qw/created_at updated_at/);



1;
