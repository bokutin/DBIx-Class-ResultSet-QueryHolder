package MyApp::Teng::Schema;

use Teng::Schema::Declare;

table {
    name 'artist';
    pk 'id';
    columns qw(id name created_at updated_at), map { "column$_" } (1..10);
};

table {
    name 'album';
    pk 'id';
    columns qw(id name created_at updated_at artist_id), map { "column$_" } (1..20);
};

table {
    name 'cover';
    pk 'id';
    columns qw(id name created_at updated_at album_id), map { "column$_" } (1..5);
};

1;
