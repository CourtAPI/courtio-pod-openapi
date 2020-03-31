package CourtIO::Pod::OpenAPI::App::PodToOpenAPI;

use strictures 2;

use Moo;
use MooX::Cmd;
use MooX::Options;
use Log::Log4perl ':easy';
use File::Find::Rule;

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

option trace => (
  is      => 'ro',
  default => sub { 0 },
  doc     => 'Enable trace logging'
);

sub execute {
  my $self = shift;

  my @files = File::Find::Rule->file
    ->name( '*.pm' )
    ->in( $self->directory );

  for my $file (@files) {
    $self->_process_file($file);
  }
}

sub _process_file {
  my ($self, $filename) = @_;

  TRACE 'Processing file: ', $filename;
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
