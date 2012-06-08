package MyApp::Rose::Album;

use strict;
use base qw(MyApp::Base::Rose::Object);

__PACKAGE__->meta->setup(
    table => 'album',
    auto  => 1,

   relationships =>
      [
        covers =>
        {
          type       => 'one to many',
          class      => 'MyApp::Rose::Cover',
          column_map => { id => 'album_id' },
        },
      ],
);

1;
