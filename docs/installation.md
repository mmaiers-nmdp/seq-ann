# Installation

## Stable release

To install SeqAnn, run this command in your terminal:

``` console
$ uv tool install seq-ann
```

For library use inside an existing project, add SeqAnn to that project's
environment:

``` console
$ uv add seq-ann
```

SeqAnn currently uses Python 3.10 for local development because its
dependency set includes older pinned packages.

## From sources

The sources for SeqAnn can be downloaded from the [GitHub
repo](https://github.com/nmdp-bioinformatics/seq-ann).

You can either clone the public repository:

``` console
$ git clone git://github.com/nmdp-bioinformatics/seq-ann
```

Or download the
[tarball](https://github.com/nmdp-bioinformatics/seq-ann/tarball/master):

``` console
$ curl  -OL https://github.com/nmdp-bioinformatics/seq-ann/tarball/master
```

Once you have a copy of the source, you can install it with:

``` console
$ uv sync
```

Run the test suite with:

``` console
$ uv run python -m unittest discover -v
```

Build source and wheel distributions with:

``` console
$ uv build
```
