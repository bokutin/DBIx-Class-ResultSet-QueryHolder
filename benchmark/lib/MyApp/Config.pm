package MyApp::Config;

use Moose;
extends "Config::JFDI";

no Moose;
__PACKAGE__->meta->make_immutable;
