use rlib "../lib";

use Modern::Perl;

use DBIx::Class::Schema::Loader qw(make_schema_at);
use MyApp::Container qw(container);

make_schema_at(
    'MyApp::Schema',
    {
        #debug => 1,
        #constraint => '^foo.*',
        dump_directory => './benchmark/lib',

        components => [
            "InflateColumn::Serializer",
            "TimeStamp"
        ],
        custom_column_info => sub {
            my ($table, $name, $info) = @_;

            if ( $name eq "created_at" ) {
                return { set_on_create => 1 };
            }
            elsif ( $name eq "misc_data" ) {
                return { serializer_class => 'JSON::Pretty', dynamic_default_on_update => "_misc_data_default" };
            }
            elsif ( $info->{data_type} eq "text" ) {
                # 本当はMySQL側で DEFAULT '' としいが、MySQLのtextタイプにはデフォルト値が指定できない。
                # ORM層以上では、text のカラムが明示的に "" としなくても作成できるようにする。
                return { %$info, default_value => "" };
            }
        },
        datetime_timezone => "Asia/Tokyo",
        datetime_locale   => "ja_JP",
        default_resultset_class => "+MyApp::Base::DBIx::Class::ResultSet",
        #dump_directory => "var/schema_loader_dump",
        generate_pod => 0,
        #moniker_map => {
        #    shop_bbs_article => "ShopBBSArticle",
        #},
        naming => { relationships => 'v7', monikers => 'v7' },
        result_base_class => "MyApp::Base::DBIx::Class::Core",
        #result_component_map => {
        #    Area             => [ "Ordered" ],
        #    Girl             => [ "Ordered" ],
        #    GirlQuestion     => [ "Ordered" ],
        #    GirlScheduleSpan => [ "Result::Validation" ],
        #    ShopCategory     => [ "Ordered" ],
        #    ShopLink         => [ "Ordered", "Result::Validation" ],
        #},
        use_moose => 1,
        use_namespaces => 1,
    },
    [ 
        container('config')->get->{'Model::DBIC'}{connect_info},
    ],
);
