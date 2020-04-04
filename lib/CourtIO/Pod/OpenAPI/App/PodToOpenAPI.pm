package CourtIO::Pod::OpenAPI::App::PodToOpenAPI;
$CourtIO::Pod::OpenAPI::App::PodToOpenAPI::VERSION = '0.05';
use strictures 2;

use Moo;
use MooX::Cmd;
use MooX::Options;

use CourtIO::Pod::OpenAPI;
use Fatal qw(open);
use File::Find::Rule;
use Log::Log4perl ':easy';

option directory => (
  is       => 'ro',
  format   => 's',
  required => 1,
  short    => 'd',
  doc      => 'Base directory of .pm files to scan'
);

option output => (
  is      => 'ro',
  format  => 's',
  short   => 'o',
  default => sub { '-' },
  doc     => 'outfile, default is to print to stdout'
);

option json => (
  is      => 'ro',
  default => sub { 0 },
  doc     => 'Output JSON instead of YAML'
);

option pretty => (
  is      => 'ro',
  default => sub { 0 },
  doc     => 'Enable pretty JSON mode'
);

option trace => (
  is      => 'ro',
  default => sub { 0 },
  doc     => 'Enable trace logging'
);

has openapi_spec => (
  is      => 'rw',
  default => sub { {} }
);

has _json_maybexs => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;

    require JSON::MaybeXS;

    my $json = JSON::MaybeXS->new->canonical->utf8;

    if ($self->pretty) {
      $json->pretty;
    }

    return $json;
  }
);

has _yaml_pp => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require YAML::PP;
    require YAML::PP::Common;

    return YAML::PP->new(
      schema   => ['JSON'],
      boolean  => 'JSON::PP',
    );
  }
);

sub execute {
  my $self = shift;

  $self->_init_logger;

  my @files = File::Find::Rule->file
    ->name( '*.pm' )
    ->in( $self->directory );

  for my $file (@files) {
    $self->_process_file($file);
  }

  my $output = $self->encode;

  if ($self->output eq '-') {
    print $output;
  }
  else {
    open my $fh, '>', $self->output;

    print $fh $output;

    close $fh;
  }
}

sub encode {
  my $self = shift;

  if ($self->json) {
    return $self->_json_maybexs->encode( $self->openapi_spec );
  }
  else {
    return $self->_yaml_pp->dump_string( $self->openapi_spec );
  }
}

sub _process_file {
  my ($self, $filename) = @_;

  TRACE 'Processing file: ', $filename;
  my $parser = CourtIO::Pod::OpenAPI->load_file($filename);

  my $spec = $parser->extract_spec;

  while (my ($path, $spec) = each %$spec) {
    $self->openapi_spec->{$path} = $spec;
  }
}

sub _init_logger {
  my $self = shift;

  Log::Log4perl::init_once(\<<~'END');
    log4perl.logger = INFO, Screen

    # Setup screen appender that colours levels
    log4perl.appender.Screen          = Log::Log4perl::Appender::ScreenColoredLevels
    log4perl.appender.Screen.utf8     = 1
    log4perl.appender.Screen.layout   = PatternLayout

    # [PID] file-line: LEVEL message
    log4perl.appender.Screen.layout.ConversionPattern = %d [%P] %F{2}-%L: %p %m%n
  END

  if ($self->trace) {
    INFO 'TRACE logging enabled';
    Log::Log4perl::get_logger('')->more_logging(5);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CourtIO::Pod::OpenAPI::App::PodToOpenAPI

=head1 VERSION

version 0.05

=head1 AUTHOR

CourtAPI Team <support@courtapi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by CourtAPI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
