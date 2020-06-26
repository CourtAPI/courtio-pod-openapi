package CourtIO::YAML::PP;
$CourtIO::YAML::PP::VERSION = '0.07';
# ABSTRACT: YAML::PP with CourtIO::YAML::PP::Schema::Include

use strict;
use warnings;

use parent 'YAML::PP';

use YAML::PP::Common;
use CourtIO::YAML::PP::Schema::Include;

# extend new() to auto register CourtIO::YAML::PP::Schema::Include
sub new {
  my ($class, %args) = @_;

  my $include = CourtIO::YAML::PP::Schema::Include->new(%args);

  my $self = $class->SUPER::new(
    schema   => ['JSON', $include],
    boolean  => 'JSON::PP',
  );

  $include->yaml_pp($self);

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CourtIO::YAML::PP - YAML::PP with CourtIO::YAML::PP::Schema::Include

=head1 VERSION

version 0.07

=head1 AUTHOR

CourtAPI Team <support@courtapi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by CourtAPI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
