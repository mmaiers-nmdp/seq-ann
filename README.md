# SeqAnn

![Build Status](https://img.shields.io/travis/nmdp-bioinformatics/SeqAnn.svg)
![Documentation Status](https://readthedocs.org/projects/seqann/badge/?version=latest)
![Updates](https://pyup.io/repos/github/nmdp-bioinformatics/SeqAnn/shield.svg)
![Version](https://img.shields.io/pypi/v/seqann.svg)
![Coverage](https://coveralls.io/repos/github/nmdp-bioinformatics/SeqAnn/badge.svg?branch=master)

**A Python package for annotating gene features in consensus sequences**

- **Free software:** LGPL 3.0
- **Documentation:** [https://seqann.readthedocs.io](https://seqann.readthedocs.io)
- **Example Notebook:** [Jupyter Notebook](https://github.com/nmdp-bioinformatics/SeqAnn/blob/master/notebook/Examples.ipynb)

## Overview

The `seqann` package allows users to annotate gene features in consensus sequences. Annotations are created by passing consensus sequences to the `annotate` method in the `BioSeqAnn` class.

Key features:
- **Zero-configuration mode:** No parameters are required when initializing a `BioSeqAnn` class
- **Database support:** Annotations run significantly faster with a BioSQL database
- **Automatic fallback:** When a BioSQL database is not provided, the latest `hla.dat` file is downloaded and parsed automatically
- **Docker support:** A pre-configured BioSQL database containing all of IPD-IMGT/HLA is available on [DockerHub](https://hub.docker.com/r/nmdpbioinformatics/imgt_biosqldb/)

## Installation

```bash
pip install seq-ann
```

## Dependencies

- [Clustal Omega](http://www.clustal.org/omega/) 1.2.0 or higher
- [Python 3.6+](https://www.python.org/downloads)
- [BLAST (blastn)](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

## Quick Start

### Basic Usage

```python
from seqann import BioSeqAnn

seqann = BioSeqAnn()
ann = seqann.annotate(sequence, "HLA-A")
```

### With BioSQL Database

For significantly faster annotations, use a BioSQL database:

```python
from seqann import BioSeqAnn
from BioSQL import BioSeqDatabase

server = BioSeqDatabase.open_database(driver="pymysql", user="root",
                                      passwd="my-secret-pw", host="localhost",
                                      db="bioseqdb", port=3306)
seqann = BioSeqAnn(server=server)
ann = seqann.annotate(sequence, "HLA-A")
```

### Environment Configuration

For BioSQL connections, set environment variables:

```bash
export BIOSQLHOST="localhost"
export BIOSQLPORT=3306
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `server` | `BioSeqDatabase` | None | A BioSQL database containing sequence data from IPD-IMGT/HLA |
| `dbversion` | `str` | Latest | The IPD-IMGT/HLA or KIR database release (e.g., "3310") |
| `datfile` | `str` | None | Path to an IPD-IMGT/HLA or KIR dat file (alternative to server) |
| `kir` | `bool` | False | Set to True for KIR gene system sequences |
| `align` | `bool` | False | Generate alignments along with annotations |
| `verbose` | `bool` | False | Enable verbose output mode |
| `verbosity` | `int` | 0 | Verbosity level (0-5) for detailed output |
| `debug` | `Dict` | None | Dictionary with process names as keys and verbosity levels as values |

## Annotations Output

Once a sequence is annotated, the gene features and their corresponding sequences are available in the returned `Annotation` object:

```python
ann = seqann.annotate(sequence, "HLA-A")
for feat in ann.annotation:
    print(feat, ann.gfe, str(ann.annotation[feat].seq), sep="\t")
```

Example annotation structure:

```python
{
    'complete_annotation': True,
    'annotation': {
        'exon_1': SeqRecord(...),
        'exon_2': SeqRecord(...),
        'exon_3': SeqRecord(...)
    },
    'features': {
        'exon_1': SeqFeature(...),
        'exon_2': SeqFeature(...),
        'exon_3': SeqFeature(...)
    },
    'method': 'nt_search and clustalo',
    'gfe': 'HLA-Aw2-1-1-1-1-1-1-1-1-1-1-1-1-1-1-1-4',
    'seq': SeqRecord(...)
}
```

**Note:** If a complete annotation cannot be produced, `None` is returned.

## Accessing Annotated Features

Once a sequence is annotated:
- **Feature sequences:** Access individual features via the `annotation` dictionary
- **Feature locations:** Get genomic positions from the `features` dictionary
- **GFE notation:** Retrieve the Gene Feature Enumeration notation from the `gfe` attribute
- **Complete status:** Check the `complete_annotation` boolean flag
- **Methodology:** Review the annotation `method` used (e.g., "nt_search and clustalo")
