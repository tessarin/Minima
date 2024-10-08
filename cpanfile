requires perl, '5.40.0';
requires 'File::Share', '0.27';
requires 'Hash::MultiValue', '0.16';
requires 'Path::Tiny', '0.142';
requires 'Plack', '1.0050';
requires 'Router::Simple', '0.17';
requires 'Template', '3.100';

on 'configure' => sub {
    requires 'Module::Build', '0.42';
};

on 'test' => sub {
    requires 'Data::Dumper', '2.1';
    requires 'HTTP::Request::Common', '6.0';
};
