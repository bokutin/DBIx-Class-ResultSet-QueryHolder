+{
    "Model::DBIC" => {
        connect_info => {
            dsn => "dbi:Pg:dbname=myapp",
            user => "foo",
            password => "",
            pg_enable_utf8 => 1,
            quote_names => 1,
        },
    },
    "View::Mason2" => {
        autoextend_request_path => 0,
        comp_root => '__path_to(root/comps)__',
    },
};
