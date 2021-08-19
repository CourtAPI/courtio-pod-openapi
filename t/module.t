#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::PP;
use Test::Deep;

use_ok('CourtIO::Pod::OpenAPI') or exit 1;

my $pod_parser = CourtIO::Pod::OpenAPI->load_file('t/data/Petshop/Controller/Pets.pm');

isa_ok $pod_parser, 'CourtIO::Pod::OpenAPI';

my $spec = $pod_parser->extract_spec;
isa_ok $spec, 'HASH';

cmp_deeply(
  $spec,
  {
    '/pets/{petId}' => {
      parameters  => [
        {
          name        => 'petId',
          in          => 'path',
          required    => JSON::PP::true,
          description => 'The id of the pet to retrieve',
          schema      => { type => 'string' }
        }
      ],
      get => {
        summary     => 'Info for a specific pet',
        operationId => 'showPetById',
        'x-mojo-to' => [ 'Pets#show', {}, [ "format", ["json"] ] ],
        tags        => [ 'pets' ],
        responses => {
          200 => {
            description => 'Expected response to a valid request',
            content     => {
              'application/json' => {
                schema => {
                  '$ref' => '#/components/schemas/Pet'
                }
              }
            }
          },
          default => {
            description => 'unexpected error',
            content => {
              'application/json' => {
                schema => {
                  '$ref' => '#/components/schemas/Error'
                }
              }
            }
          },
        },
      }
    },
    '/pets' => {
      get => {
        summary     => 'List all pets',
        operationId => 'listPets',
        'x-mojo-to' => 'Pets#list',
        tags        => [ 'pets' ],
        parameters  => [
          {
            name        => 'limit',
            in          => 'query',
            description => 'How many items to return at one time (max 100)',
            required    => JSON::PP::false,
            schema      => {
              type   => 'integer',
              format => 'int32'
            }
          }
        ],
        responses => {
          200 => {
            description => 'A paged array of pets',
            headers => {
              'x-next' => {
                description => 'A link to the next page of responses',
                schema => {
                  type => 'string'
                }
              }
            },
            content => {
              'application/json' => {
                schema => {
                  '$ref' => '#/components/schemas/Pets'
                }
              }
            }
          },
          default => {
            description => 'unexpected error',
            content => {
              'application/json' => {
                schema => {
                  '$ref' => '#/components/schemas/Error'
                }
              }
            }
          },
        },
      },
      post => {
        summary     => 'Create a pet',
        operationId => 'createPets',
        'x-mojo-to' => 'Pets#create',
        tags        => [ 'pets' ],
        responses   => {
          201 => {
            description => 'Null response'
          },
          default => {
            description => 'unexpected error',
            content     => {
              'application/json' => {
                'schema' => {
                  '$ref' => '#/components/schemas/Error'
                }
              }
            }
          }
        },
      }
    }
  },
  'Got expected OpenAPI spec'
);

done_testing;
