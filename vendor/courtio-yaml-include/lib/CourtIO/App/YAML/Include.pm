package CourtIO::App::YAML::Include;
# ABSTRACT: YAML Include processor
$CourtIO::App::YAML::Include::VERSION = '0.07';
use strict;
use warnings;

use Moo;
use MooX::Cmd;
use MooX::Options;
use CourtIO::YAML::PP;
use File::Spec;
use Fatal 'open';
use JSON::XS;
use Log::Log4perl ':easy';

option file => (
  is       => 'ro',
  format   => 's',
  required => 1,
  short    => 'f',
  doc      => 'The YAML file to process'
);

option include => (
  is         => 'ro',
  format     => 's@',
  repeatable => 1,
  default    => sub { [] },
  short      => 'I',
  doc        => 'Include directories',
);

option output => (
  is      => 'ro',
  format  => 's',
  default => sub { '-' },
  short   => 'o',
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

  $self->_init_logger;

  # Make include dirs absolute
  my @include_dirs = map { File::Spec->rel2abs($_) } $self->include->@*;

  my $yaml_pp = CourtIO::YAML::PP->new(paths => \@include_dirs);

  my $data = $yaml_pp->load_file($self->file);

  my $output_string = $self->json
    ? JSON::XS->new->utf8->canonical->pretty->encode($data)
    : $yaml_pp->dump_string($data);

  if ($self->output eq '-') {
    print $output_string;
  }
  else {
    # TODO Encoding?
    open my $outfh, '>', $self->output;

    print $outfh $output_string;

    close $outfh;
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

CourtIO::App::YAML::Include - YAML Include processor

=head1 VERSION

version 0.07

=head1 AUTHOR

CourtAPI Team <support@courtapi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by CourtAPI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
