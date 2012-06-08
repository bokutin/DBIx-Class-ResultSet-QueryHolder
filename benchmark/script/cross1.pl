use rlib qw(../lib ../../lib);

use Modern::Perl;

use Benchmark qw(:all);
use Data::Dumper;
use List::Flatten;
use List::Util qw(max);
use MyApp::Container qw(container);
use SQL::Format;

my @ARTIST_COLUMNS = (qw(id name created_at updated_at),           map { "column$_" } (1..10));
my @ALBUM_COLUMNS  = (qw(id name created_at updated_at artist_id), map { "column$_" } (1..20));
my @COVER_COLUMNS  = (qw(id name created_at updated_at album_id),  map { "column$_" } (1..5));

my $schema = container('schema');
my $teng = container('teng');
my $dbh = $schema->storage->dbh;
my $dm = container("dm");

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

sub bench_dm_columns {
    my $artist = $dm->table("Artist")->select(
        -columns   => [qw(id name)],
        -where     => { name => "artist1" },
        -result_as => 'firstrow',
    );
    my $albums = $artist->albums(
        -columns   => [qw(id name)],
        -order_by => ['name'],
    );
    for my $album (@$albums) {
        my $cover = $album->covers(
            -columns   => [qw(id name)],
            -where     => { name => "cover1" },
            -result_as => 'firstrow',
        );
        my $id = $cover->{id} or die;
    }
}

sub bench_dm_hand_join {
    my $artist = $dm->table("Artist")->select(
        -where     => { name => "artist1" },
        -result_as => 'firstrow',
    );
    my $albums = $dm->table("Album")->select(
        -where    => { artist_id => $artist->{id} },
        -order_by => ['name'],
    );
    for my $album (@$albums) {
        my $cover = $dm->table("Cover")->select(
            -where     => { album_id => $album->{id}, name => "cover1" },
            -result_as => 'firstrow',
        );
        my $id = $cover->{id} or die;
    }
}

sub bench_dm_sth {
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

sub bench_dm_sth_columns {
    my $name = do {
        state $count = 0;
        "artist" . ( 1 + $count++%2 );
    };
    state $artist_stmt = $dm->table("Artist")->select(
        -columns   => [qw(id name)],
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
        -columns   => [qw(id artist_id)],
        -order_by => ['name'],
    );
    my $albums = $albums_stmt->execute($artist)->all;
    for my $album (@$albums) {
        die unless $album->{artist_id} == $artist->{id};
        state $covers_stmt = $dm->table("Album")->join("covers")->prepare(
            -columns   => [qw(id album_id)],
            -where => { name => "cover1" },
        );
        my $cover = $covers_stmt->execute($album)->next;
        my $id = $cover->{id} or die;
        die unless $cover->{album_id} == $album->{id};
    }
}

sub bench_dm_sth_hand_join_no_slice {
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
        $artist_stmt->{sth}->fetchrow_arrayref;
    };
    die unless $artist->[1] eq $name;
    state $albums_stmt = $dm->table("Artist")->join("albums")->prepare(
        -order_by => ['name'],
    );
    my $albums = do {
        $albums_stmt->bind( id => $artist->[0] );
        $albums_stmt->execute;
        $albums_stmt->{sth}->fetchall_arrayref;
    };
    die unless @$albums == 20;
    for my $album (@$albums) {
        die unless $album->[4] == $artist->[0];
        state $covers_stmt = $dm->table("Album")->join("covers")->prepare(
            -where => { name => "cover1" },
        );
        my $cover = do {
            $covers_stmt->bind( id => $album->[0] );
            $covers_stmt->execute;
            $covers_stmt->{sth}->fetchrow_arrayref;
        };
        my $id = $cover->[0] or die;
        die unless $cover->[4] == $album->[0];
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
    $teng->suppress_row_objects(0);
    my $artist = $teng->single('artist',{name=>"artist1"}) or die;
    my @albums = $teng->search('album',{artist_id=>$artist->id},{order_by=>"name"});
    for my $album (@albums) {
        my $cover = $teng->single('cover',{album_id=>$album->id,name=>"cover1"}) or die;
        my $id = $cover->id or die;
    }
}

sub bench_teng_suppress_row_objects {
    $teng->suppress_row_objects(1);
    my $artist = $teng->single('artist',{name=>"artist1"}) or die;
    my @albums = $teng->search('album',{artist_id=>$artist->{id}},{order_by=>"name"});
    for my $album (@albums) {
        my $cover = $teng->single('cover',{album_id=>$album->{id},name=>"cover1"}) or die;
        my $id = $cover->{id} or die;
    }
}

sub bench_rose {
    require MyApp::Rose::Artist;

    my $artist = MyApp::Rose::Artist->new(name=>"artist1");
    $artist->load;
    my @albums = $artist->albums;
    die unless @albums == 20;
    for my $album (@albums) {
        $album->name or die;
        my @covers = $album->covers({name=>"cover1"});
        die unless @covers == 1;
        my $cover = $covers[0];
        $cover->load;
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
    bench_dm_columns                      => \&bench_dm_columns,
    bench_dm_hand_join                    => \&bench_dm_hand_join,
    bench_dm_sth                          => \&bench_dm_sth,
    bench_dm_sth_columns                  => \&bench_dm_sth_columns,
    bench_dm_sth_hand_join_no_slice       => \&bench_dm_sth_hand_join_no_slice,
    bench_rose                            => \&bench_rose,
    bench_sqlf                            => \&bench_sqlf,
    bench_sqlf_sth                        => \&bench_sqlf_sth,
    bench_teng                            => \&bench_teng,
    bench_teng_suppress_row_objects       => \&bench_teng_suppress_row_objects,
);

for my $name (sort keys %bench) {
    $bench{$name}->();
}

my $name_width = max(map { length } keys %bench);

#DB::enable_profile;
for my $name (sort keys %bench) {
    my $time = 2;
    my $t = countit($time, $bench{$name});
    say sprintf("%-${name_width}s: %s", $name, timestr($t));
}
#DB::disable_profile;

#foil bokutin % perl benchmark/script/cross1.pl  
#                           bench_dbic:  3 wallclock secs ( 2.12 usr +  0.04 sys =  2.16 CPU) @  20.83/s (n=45)
#                  bench_dbic_as_query:  3 wallclock secs ( 1.96 usr +  0.15 sys =  2.11 CPU) @ 126.54/s (n=267)
#         bench_dbic_as_query_foul_sth:  3 wallclock secs ( 1.92 usr +  0.18 sys =  2.10 CPU) @ 168.57/s (n=354)
#bench_dbic_as_query_foul_sth_no_slice:  6 wallclock secs ( 1.72 usr +  0.29 sys =  2.01 CPU) @ 323.38/s (n=650)
#                   bench_dbic_hashref:  2 wallclock secs ( 2.08 usr +  0.03 sys =  2.11 CPU) @  26.54/s (n=56)
#              bench_dbic_query_holder:  4 wallclock secs ( 1.95 usr +  0.15 sys =  2.10 CPU) @ 136.19/s (n=286)
#                             bench_dm:  3 wallclock secs ( 2.06 usr +  0.13 sys =  2.19 CPU) @  41.10/s (n=90)
#                     bench_dm_columns:  3 wallclock secs ( 1.93 usr +  0.14 sys =  2.07 CPU) @  45.89/s (n=95)
#                   bench_dm_hand_join:  3 wallclock secs ( 2.01 usr +  0.14 sys =  2.15 CPU) @  43.72/s (n=94)
#                         bench_dm_sth:  3 wallclock secs ( 2.01 usr +  0.14 sys =  2.15 CPU) @ 121.86/s (n=262)
#                 bench_dm_sth_columns:  3 wallclock secs ( 1.86 usr +  0.24 sys =  2.10 CPU) @ 264.76/s (n=556)
#      bench_dm_sth_hand_join_no_slice:  4 wallclock secs ( 1.88 usr +  0.27 sys =  2.15 CPU) @ 284.19/s (n=611)
#                           bench_rose:  4 wallclock secs ( 1.98 usr +  0.16 sys =  2.14 CPU) @  65.42/s (n=140)
#                           bench_sqlf:  4 wallclock secs ( 1.90 usr +  0.26 sys =  2.16 CPU) @  90.28/s (n=195)
#                       bench_sqlf_sth:  3 wallclock secs ( 2.05 usr +  0.13 sys =  2.18 CPU) @ 128.44/s (n=280)
#                           bench_teng:  4 wallclock secs ( 1.95 usr +  0.21 sys =  2.16 CPU) @  69.44/s (n=150)
#      bench_teng_suppress_row_objects:  4 wallclock secs ( 1.84 usr +  0.21 sys =  2.05 CPU) @  78.05/s (n=160)
