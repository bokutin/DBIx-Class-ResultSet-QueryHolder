use rlib "../lib";

use Data::Dumper;
use Modern::Perl;
use MyApp::Container qw(container);

#my $schema = container('schema');

#$schema->create(

my @items =
    map {
        +{
            name => "artist$_",
            (
                map {
                    ( "column$_" => "var$_" );
                } (1..10)
            ),
            albums => [
                map {
                    +{
                        name => "album$_",
                        (
                            map {
                                ( "column$_" => "var$_" );
                            } (1..20)
                        ),
                        covers => [
                            map {
                                +{
                                    name => "cover$_",
                                    (
                                        map {
                                            ( "column$_" => "var$_" );
                                        } (1..5)
                                    ),
                                };
                            } (1..4)
                        ],
                    };
                } (1..20)
            ],
        };
    } (1..100);

#$Data::Dumper::Sortkeys = 1;
#warn Dumper \@items;

local $| = 1;

for ( container('schema')->sources ) {
    container('schema')->resultset($_)->delete;
}

my $num_items = 0;
for my $item (@items) {
    container('schema')->resultset("Artist")->create($item);
    $num_items++;
    printf("\r%d/%d", $num_items, 0+@items);
}
print "\n";

for ( container('schema')->sources ) {
    say sprintf("%s: %d", $_, container('schema')->resultset($_)->count);
}
