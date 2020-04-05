# Developer Notes

This module uses `Dist::Zilla` for builds. If needed, install it with:

```
$ cpanm -q --notest Dist::Zilla
```

And then install any plugins needed with:

```
dzil authordeps --missing | xargs cpanm -q --notest
```

## Running Tests:

Tests can be run with `dzil`:

```
dzil test -v
```

Extra tests can be enabled with `--author`

## Buliding an unpublished docker image

You can build the distribution bundle with:

```
dzil build
```

Then `cd` into the `CourtIO::Pod::OpenAPI-X.YY` directory.

You can make the docker image locally with

```
./script/build-docker-image
```

## Making a release

You can make a published (on docker hub) release with:

```
dzil release
```

This will do the following:

- Updates the version in `Changes`
- Builds the distribution files
- Commits the distribution files to the `build/releases` branch
- Creates a git tag for the current version being built
- Pushes branches `master` and `build/releases` to git remote `origin` (including tags)

This will auto trigger a build on docker hub of the official release image.
