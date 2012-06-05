use rlib qw(../lib ../../lib);
use Benchmark qw(:all);
use Data::Dumper;
use Modern::Perl;
use MyApp::Container qw(container);
use List::Util qw(max);
use List::Flatten;

my $schema = container('schema');
my $teng = container('teng');

sub bench_dbic {
    my @artists = $schema->resultset("Artist")->search({name=>[qw(artist1 artist2 artist3)]});
    die unless @artists == 3;
    for my $artist (@artists) {
        my @albums = $artist->albums(undef,{order_by=>"name"});
        for my $album (@albums) {
            my @covers = $album->covers({name=>"cover1"});
            die unless @covers == 1;
            my $id = $covers[0]->id or die;
        }
    }
}

sub bench_dbic_query_holder {
    state $artist_qh = $schema->resultset("Artist")->search({name=>[qw(artist1 artist2 artist3)]})->as_query_holder;
    $artist_qh->set_bind_value({name=>[qw(artist1 artist2 artist3)]});
    my @artists = flat $artist_qh->fetchall_arrayref({});
    die unless @artists == 3;
    for my $artist (@artists) {
        state $albums_qh = $schema->resultset("Album")->search({artist_id=>$artist->{id}},{order_by=>"name"})->as_query_holder;
        $albums_qh->set_bind_value({artist_id=>$artist->{id}});
        my @albums = flat $albums_qh->fetchall_arrayref({});
        for my $album (@albums) {
            state $covers_qh = $schema->resultset("Cover")->search({album_id=>$album->{id},name=>"cover1"})->as_query_holder;
            $covers_qh->set_bind_value({album_id=>$album->{id},name=>"cover1"});
            my @covers = flat $covers_qh->fetchall_arrayref({});
            die unless @covers == 1;
            my $id = $covers[0]->{id} or die;
        }
    }
}

sub bench_teng {
    my @artists = $teng->search('artist',{name=>[qw(artist1 artist2 artist3)]}) or die;
    die unless @artists == 3;
    for my $artist (@artists) {
        my @albums = $teng->search('album',{artist_id=>$artist->id},{order_by=>'name'});
        for my $album (@albums) {
            my $cover = $teng->single('cover',{album_id=>$album->id,name=>"cover1"}) or die;
            my $id = $cover->id or die;
        }
    }
}

my %bench = (
    bench_dbic              => \&bench_dbic,
    bench_dbic_query_holder => \&bench_dbic_query_holder,
    bench_teng              => \&bench_teng,
);

for my $name (sort keys %bench) {
    $bench{$name}->();
}

my $name_width = max(map { length } keys %bench);

for my $name (sort keys %bench) {
    my $time = 2;
    my $t = countit($time, $bench{$name});
    say sprintf("%${name_width}s: %s", $name, timestr($t));
}
