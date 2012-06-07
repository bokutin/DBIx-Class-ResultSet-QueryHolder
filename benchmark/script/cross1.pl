use rlib qw(../lib ../../lib);

use Modern::Perl;

use Benchmark qw(:all);
use Data::Dumper;
use List::Flatten;
use List::Util qw(max);
use MyApp::Container qw(container);
use SQL::Format;

my @ARTIST_COLUMNS = (qw(id name), map { "column$_" } (1..10));
my @ALBUM_COLUMNS  = (qw(id name artist_id), map { "column$_" } (1..20));
my @COVER_COLUMNS  = (qw(id name album_id), map { "column$_" } (1..5));

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

sub bench_dm {
    my $dm = container("dm");

    my $artist = $dm->table("Artist")->select(
        -where     => { name => "artist1" },
        -result_as => 'firstrow',
    );
    my $albums = $artist->albums(
        -order_by => ['name'],
    );
    for my $album (@$albums) {
        my $cover = $album->covers(
            -where     => { name => "cover1" },
            -result_as => 'firstrow',
        );
        my $id = $cover->{id} or die;
    }
}

sub bench_dm_sth {
    my $dm = container("dm");

    my $name = do {
        state $count = 0;
        "artist" . ( 1 + $count++%2 );
    };
    state $artist_stmt = $dm->table("Artist")->select(
        -where     => { name => "?:name" },
        -result_as => 'fast_statement',
    );
    my $artist = do {
        $artist_stmt->bind( name => $name );
        $artist_stmt->execute;
        $artist_stmt->next;
    };
    die unless $artist->{name} eq $name;
    state $albums_stmt = $dm->table("Artist")->join("albums")->prepare(
        -order_by => ['name'],
    );
    my $albums = $albums_stmt->execute($artist)->all;
    for my $album (@$albums) {
        die unless $album->{artist_id} == $artist->{id};
        state $covers_stmt = $dm->table("Album")->join("covers")->prepare(
            -where => { name => "cover1" },
        );
        my $cover = $covers_stmt->execute($album)->next;
        my $id = $cover->{id} or die;
        die unless $cover->{album_id} == $album->{id};
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

sub bench_dbic_as_query_foul_sth {
    my @artists = do {
        state $sth = do {
            my $query = $schema->resultset("Artist")->search({name=>"artist1"})->as_query;
            my $sth = $dbh->prepare($$query->[0]);
            $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
            $sth;
        };
        $sth->execute or die;
        @{ $sth->fetchall_arrayref({}) };
    };
    for my $artist (@artists) {
        my @albums = do {
            state $sth = do {
                my $query = $schema->resultset("Album")->search({artist_id=>$artist->{id}},{order_by=>"name"})->as_query;
                my $sth = $dbh->prepare($$query->[0]);
                $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
                $sth;
            };
            $sth->execute or die;
            @{ $sth->fetchall_arrayref({}) };
        };
        for my $album (@albums) {
            my @covers = do {
                state $sth = do {
                    my $query = $schema->resultset("Cover")->search({album_id=>$album->{id},name=>"cover1"})->as_query;
                    my $sth = $dbh->prepare($$query->[0]);
                    $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
                    $sth;
                };
                $sth->execute or die;
                @{ $sth->fetchall_arrayref({}) };
            };
            die unless @covers == 1;
            my $id = $covers[0]->{id} or die;
        }
    }
}

sub bench_dbic_as_query_foul_sth_no_slice {
    my @artists = do {
        state $sth = do {
            my $query = $schema->resultset("Artist")->search({name=>"artist1"})->as_query;
            my $sth = $dbh->prepare($$query->[0]);
            $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
            $sth;
        };
        $sth->execute or die;
        @{ $sth->fetchall_arrayref() };
    };
    for my $artist (@artists) {
        my @albums = do {
            state $sth = do {
                my $query = $schema->resultset("Album")->search({artist_id=>$artist->[0]},{order_by=>"name"})->as_query;
                my $sth = $dbh->prepare($$query->[0]);
                $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
                $sth;
            };
            $sth->execute or die;
            @{ $sth->fetchall_arrayref() };
        };
        for my $album (@albums) {
            my @covers = do {
                state $sth = do {
                    my $query = $schema->resultset("Cover")->search({album_id=>$album->[0],name=>"cover1"})->as_query;
                    my $sth = $dbh->prepare($$query->[0]);
                    $sth->bind_param($_, $$query->[$_][1]) for (1..$#{$$query});
                    $sth;
                };
                $sth->execute or die;
                @{ $sth->fetchall_arrayref() };
            };
            die unless @covers == 1;
            my $id = $covers[0]->[0] or die;
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
            \@ARTIST_COLUMNS,
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
            \@ALBUM_COLUMNS,
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
                \@COVER_COLUMNS,
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
            \@ARTIST_COLUMNS,
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
            \@ALBUM_COLUMNS,
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
                \@COVER_COLUMNS,
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
    bench_dbic                            => \&bench_dbic,
    bench_dbic_as_query                   => \&bench_dbic_as_query,
    bench_dbic_as_query_foul_sth          => \&bench_dbic_as_query_foul_sth,
    bench_dbic_as_query_foul_sth_no_slice => \&bench_dbic_as_query_foul_sth_no_slice,
    bench_dbic_hashref                    => \&bench_dbic_hashref,
    bench_dbic_query_holder               => \&bench_dbic_query_holder,
    bench_dm                              => \&bench_dm,
    bench_dm_sth                          => \&bench_dm_sth,
    bench_sqlf                            => \&bench_sqlf,
    bench_sqlf_sth                        => \&bench_sqlf_sth,
    bench_teng                            => \&bench_teng,
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
#                           bench_dbic:  2 wallclock secs ( 2.10 usr +  0.04 sys =  2.14 CPU) @  21.03/s (n=45)
#                  bench_dbic_as_query:  4 wallclock secs ( 1.96 usr +  0.13 sys =  2.09 CPU) @ 129.19/s (n=270)
#         bench_dbic_as_query_foul_sth:  4 wallclock secs ( 1.92 usr +  0.17 sys =  2.09 CPU) @ 171.77/s (n=359)
#bench_dbic_as_query_foul_sth_no_slice:  6 wallclock secs ( 1.87 usr +  0.31 sys =  2.18 CPU) @ 323.85/s (n=706)
#                   bench_dbic_hashref:  3 wallclock secs ( 2.08 usr +  0.04 sys =  2.12 CPU) @  26.89/s (n=57)
#              bench_dbic_query_holder:  3 wallclock secs ( 1.92 usr +  0.15 sys =  2.07 CPU) @ 138.16/s (n=286)
#                             bench_dm:  3 wallclock secs ( 2.01 usr +  0.12 sys =  2.13 CPU) @  38.97/s (n=83)
#                         bench_dm_sth:  3 wallclock secs ( 1.95 usr +  0.14 sys =  2.09 CPU) @ 133.97/s (n=280)
#                           bench_sqlf:  4 wallclock secs ( 1.89 usr +  0.27 sys =  2.16 CPU) @  97.22/s (n=210)
#                       bench_sqlf_sth:  3 wallclock secs ( 2.00 usr +  0.14 sys =  2.14 CPU) @ 139.72/s (n=299)
#                           bench_teng:  3 wallclock secs ( 1.92 usr +  0.19 sys =  2.11 CPU) @  70.62/s (n=149)
