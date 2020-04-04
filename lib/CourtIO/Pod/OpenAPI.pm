package CourtIO::Pod::OpenAPI;
$CourtIO::Pod::OpenAPI::VERSION = '0.05';
# ABSTRACT: Parse OpenAPI Specification from POD

use Moo;
use strictures 2;

use Carp::Assert::More qw(assert_nonblank);
use Hash::Merge::Simple qw();
use Log::Log4perl ':easy';
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental;
use YAML::PP;
use namespace::clean;

has controller_name => ( is => 'ro' );

has document => (
  is       => 'ro',
  isa      => sub { $_[0]->isa('Pod::Elemental::Document') },
  required => 1
);

has _yaml_pp => (
  is      => 'ro',
  default => sub {
    YAML::PP->new(
      schema   => ['JSON'],
      boolean  => 'JSON::PP',
    );
  }
);

my @POSSIBLE_METHODS = qw(
  get
  put
  post
  patch
  delete
  options
  head
  trace
);

sub load_file {
  my ($class, $filename) = @_;

  my $document = Pod::Elemental->read_file($filename);

  $document = Pod::Elemental::Transformer::Pod5->new
    ->transform_node($document);

  my $controller_name = $filename =~ s|^.*?Controller/||r;
  $controller_name =~ s|/|::|g;
  $controller_name =~ s|\.pm$||;

  return $class->new(
    controller_name => $controller_name,
    document        => $document,
  );
}

sub extract_spec {
  my $self = shift;

  my $api_spec = {};

  for my $node ($self->document->children->@*) {
    if ($self->is_openapi_node($node)) {
      my $spec = $self->parse_openapi_node($node);
      $api_spec = Hash::Merge::Simple::merge($api_spec, $spec);
    }
  }

  return $api_spec;
}

sub parse_openapi_node {
  my ($self, $node) = @_;

  my %spec;

  my $path;

  for my $node ($node->children->@*) {
    if ($self->is_path_node($node)) {
      $path = $node->content;
      TRACE 'Found path: ', $path;
    }
    elsif ($self->is_method_node($node)) {
      assert_nonblank($path, '=path must be set before using =for :method');

      my $method = $node->format_name;
      TRACE 'Found method ', $method;

      if (my $data = $self->parse_api_method_node($node)) {
        $spec{$path}{$method} = $data;
      }
    }
  }

  # Do some sanity checking on what we parsed.
  unless (keys %spec) {
    # TODO dump the content?
    ERROR 'No OpenAPI specs were found in this node';
    ERROR map { $_->content } $node->children->@*;
  }

  # =path something was seen, but no =for :method was seen after it
  if (defined $path and not defined $spec{$path}) {
    ERROR "=path $path was encountered, but no methods were found for it.";
  }

  return \%spec;
}

sub is_openapi_node {
  my ($self, $node) = @_;

  return $node->isa('Pod::Elemental::Element::Pod5::Region')
    && $node->format_name eq 'openapi';
}

sub is_path_node {
  my ($self, $node) = @_;

  return $node->isa('Pod::Elemental::Element::Pod5::Command')
    && $node->command eq 'path';
}

sub is_method_node {
  my ($self, $node) = @_;

  return 0 unless $node->isa('Pod::Elemental::Element::Pod5::Region');

  for my $method (@POSSIBLE_METHODS) {
    return 1 if $node->format_name eq $method;
  }

  return 0;
}

sub parse_api_method_node {
  my ($self, $node) = @_;

  # Everything after =for is a single child paragraph, up to blank line
  my $content = $node->children->[0]->content;

  my $data = $self->_yaml_pp->load_string($content);

  if (ref $data eq 'HASH') {
    $self->_expand_mojo_to($data);
  }

  return $data;
}

sub _expand_mojo_to {
  my ($self, $spec) = @_;

  my $mojo_to = $spec->{'x-mojo-to'};

  return unless defined $mojo_to;

  # can't expand unless we know the controller name
  my $controller_name = $self->controller_name or return;

  if ($mojo_to =~ /^@#?/) {
    $mojo_to =~ s/^@#?/${controller_name}#/;

    TRACE 'x-mojo-to: ', $mojo_to;

    $spec->{'x-mojo-to'} = $mojo_to;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CourtIO::Pod::OpenAPI - Parse OpenAPI Specification from POD

=head1 VERSION

version 0.05

=head1 AUTHOR

CourtAPI Team <support@courtapi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by CourtAPI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
