# cpm resolver sample

This respository demonstrates how to create your own resolver for [cpm](https://github.com/skaji/cpm),
and how to use it.

## Introduction

Do you know [cpm](https://github.com/skaji/cpm) allows you to change resolvers?

Here, a *resolver* has responsibility to resolve
package names (optionally with some version requirements) into distribution URIs.
Some examples of "resolving" are:

    Plack::Request -> https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz
    Class::MOP with version < 2.1000 -> https://cpan.metacpan.org/authors/id/E/ET/ETHER/Moose-2.0800.tar.gz
    Carl::Indexer -> https://github.com/skaji/Carl.git, branch: dev

cpm comes with the following resolvers by default:

* metadb - see https://cpanmetadb.plackperl.org
* metacpan - see https://fastapi.metacpan.org/v1/download_url
* 02packages - see https://www.cpan.org/modules/02packages.details.txt.gz
* cpanfile - by dist/url syntax in cpanfile, see https://github.com/miyagawa/cpanminus/pull/568
* snapshot - see https://metacpan.org/pod/Carton

and you can set/reorder resolvers by `--resolver` options:

```console
# use metacpan resolver only
cpm install --resolver metacpan Plack

# use snapshot resolver first, and fall back on metadb resolver
cpm install --resolver snapshot --resolver metadb Plack
```

You may not be satisfied with the above resolvers, especially if you are working on private distributions
or distributions on git repositories.
Actuall I'm not either.

So why don't you create your own resolver for cpm?

This respository demonstrates how to create your own resolver for cpm, and how to use it.
Specifically, create a resolver which defines the correspondence
between packages and distributions in a static YAML file.
Unlike 02packages.details.txt, it will support git repository URIs.

## The spec of resolvers for cpm

A resolver for cpm is a perl package that simply has `resolve` method.
A minimal resolver for cpm looks like:

```perl
package App::cpm::Resolver::Minimal;
sub new {
    my $class = shift;
    bless {}, $class;
}
sub resolve {
    my ($self, $argv) = @_;
    my $package = $argv->{package};
    my $version_range = $argv->{version_range}; # this is optional
    if ($package eq "Plack::Request") {
        return { uri => "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz" };
    } else {
        return { error => "not found" };
    }
}
1;
```

`resolve` method will take a hash reference `$argv` which has `package` and `version_range` keys,
and it must returns a hash reference representing distribution URI.
The above `App::cpm::Resolver::Minimal` resolver resolves only `Plack::Request` package;
otherwise returns an error "not found".

Resolvers for cpm are specified by `--resolver` option:

```console
cpm install --resolver Minimal Plack

# Comma separated arguments are passed as Minimal->new(arg1, arg2)
cpm install --resolver Minimal,arg1,arg2 Plack
```

## Practical sample

Let's go on to a practical one.

Please look at [index.yaml](index.yaml),
which is a *static* YAML file, and defines the correspondence between packages and distributions.

```yaml
index:
  Plack::Request: { source: "http", uri: "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/Plack-1.0047.tar.gz" }
  Class::MOP:     { source: "http", uri: "https://cpan.metacpan.org/authors/id/E/ET/ETHER/Moose-2.0800.tar.gz" }
  Carl::Indexer:  { source: "git", uri: "https://github.com/skaji/Carl.git", ref: "master" }
```

You will easily set distributions not in CPAN, or on git repositories in this index.yaml.
[App::cpm::Resolver::Sample](lib/App/cpm/Resolver/Sample.pm) is a resolver loding this yaml file.

Now let's use this resolver with cpm. First install it into your local:

```console
cpm install -g https://github.com/skaji/cpm-resolver-sample.git
```

And use it!

```console
cpm install --resolver Sample,/path/to/index.yaml Module

# you may want to set metadb resolver to fall back on
cpm install --resolver Sample,/path/to/index.yaml --resolver metadb Module
```

## Caveats

The resolvers in cpm are still in alpha stage.

## Feedback

I would like to hear your thoughts. Please feel free to create [github issues](https://github.com/skaji/cpm-resolver-sample/issues)
or to contact me via [twitter](https://twitter.com/shoichikaji).

Let's make CPAN better.

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
