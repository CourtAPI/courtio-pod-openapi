package CourtIO::Pod::OpenAPI::App::PodToOpenAPI;

use strictures 2;

use Moo;
use MooX::Cmd;
use MooX::Options;

use feature qw(signatures);
no warnings qw(experimental::signatures);

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

sub execute ($self, @args) {
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

sub encode ($self) {
  if ($self->json) {
    return $self->_json_maybexs->encode( $self->openapi_spec );
  }
  else {
    return $self->_yaml_pp->dump_string( $self->openapi_spec );
  }
}

sub _process_file ($self, $filename) {
  TRACE 'Processing file: ', $filename;
  my $parser = CourtIO::Pod::OpenAPI->load_file($filename);

  my $spec = $parser->extract_spec;

  while (my ($path, $spec) = each %$spec) {
    $self->openapi_spec->{$path} = $spec;
  }
}

sub _init_logger ($self) {
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
