use rlib "../lib";

use Modern::Perl;

use DBIx::DataModel::Schema::Generator;
use MyApp::Container qw(container);

my $generator = DBIx::DataModel::Schema::Generator->new("-schema" => "MyApp::DataModel::Schema");
say $generator->fromDBIxClass(container('schema'));
