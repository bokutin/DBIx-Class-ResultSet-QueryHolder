package MyApp::Rose::Artist;

use strict;
use base qw(MyApp::Base::Rose::Object);

__PACKAGE__->meta->setup(
    table => 'artist',
    auto  => 1,

   relationships =>
      [
        albums =>
        {
          type       => 'one to many',
          class      => 'MyApp::Rose::Album',
          column_map => { id => 'artist_id' },
        },
      ],
);

1;
