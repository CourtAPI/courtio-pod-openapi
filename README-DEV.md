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

## Building a release

Make a release with:

```
dzil release
```

This just creates a build, saves the build results to the `build/releases`
branch, tags it, and pushes the git repo.
