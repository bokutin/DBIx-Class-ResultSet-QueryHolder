package MyApp::Rose;

use strict;
use base qw(Rose::DB);

use MyApp::Container qw(container);

__PACKAGE__->register_db(
    %{ container("config")->get->{rose} },
);

1;
