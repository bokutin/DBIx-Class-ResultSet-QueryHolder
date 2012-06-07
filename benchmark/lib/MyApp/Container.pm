package MyApp::Container;

use strict;
use warnings;

use Class::Load qw(load_class);
use File::Spec::Functions ':ALL';
use Object::Container '-base';

register "config" => sub {
    require MyApp::Config;
    my $path_to = catdir( (splitpath(__FILE__))[1], "../.." );
    MyApp::Config->new( name => "myapp", path_to => $path_to, path => "$path_to/etc" );
};

register "dm" => sub {
    my $self = shift;

    my $class = "MyApp::DataModel::Schema";
    my $dbh = $self->get("schema")->storage->dbh;

    load_class($class);
    $class->dbh($dbh);
    $class;
};

register "dtx" => sub {
    require DateTimeX::Web;
    my $dtx = DateTimeX::Web->new(time_zone => 'Asia/Tokyo', locale => "ja");
};

register "mason" => sub {
    my $self = shift;

    my $config = $self->get("config");

    require Mason;
    my %args = %{$config->get->{"View::Mason2"}};
    push @{$args{allow_globals}}, '$c';
    my $mason = Mason->new(%args);
};

register "schema" => sub {
    my $self = shift;

    require MyApp::Schema;
    my $config = $self->get("config");
    my $schema = MyApp::Schema->connect($config->get->{"Model::DBIC"}{connect_info});
};

register "teng" => sub {
    my $self = shift;

    require MyApp::Teng;
    my $dbh = $self->get("schema")->storage->dbh;
    my $db = MyApp::Teng->new(dbh=>$dbh);
};

1;
