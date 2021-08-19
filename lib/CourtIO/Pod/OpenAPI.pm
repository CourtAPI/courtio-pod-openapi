package CourtIO::Pod::OpenAPI;

# ABSTRACT: Parse OpenAPI Specification from POD

use Moo;
use strictures 2;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Carp::Assert::More qw(assert_nonblank);
use CourtIO::YAML::PP;
use CourtIO::YAML::PP::Schema::Include;
use Hash::Merge::Simple qw();
use Log::Log4perl ':easy';
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental;
use String::Util qw(hascontent);
use String::CamelCase qw(decamelize);
use namespace::clean;

has controller_name => ( is => 'ro' );

has document => (
  is       => 'ro',
  isa      => sub { $_[0]->isa('Pod::Elemental::Document') },
  required => 1
);

has include_paths => (
    is      => 'ro',
    default => sub { [] }
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

sub load_file ($class, $filename, %args) {
  my $document = Pod::Elemental->read_file($filename);

  $document = Pod::Elemental::Transformer::Pod5->new
    ->transform_node($document);

  my $controller_name = $filename =~ s|^.*?Controller/||r;
  $controller_name =~ s|/|::|g;
  $controller_name =~ s|\.pm$||;

  return $class->new(
    controller_name => $controller_name,
    document        => $document,
    %args
  );
}

sub extract_spec ($self) {
  my $api_spec = {};

  for my $node ($self->document->children->@*) {
    if ($self->is_openapi_node($node)) {
      my $spec = $self->parse_openapi_node($node);
      $api_spec = Hash::Merge::Simple::merge($api_spec, $spec);
    }
  }

  return $api_spec;
}

sub default_controller_path ($self, $path) {
  # we will replace leading "@/" with the default controller path
  if (hascontent($path)) {
    $path =~ s|^@/?||;
  }

  my $controller = $self->controller_name or return;

  my $controller_path = join '/',
    map { s/_/-/gr }
    map { decamelize($_) }
    split /::/, $controller;

  if (hascontent($path)) {
    $controller_path .= "/$path";
  }

  TRACE 'Computed default path: ', $controller_path;

  return "/$controller_path";
}

sub parse_openapi_node ($self, $node) {
  my %spec;

  my $path;

  for my $node ($node->children->@*) {
    TRACE 'Node: ', ref($node);
    if ($self->is_path_node($node)) {
      $path = $node->content;
      TRACE 'Found path: ', $path;
    }
    elsif ($self->is_common_parameters_node($node)) {
      TRACE 'Found common parameters node: ', $node->children->[0]->content;

      assert_nonblank($path, '=path must be set before using =for :parameters');

      if (my $data = $self->parse_common_parameters_node($node)) {
        $spec{$path}{parameters} = $data;
      }
    }
    elsif ($self->is_method_node($node)) {
      my $method = $node->format_name;
      TRACE 'Found method ', $method;

      if (not defined $path or $path =~ /^\@/) {
        $path = $self->default_controller_path($path);
      }

      # make sure we got a path
      assert_nonblank($path, '=path must be set before using =for :method');

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

sub is_openapi_node ($self, $node) {
  return $node->isa('Pod::Elemental::Element::Pod5::Region')
    && $node->format_name eq 'openapi';
}

sub is_path_node ($self, $node) {
  return $node->isa('Pod::Elemental::Element::Pod5::Command')
    && $node->command eq 'path';
}

sub is_common_parameters_node ($self, $node) {
  return 0 unless $node->isa('Pod::Elemental::Element::Pod5::Region');

  return $node->format_name eq 'parameters';
}

sub is_method_node ($self, $node) {
  return 0 unless $node->isa('Pod::Elemental::Element::Pod5::Region');

  for my $method (@POSSIBLE_METHODS) {
    return 1 if $node->format_name eq $method;
  }

  return 0;
}

sub parse_common_parameters_node ($self, $node) {
  my $content = $node->children->[0]->content;

  return $self->_yaml_pp->load_string($content);
}

sub parse_api_method_node ($self, $node) {
  # Everything after =for is a single child paragraph, up to blank line
  my $content = $node->children->[0]->content;

  my $data = $self->_yaml_pp->load_string($content);

  if (ref $data eq 'HASH') {
    $self->_expand_mojo_to($data);
  }

  return $data;
}

sub _yaml_pp ($self) {
  CourtIO::YAML::PP->new(paths => $self->include_paths);
}

sub _expand_mojo_to ($self, $spec) {
  my $mojo_to = $spec->{'x-mojo-to'};

  return unless defined $mojo_to;

  # can't expand unless we know the controller name
  my $controller_name = $self->controller_name or return;

  # mojo_to could be a string, an arrayref, or a hashref.
  # "x-mojo-to": "pet#list"
  # "x-mojo-to": {"controller": "pet", "action": "list", "foo": 123}
  # "x-mojo-to": ["pet#list", {"foo": 123}, ["format": ["json"]]]
  #

  unless (ref $mojo_to) {
    # its a plain string
    _expand_controller_reference(\$mojo_to, $controller_name);
  }
  elsif (ref $mojo_to eq 'HASH') {
    _expand_controller_reference( \($mojo_to->{controller}), $controller_name );
  }
  elsif (ref $mojo_to eq 'ARRAY') {
    _expand_controller_reference( \($mojo_to->[0]), $controller_name );
  }

  $spec->{'x-mojo-to'} = $mojo_to;
}

sub _expand_controller_reference {
  my ($value_ref, $controller_name) = @_;

  if ($$value_ref =~ /^@#?/) {
    $$value_ref =~ s/^@#?/${controller_name}#/;

    TRACE 'controller: ', $value_ref;
  }

  return $$value_ref;
}

1;

__END__
