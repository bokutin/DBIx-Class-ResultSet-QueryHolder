use rlib "../lib";

use Modern::Perl;
use MyApp::Container qw(container);

main: {
    my $mason = container('mason');
    my $out = $mason->run('/sql/generate.mc')->output;
};
