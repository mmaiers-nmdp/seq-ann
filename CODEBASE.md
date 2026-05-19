# SeqAnn Codebase Documentation

## Project Overview

**SeqAnn** is a bioinformatics Python package developed by the National Marrow Donor Program (NMDP) for annotating gene features in DNA consensus sequences. It specializes in annotating Human Leukocyte Antigen (HLA) and Killer-cell Immunoglobulin-like Receptor (KIR) genes using reference databases from the IPD-IMGT (International Immunogenetics Information System).

### Key Objectives
- Automatically identify and annotate gene features (exons, introns, UTRs) in sequence data
- Support both HLA and KIR gene systems
- Generate standardized Gene Feature Enumeration (GFE) notation for sequence features
- Provide fast, accurate annotations using BLAST and sequence alignment techniques
- Enable integration with BioSQL databases for large-scale analyses

## Architecture Overview

The SeqAnn package follows a layered architecture:

```
┌─────────────────────────────────────┐
│  User Interface Layer               │
│  (BioSeqAnn class - main API)       │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Feature Detection Layer            │
│  - seq_search: nt_search, patterns  │
│  - blast_cmd: BLAST-based matching  │
│  - align: ClustalO alignment        │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Data Processing Layer              │
│  - GFE: Notation conversion         │
│  - Models: Data structures          │
│  - Util: Helper functions           │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Reference Data Layer               │
│  - BioSQL database access           │
│  - IMGT/HLA or KIR reference data   │
│  - Feature and allele information   │
└─────────────────────────────────────┘
```

## Core Modules

### 1. **sequence_annotation.py** - Main API

**Class:** `BioSeqAnn`

The central class that orchestrates the entire annotation pipeline.

#### Key Methods

- **`__init__()`** - Initializes the annotation engine
  - Loads reference data (either from BioSQL or downloads hla.dat)
  - Configures database version and parameters
  - Sets up logging and debug options

- **`annotate(sequence, locus)`** - Main annotation method
  - **Input:** Biopython Seq object, gene locus (e.g., "HLA-A")
  - **Output:** `Annotation` object containing features and GFE notation
  - **Process:**
    1. Validates input sequence
    2. Performs initial feature search (BLAST or nt_search)
    3. Aligns regions to reference sequences
    4. Maps features to the query sequence
    5. Generates GFE notation
    6. Returns complete annotation or None if unsuccessful

#### Key Parameters

```python
BioSeqAnn(
    server=None,              # BioSQL database connection
    dbversion='3310',         # Reference database version
    datfile='',               # Alternative path to .dat file
    verbose=False,            # Enable verbose logging
    verbosity=0,              # Verbosity level (0-5)
    kir=False,                # Flag for KIR vs HLA
    align=False,              # Generate alignments
    load_features=False,      # Preload feature service data
    store_features=False,     # Cache features locally
    debug={},                 # Debug specific processes
    safemode=False            # Skip alignments on partial matches
)
```

### 2. **seq_search.py** - Sequence Feature Search

**Class:** `SeqSearch`

Performs initial pattern-matching and feature detection in query sequences.

#### Methods

- **`getblocks()`** - Identifies conserved sequence blocks
  - Used for initial feature boundaries
  - Supports both exact and fuzzy matching

- **`nt_search()`** - Nucleotide pattern search
  - Uses Biopython's `SeqUtils.nt_search()`
  - Finds exact or near-exact matches to known sequences
  - Fast initial filtering before BLAST

#### Workflow
1. Searches for known feature patterns in the query sequence
2. Extracts approximate feature boundaries
3. Generates candidate matches ranked by quality
4. Passes results to alignment step for refinement

### 3. **blast_cmd.py** - BLAST Search & Alignment

**Module:** Functions for NCBI BLAST integration

#### Key Functions

- **`blastn(sequences, locus, nseqs, kir=False, ...)`**
  - Runs BLAST search against reference database
  - Returns ranked list of similar alleles
  - **Parameters:**
    - `sequences` - Query sequence (SeqRecord)
    - `locus` - Gene locus (e.g., "HLA-A")
    - `nseqs` - Number of results to return
    - `evalue` - E-value threshold (default: 10)

- **`get_locus()`**
  - Automatically detects gene locus from sequence
  - Uses BLAST results to infer locus if not provided

#### Features
- Uses `NcbiblastnCommandLine` from Biopython
- Parses BLAST XML output
- Handles both HLA and KIR reference databases
- Supports custom e-value thresholds

### 4. **align.py** - Sequence Alignment

**Module:** Handles pairwise and multiple sequence alignments

#### Key Functions

- **`align_seqs()`**
  - Performs multiple sequence alignment using Clustal Omega
  - Aligns query sequence against reference sequences
  - Used to refine feature boundaries and verify matches

- **`get_seqfeat()`**
  - Extracts feature coordinates from alignment
  - Maps reference features to query sequence positions

#### Alignment Strategy
1. Takes BLAST results (top-matching alleles)
2. Extracts reference features for those alleles
3. Performs multiple alignment: query + references
4. Projects reference features onto query sequence
5. Validates feature boundaries using alignment gaps

### 5. **gfe.py** - Gene Feature Enumeration

**Class:** `GFE`

Converts annotated features into standardized GFE notation.

#### Concept: Gene Feature Enumeration (GFE)
GFE is a standardized notation where each gene feature (exon, intron, UTR) is assigned a numeric identifier:
- Example: `HLA-Aw2-1-1-1-1-1-1-1-1-1-1-1-1-1-1-1-4`
- Format: `GENE-FEATURE1-FEATURE2-FEATURE3-...`
- Each number represents a specific sequence variant

#### Key Methods

- **`get_gfe(annotation)`**
  - Converts feature sequences to GFE notation
  - Queries Feature Service (REST API)
  - Maps feature sequences to feature IDs

#### Feature Service Integration
- REST API integration with feature enumeration service
- Caching of feature IDs to improve performance
- Support for both novel and known sequence variants

### 6. **Models** - Data Structures

#### Key Model Classes

**`Annotation` (models/annotation.py)**
- Represents the complete result of sequence annotation
- **Attributes:**
  - `annotation` - Dictionary of feature name → SeqRecord
  - `features` - Dictionary of feature name → SeqFeature (with locations)
  - `gfe` - Gene Feature Enumeration string
  - `complete_annotation` - Boolean flag indicating complete vs partial annotation
  - `method` - String describing the annotation method used
  - `seq` - Original query sequence

**`Blast` (models/blast.py)**
- Encapsulates BLAST search results
- Stores alignment scores and E-values
- Ranks candidate alleles

**`ReferenceData` (models/reference_data.py)**
- Manages reference sequence database access
- Caches allele information
- Provides feature definitions for each locus

**`Model` (models/base_model_.py)**
- Base class for all model objects
- Provides serialization/deserialization utilities

### 7. **util.py** - Utility Functions

Helper functions used throughout the codebase:

```python
# Feature classification
isexon(feature_name)              # Check if feature is an exon
isfive(feature_name)              # Check if 5' UTR
isutr(feature_name)               # Check if any UTR
is_classII(locus)                 # HLA Class II classification

# Sequence utilities
get_seqs(seq_record)              # Extract subsequences
checkseq(sequence)                # Validate sequence format
get_structures()                  # Get feature structure definitions
get_features()                    # Get all features for a locus

# File operations
randomid()                        # Generate random IDs
cleanup()                         # Clean temporary files
deserialize_model()               # Convert JSON to model objects
```

### 8. **Data Directory** - Reference Files

```
data/
├── feature_lengths.csv            # Feature size specifications
├── gc_content.csv                 # GC content reference values
├── kir-feature_lengths.csv        # KIR-specific feature sizes
├── molecular_weight.csv           # Molecular weight calculations
├── reference_alleles.txt          # Known allele list
├── alignments/                    # Multi-alignment templates
│   ├── 3290/
│   ├── 3300/
│   └── 3310/
├── allele_lists/                  # Allele lists per database version
│   ├── Allelelist.300.txt
│   ├── Allelelist.310.txt
│   └── ...
└── blast/                         # BLAST database files
```

## Annotation Pipeline

### Step-by-Step Process

1. **Input Validation**
   - Verify sequence format (DNA only)
   - Check locus parameter or auto-detect
   - Initialize reference data

2. **Initial Search (SeqSearch)**
   - Fast pattern matching using `nt_search()`
   - Identifies approximate feature boundaries
   - Quick filtering to narrow candidate set

3. **BLAST Search**
   - Runs BLAST against full reference database
   - Returns top-N matching alleles
   - Filters results by E-value threshold

4. **Reference Feature Extraction**
   - For each top BLAST hit, retrieve known features
   - Extract reference allele sequences from BioSQL

5. **Multiple Alignment**
   - Uses Clustal Omega to align:
     - Query sequence
     - Top BLAST matches
     - Known reference features
   - Resolves feature boundaries

6. **Feature Mapping**
   - Projects reference features to query coordinates
   - Validates feature continuity
   - Checks for frameshifts and gaps

7. **GFE Generation**
   - For each identified feature, query Feature Service
   - Map feature sequence to feature ID
   - Construct GFE notation string

8. **Return Results**
   - Package annotation in `Annotation` object
   - Include confidence metrics
   - Provide method used for annotation

### Feature Structures

Features are organized by gene locus:

```
HLA Class I (HLA-A, HLA-B, HLA-C):
├── exon_1         # Signal peptide (20 bp)
├── intron_1       # Variable
├── exon_2         # Polymorphic domain 1 (270 bp)
├── exon_3         # Polymorphic domain 2 (270 bp)
├── exon_4         # Transmembrane (150 bp)
├── exon_5         # Cytoplasmic (30 bp)
├── exon_6         # Cytoplasmic (60 bp)
├── exon_7         # Cytoplasmic (30 bp)
└── exon_8         # 3' UTR (100+ bp)

HLA Class II (HLA-DR, HLA-DQ):
├── exon_1         # Signal peptide
├── exon_2         # Polymorphic domain (190-270 bp)
├── exon_3         # Ig-like domain
├── exon_4         # Transmembrane
├── exon_5         # Cytoplasmic
└── exon_6         # 3' UTR
```

## Reference Data Management

### BioSQL vs. hla.dat

**BioSQL Approach (Recommended for Production)**
- Full relational database with indexing
- Fast queries via SQL
- Suitable for batch processing
- Requires Docker/database setup

**hla.dat File (Default)**
- Flat file from ANHIG/IMGTHLA repository
- Downloaded automatically if no database provided
- Parsed into memory on startup
- Slower for large-scale processing

### Version Management

Database versions follow IMGT releases:
- `3290` - 3.29.0 release
- `3300` - 3.30.0 release
- `3310` - 3.31.0 release (default)

## Performance Considerations

### Optimization Strategies

1. **Use BioSQL Database**
   - 10-100x faster than flat file parsing
   - Enables parallel processing

2. **Pre-cache Features**
   - Load feature definitions at startup
   - Set `load_features=True` for batch jobs

3. **Adjust E-values**
   - Lower e-value = stricter, faster
   - Higher e-value = more permissive, thorough

4. **Use Safe Mode**
   - Skip expensive alignments on partial matches
   - `safemode=True` for speed over accuracy

5. **Parallel Processing**
   - SeqAnn instances are thread-safe
   - Distribute sequences across CPU cores

### Typical Execution Times

| Scenario | Time |
|----------|------|
| Single annotation (no DB) | 5-30 seconds |
| Single annotation (BioSQL) | 0.5-2 seconds |
| Batch 100 sequences (BioSQL) | 1-5 minutes |
| Batch 1000 sequences (BioSQL) | 15-60 minutes |

## Testing

### Test Suite

Located in `tests/` directory:

```
test_align.py           # Alignment module tests
test_blast.py           # BLAST search tests
test_feature.py         # Feature detection tests
test_gfe.py             # GFE notation tests
test_refdata.py         # Reference data loading
test_seqann.py          # Main API integration tests
test_seqsearch.py       # Sequence search tests
test_util.py            # Utility function tests
```

### Test Resources

Located in `tests/resources/`:

- `exact_seqs.fasta` - Known sequences with exact matches
- `partial_seqs.fasta` - Partial sequence matches
- `ambig_seqs.fasta` - Sequences with ambiguous bases
- `insertion_seqs.fasta` - Sequences with insertions
- `deletion_seqs.fasta` - Sequences with deletions
- `expected.json` - Expected annotation results

### Running Tests

```bash
pytest tests/
pytest tests/test_seqann.py -v           # Verbose output
pytest tests/test_align.py --cov         # With coverage
```

## Usage Examples

### Example 1: Basic Annotation

```python
from seqann import BioSeqAnn
from Bio.Seq import Seq

# Initialize
seqann = BioSeqAnn()

# Create sequence
sequence = Seq("AGAGACTCTCCCGAGGATTTCGTGTACCAGTTTAAGGCCATGTGCTACTTCACCAACGGGACGGAGC...")

# Annotate
annotation = seqann.annotate(sequence, "HLA-A")

# Access results
if annotation:
    print(f"GFE: {annotation.gfe}")
    print(f"Method: {annotation.method}")
    for feature_name, seq_record in annotation.annotation.items():
        print(f"{feature_name}: {str(seq_record.seq)}")
```

### Example 2: Batch Processing with Database

```python
from seqann import BioSeqAnn
from BioSQL import BioSeqDatabase
from Bio import SeqIO

# Connect to database
server = BioSeqDatabase.open_database(
    driver="pymysql",
    user="root",
    passwd="password",
    host="localhost",
    db="bioseqdb"
)

# Initialize with database (much faster)
seqann = BioSeqAnn(server=server, dbversion="3310")

# Process FASTA file
results = []
for record in SeqIO.parse("input.fasta", "fasta"):
    annotation = seqann.annotate(record.seq, "HLA-A")
    if annotation:
        results.append({
            'sequence_id': record.id,
            'gfe': annotation.gfe,
            'method': annotation.method
        })
```

### Example 3: KIR Gene Annotation

```python
from seqann import BioSeqAnn
from Bio.Seq import Seq

# Initialize for KIR system
seqann = BioSeqAnn(kir=True, dbversion="2170")

# Annotate KIR sequence
sequence = Seq("ATGGGGCAGGTCCTGGCCGGAGCCGAAGCTGGCGCAG...")
annotation = seqann.annotate(sequence, "KIR3DL1")
```

### Example 4: Debugging and Verbose Output

```python
from seqann import BioSeqAnn
from Bio.Seq import Seq

# Enable detailed debugging
seqann = BioSeqAnn(
    verbose=True,
    verbosity=4,
    debug={
        "blast": 3,
        "align": 2,
        "gfe": 1
    }
)

# Annotate with detailed output
sequence = Seq("AGAGACTCTCCCGAGGATTTCGTGTACCAGTTTAAGGCCATGTGCTACTTCACCAACGGGACGGAGC...")
annotation = seqann.annotate(sequence, "HLA-A")
```

## Key Dependencies

- **Biopython** (1.75) - Sequence handling and alignment
- **PyMySQL** (0.9.3) - MySQL/BioSQL connectivity
- **BSON** (0.5.8) - Data serialization
- **Requests** (2.22.0) - HTTP client for Feature Service
- **NCBI BLAST+** (external) - Sequence alignment
- **Clustal Omega** (external) - Multiple sequence alignment

## Contributing

Development workflow:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

For detailed contribution guidelines, see `CONTRIBUTING.rst`.

## License

SeqAnn is licensed under the **GNU Lesser General Public License (LGPL) 3.0**.

See `COPYING` for full license text.

## References

- **IMGT/HLA Database:** https://www.ebi.ac.uk/ipd/imgt/hla/
- **KIR Database:** https://www.ebi.ac.uk/ipd/kir/
- **GFE Specification:** https://github.com/ANHIG/GFE
- **Biopython Documentation:** https://biopython.org/

## Contact & Support

- **Organization:** NMDP Bioinformatics, CIBMTR
- **Repository:** https://github.com/nmdp-bioinformatics/SeqAnn
- **Issues:** https://github.com/nmdp-bioinformatics/SeqAnn/issues
