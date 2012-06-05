use rlib qw(../lib ../../lib);

use Modern::Perl;

use Benchmark qw(:all);
use Data::Dumper;
use List::Flatten;
use List::Util qw(max);
use MyApp::Container qw(container);
use SQL::Format;

my $schema = container('schema');
my $teng = container('teng');
my $dbh = $schema->storage->dbh;

sub bench_dbic {
    my $artist = $schema->resultset("Artist")->find({name=>"artist1"}) or die;
    my @albums = $artist->albums(undef,{order_by=>"name"});
    for my $album (@albums) {
        my @covers = $album->covers({name=>"cover1"});
        die unless @covers == 1;
        my $id = $covers[0]->id or die;
    }
}

sub bench_dbic_hashref {
    my $artist = $schema->resultset("Artist")->search({name=>"artist1"})->hashref_first or die;
    my @albums = $schema->resultset("Album")->search({artist_id=>$artist->{id}},{order_by=>"name"})->hashref_array;
    for my $album (@albums) {
        my @covers = $schema->resultset("Cover")->search({album_id=>$album->{id},name=>"cover1"})->hashref_array;
        die unless @covers == 1;
        my $id = $covers[0]->{id} or die;
    }
}

sub bench_dbic_query_holder {
    state $artist_qh = $schema->resultset("Artist")->search({name=>"artist1"})->as_query_holder;
    $artist_qh->set_bind_value({name=>"artist1"});
    my $artist = $artist_qh->fetchrow_hashref or die;
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

sub bench_dbic_as_query {
    state $dbh = $schema->storage->dbh;

    my @artists = do {
        state $query = $schema->resultset("Artist")->search({name=>"artist1"})->as_query;
        @{ $dbh->selectall_arrayref($$query->[0], { Slice => {} }, map { $_->[1] } @{$$query}[1..$#{$$query}]) };
    };
    for my $artist (@artists) {
        my @albums = do {
            state $query = $schema->resultset("Album")->search({artist_id=>$artist->{id}},{order_by=>"name"})->as_query;
            @{ $dbh->selectall_arrayref($$query->[0], { Slice => {} }, map { $_->[1] } @{$$query}[1..$#{$$query}]) };
        };
        for my $album (@albums) {
            my @covers = do {
                state $query = $schema->resultset("Cover")->search({album_id=>$album->{id},name=>"cover1"})->as_query;
                @{ $dbh->selectall_arrayref($$query->[0], { Slice => {} }, map { $_->[1] } @{$$query}[1..$#{$$query}]) };
            };
            die unless @covers == 1;
            my $id = $covers[0]->{id} or die;
        }
    }
}

sub bench_teng {
    my $artist = $teng->single('artist',{name=>"artist1"}) or die;
    my @albums = $teng->search('album',{artist_id=>$artist->id});
    for my $album (@albums) {
        my $cover = $teng->single('cover',{album_id=>$album->id,name=>"cover1"}) or die;
        my $id = $cover->id or die;
    }
}

sub bench_sqlf {
    local $SQL::Format::QUOTE_CHAR = '"';
    my $artist = do {
        my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
            [qw(id name), map { "column$_" } (1..10)],
            'artist',
            {
                name => "artist1",
            },
        );
        my $sth = $dbh->prepare($stmt) or die;
        $sth->execute(@bind);
        $sth->fetchrow_hashref;
    } or die;
    my @albums = do {
        my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w %o' => (
            [qw(id name artist_id), map { "column$_" } (1..20)],
            'album',
            {
                artist_id => $artist->{id},
            },
            {
                order_by => "name",
            },
        );
        my $sth = $dbh->prepare($stmt) or die;
        $sth->execute(@bind);
        flat $sth->fetchall_arrayref({});
    }; 
    for my $album (@albums) {
        my $cover = do {
            my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
                [qw(id name album_id), map { "column$_" } (1..5)],
                'cover',
                {
                    album_id => $album->{id},
                    name     => "cover1",
                },
            );
            my $sth = $dbh->prepare($stmt) or die;
            $sth->execute(@bind);
            $sth->fetchrow_hashref;
        };
        my $id = $cover->{id} or die;
    }
}

sub bench_sqlf_sth {
    local $SQL::Format::QUOTE_CHAR = '"';
    my $artist = do {
        my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
            [qw(id name), map { "column$_" } (1..10)],
            'artist',
            {
                name => "artist1",
            },
        );
        state $sth = $dbh->prepare($stmt) or die;
        $sth->execute(@bind);
        $sth->fetchrow_hashref;
    } or die;
    my @albums = do {
        my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w %o' => (
            [qw(id name artist_id), map { "column$_" } (1..20)],
            'album',
            {
                artist_id => $artist->{id},
            },
            {
                order_by => "name",
            },
        );
        state $sth = $dbh->prepare($stmt) or die;
        $sth->execute(@bind);
        flat $sth->fetchall_arrayref({});
    }; 
    for my $album (@albums) {
        my $cover = do {
            my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
                [qw(id name album_id), map { "column$_" } (1..5)],
                'cover',
                {
                    album_id => $album->{id},
                    name     => "cover1",
                },
            );
            state $sth = $dbh->prepare($stmt) or die;
            $sth->execute(@bind);
            $sth->fetchrow_hashref;
        };
        my $id = $cover->{id} or die;
    }
}

my %bench = (
    bench_dbic              => \&bench_dbic,
    bench_dbic_hashref      => \&bench_dbic_hashref,
    bench_dbic_query_holder => \&bench_dbic_query_holder,
    bench_dbic_as_query     => \&bench_dbic_as_query,
    bench_teng              => \&bench_teng,
    bench_sqlf              => \&bench_sqlf,
    bench_sqlf_sth          => \&bench_sqlf_sth,
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

#foil bokutin % perl benchmark/script/cross1.pl
#             bench_dbic:  2 wallclock secs ( 1.96 usr +  0.04 sys =  2.00 CPU) @ 21.00/s (n=42)
#    bench_dbic_as_query:  3 wallclock secs ( 1.89 usr +  0.14 sys =  2.03 CPU) @ 128.57/s (n=261)
#     bench_dbic_hashref:  3 wallclock secs ( 2.20 usr +  0.04 sys =  2.24 CPU) @ 26.79/s (n=60)
#bench_dbic_query_holder:  4 wallclock secs ( 1.93 usr +  0.15 sys =  2.08 CPU) @ 137.50/s (n=286)
#             bench_sqlf:  4 wallclock secs ( 1.85 usr +  0.25 sys =  2.10 CPU) @ 95.24/s (n=200)
#         bench_sqlf_sth:  2 wallclock secs ( 1.94 usr +  0.14 sys =  2.08 CPU) @ 134.62/s (n=280)
#             bench_teng:  4 wallclock secs ( 1.93 usr +  0.20 sys =  2.13 CPU) @ 70.42/s (n=150)
