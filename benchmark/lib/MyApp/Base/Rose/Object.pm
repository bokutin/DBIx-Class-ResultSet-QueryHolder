package MyApp::Base::Rose::Object;

use MyApp::Container qw(container);
use MyApp::Rose;

use base qw(Rose::DB::Object);

sub init_db {
    MyApp::Rose->new;
}

1;
