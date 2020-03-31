package Petshop::Controller::Pets;

=begin :openapi

=path /pets

=for :get
summary: List all pets
operationId: listPets
tags:
- pets
x-mojo-to: "@list"
parameters:
- name: limit
  in: query
  description: How many items to return at one time (max 100)
  required: false
  schema:
    type: integer
    format: int32
responses:
  '200':
    description: A paged array of pets
    headers:
      x-next:
        description: A link to the next page of responses
        schema:
          type: string
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/Pets"
  default:
    description: unexpected error
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/Error"

=for :post
summary: Create a pet
operationId: createPets
x-mojo-to: '@create'
tags:
- pets
responses:
  '201':
    description: Null response
  default:
    description: unexpected error
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/Error"

=end :openapi


=begin :openapi

=path /pets/{petId}

=for :get
summary: Info for a specific pet
operationId: showPetById
x-mojo-to: "@show"
tags:
- pets
parameters:
- name: petId
  in: path
  required: true
  description: The id of the pet to retrieve
  schema:
    type: string
responses:
  '200':
    description: Expected response to a valid request
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/Pet"
  default:
    description: unexpected error
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/Error"

=end :openapi

1;


