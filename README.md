# cpm resolver sample

This repository demonstrates how to create a custom resolver for
[cpm](https://github.com/skaji/cpm), and how to use it with cpm v1.

## Introduction

A cpm resolver turns a package request into a distribution location.

For example:

```text
Plack::Request                  -> https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz
Class::MOP with version < 2.1000 -> https://cpan.metacpan.org/authors/id/E/ET/ETHER/Moose-2.0800.tar.gz
Carl::Indexer                   -> https://github.com/skaji/Carl.git, branch: dev
```

cpm has built-in resolvers such as `metacpan`, `metadb`, `02packages`,
`snapshot`, and dependency-file custom resolvers for `cpanfile`/`cpm.yml`
`dist`, `url`, and `git` entries.

You can choose and order resolvers with `--resolver`:

```console
# Use the metacpan resolver only, followed by cpm's default resolvers.
cpm install --resolver metacpan Plack

# Use a snapshot resolver first, then metadb, then cpm's default resolvers.
cpm install --resolver snapshot --resolver metadb Plack

# Use only the resolvers you specify.
cpm install --no-default-resolvers --resolver metacpan Plack
```

This sample resolver reads a static YAML file that maps packages to
distribution entries. It is useful for private distributions, git
repositories, or any distribution source that you want to resolve explicitly.

## Resolver API

The resolver API is still experimental, but cpm v1 calls custom resolvers like
this:

```perl
sub new ($class, $ctx, @argv)
sub resolve ($self, $ctx, $task)
```

### Constructor

```perl
sub new ($class, $ctx, @argv)
```

`$class` is the resolver class name.

When the command line uses an unqualified resolver name, cpm prefixes it with
`App::cpm::Resolver::`. For example:

```console
cpm install --resolver Sample,/path/to/index.yaml Module
```

loads `App::cpm::Resolver::Sample` and calls:

```perl
App::cpm::Resolver::Sample->new($ctx, "/path/to/index.yaml")
```

Use a leading `+` for a fully qualified class name:

```console
cpm install --resolver +My::Resolver,arg1,arg2 Module
```

which calls:

```perl
My::Resolver->new($ctx, "arg1", "arg2")
```

`$ctx` is an `App::cpm::Context` object. It exposes cpm internals such as the
HTTP client and logger. Treat it as experimental.

`@argv` is the comma-separated argument list from `--resolver`.

### resolve

```perl
sub resolve ($self, $ctx, $task)
```

`$task` is an `App::cpm::Task` object. Resolver implementations can treat it as
a hash reference. Important keys are:

```perl
$task->{package}       # requested package name, e.g. "Plack"
$task->{version_range} # requested version range, e.g. ">= 1.000, < 2.000"; may be undef/0
$task->{dev}           # true when the request asks for a dev/TRIAL release
$task->{reinstall}     # true for a top-level reinstall request
```

The resolver should return a hash reference. On success, common keys are:

```perl
{
    source   => "cpan", # "cpan", "http", "git", or "local"
    uri      => "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz",
    distfile => "M/MI/MIYAGAWA/Plack-1.0047.tar.gz", # useful for CPAN distributions
    version  => "1.0047",
    provides => [
        { package => "Plack", version => "1.0047" },
    ],
}
```

For a git distribution:

```perl
{
    source   => "git",
    uri      => "https://github.com/skaji/Carl.git",
    ref      => "master",
    provides => [
        { package => "Carl::Indexer" },
    ],
}
```

If the resolver cannot resolve the package, return an `error` entry:

```perl
return { error => "not found" };
```

cpm's cascade resolver will then try the next resolver. If no resolver
succeeds, cpm reports the collected errors.

## Minimal Resolver

A minimal cpm v1 resolver looks like this:

```perl
package App::cpm::Resolver::Minimal;
use v5.24;
use experimental 'signatures';

sub new ($class, $ctx, @argv) {
    bless {}, $class;
}

sub resolve ($self, $ctx, $task) {
    return { error => "not found" }
        if $task->{package} ne "Plack::Request";

    return {
        source   => "cpan",
        uri      => "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz",
        distfile => "M/MI/MIYAGAWA/Plack-1.0047.tar.gz",
        version  => "1.0047",
        provides => [
            { package => "Plack::Request" },
        ],
    };
}

1;
```

## Practical Sample

[index.yaml](index.yaml) is a static YAML file that defines package to
distribution mappings:

```yaml
index:
  Plack::Request: { source: "cpan", distfile: "M/MI/MIYAGAWA/Plack-1.0047.tar.gz", uri: "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz" }
  Class::MOP:     { source: "cpan", distfile: "E/ET/ETHER/Moose-2.0800.tar.gz", uri: "https://cpan.metacpan.org/authors/id/E/ET/ETHER/Moose-2.0800.tar.gz" }
  Carl::Indexer:  { source: "git", uri: "https://github.com/skaji/Carl.git", ref: "master" }
```

[App::cpm::Resolver::Sample](lib/App/cpm/Resolver/Sample.pm) loads this YAML
file and returns the matching entry.

Install the sample resolver:

```console
cpm install -g https://github.com/skaji/cpm-resolver-sample.git
```

Use it:

```console
cpm install --resolver Sample,/path/to/index.yaml Module
```

You may want to keep cpm's default resolvers enabled as fallback. That is the
default behavior. If you want to use only this resolver, disable default
resolvers. In that mode, every required package must be resolvable by this
resolver:

```console
cpm install --no-default-resolvers --resolver Sample,/path/to/index.yaml Module
```

## Caveats

The custom resolver API is experimental and may change.

This sample does not implement version-range matching. A production resolver
should check `$task->{version_range}` before returning a distribution.

## Feedback

I would like to hear your thoughts. Please feel free to create
[GitHub issues](https://github.com/skaji/cpm-resolver-sample/issues).

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
