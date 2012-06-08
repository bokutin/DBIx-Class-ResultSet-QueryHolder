package MyApp::Rose::Cover;

use strict;
use base qw(MyApp::Base::Rose::Object);

__PACKAGE__->meta->setup(
    table => 'cover',
    auto  => 1,
);

1;
