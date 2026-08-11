#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path
from collections import Counter, defaultdict


def safe_float(value):
    """Convert value to float when possible."""
    if value is None:
        return None

    value = str(value).strip().replace("%", "")

    try:
        return float(value)
    except ValueError:
        return None


def unique_sorted(values):
    """Return sorted unique non-empty values."""
    return sorted(
        {
            str(v).strip()
            for v in values
            if v is not None
            and str(v).strip()
            and str(v).strip() not in {"-", "."}
        }
    )


def detect_sample_from_filename(path):
    """
    Infer sample ID from common pipeline filenames.
    """

    name = path.name

    suffixes = [
        "_abricate_summary.tsv",
        "_abricate_combined.tsv",
        "_resfinder.tsv",
        "_vfdb.tsv",
        "_plasmidfinder.tsv",
        ".tsv",
    ]

    for suffix in suffixes:
        if name.endswith(suffix):
            return name[:-len(suffix)]

    return path.stem


def normalize_sample_id(sample):
    """
    Normalize sample names so outputs from different tools
    are grouped under the same biological sample.
    """

    suffixes = [
        "_prokka",
        "_quast",
        "_nanoplot_raw",
        "_nanoplot_filtered",
        "_abricate",
        "_medaka",
        "_flye",
    ]

    sample = str(sample).strip()

    for suffix in suffixes:
        if sample.endswith(suffix):
            sample = sample[:-len(suffix)]

    return sample


# ------------------------------------------------------------
# PROKKA
# ------------------------------------------------------------

def read_prokka_tsv(path):
    """
    Parse a Prokka TSV file.

    Typical columns:
    locus_tag, ftype, len_bp, gene, EC_number, COG, product
    """

    stats = Counter()
    genes = []
    products = []
    hypothetical = 0
    total_length = 0

    with open(path, "r", encoding="utf-8", errors="replace") as handle:

        reader = csv.DictReader(handle, delimiter="\t")

        if not reader.fieldnames:
            return None

        # Check that it looks like a Prokka TSV
        fields = {x.lower() for x in reader.fieldnames if x}

        if "ftype" not in fields and "locus_tag" not in fields:
            return None

        for row in reader:

            feature = (
                row.get("ftype")
                or row.get("FTYPE")
                or ""
            ).strip()

            if feature:
                stats[feature] += 1

            gene = (
                row.get("gene")
                or row.get("GENE")
                or ""
            ).strip()

            product = (
                row.get("product")
                or row.get("PRODUCT")
                or ""
            ).strip()

            if gene and gene not in {"-", "."}:
                genes.append(gene)

            if product and product not in {"-", "."}:
                products.append(product)

                if "hypothetical protein" in product.lower():
                    hypothetical += 1

            length = (
                row.get("len_bp")
                or row.get("LEN_BP")
            )

            try:
                total_length += int(length)
            except (TypeError, ValueError):
                pass

    return {
        "features": stats,
        "genes": unique_sorted(genes),
        "products": products,
        "hypothetical": hypothetical,
        "total_feature_length": total_length,
    }


def find_prokka_results(annotation_dir):
   """
    Find Prokka TSV files recursively.
    """

    def normalize_sample_id(sample):
        """
        Normalize sample names so outputs from different tools
        are grouped under the same biological sample.
        """

        suffixes = [
            "_prokka",
            "_quast",
            "_nanoplot_raw",
            "_nanoplot_filtered",
            "_abricate",
            "_medaka",
            "_flye",
        ]

        sample = str(sample).strip()

        for suffix in suffixes:
            if sample.endswith(suffix):
                sample = sample[:-len(suffix)]

        return sample

    results = {}

    for path in annotation_dir.rglob("*.tsv"):

        parsed = read_prokka_tsv(path)

        if parsed is None:
            continue

        # Prefer parent directory name as sample when possible
        sample = path.parent.name

        # fallback for generic directories
        if sample.lower() in {
            "annotation",
            "prokka",
            "results",
        }:
            sample = detect_sample_from_filename(path)

        sample = normalize_sample_id(sample)
        results[sample] = parsed

    return results


# ------------------------------------------------------------
# ABRICATE
# ------------------------------------------------------------

def read_abricate_file(path):
    """
    Parse an ABRicate TSV result file.

    Typical columns include:
    #FILE
    SEQUENCE
    START
    END
    STRAND
    GENE
    %COVERAGE
    %IDENTITY
    DATABASE
    ACCESSION
    PRODUCT
    RESISTANCE
    """

    hits = []

    with open(path, "r", encoding="utf-8", errors="replace") as handle:

        reader = csv.DictReader(handle, delimiter="\t")

        if not reader.fieldnames:
            return hits

        for row in reader:

            # Ignore blank rows
            if not any(str(v).strip() for v in row.values() if v):
                continue

            gene = (
                row.get("GENE")
                or row.get("gene")
                or ""
            ).strip()

            database = (
                row.get("DATABASE")
                or row.get("database")
                or ""
            ).strip()

            identity = safe_float(
                row.get("%IDENTITY")
                or row.get("IDENTITY")
            )

            coverage = safe_float(
                row.get("%COVERAGE")
                or row.get("COVERAGE")
            )

            product = (
                row.get("PRODUCT")
                or row.get("product")
                or ""
            ).strip()

            resistance = (
                row.get("RESISTANCE")
                or row.get("resistance")
                or ""
            ).strip()

            accession = (
                row.get("ACCESSION")
                or row.get("accession")
                or ""
            ).strip()

            hits.append(
                {
                    "gene": gene,
                    "database": database,
                    "identity": identity,
                    "coverage": coverage,
                    "product": product,
                    "resistance": resistance,
                    "accession": accession,
                }
            )

    return hits


def database_from_filename(path):
    name = path.name.lower()

    if "resfinder" in name:
        return "resfinder"

    if "vfdb" in name:
        return "vfdb"

    if "plasmidfinder" in name:
        return "plasmidfinder"

    return None


def find_abricate_results(detection_dir):
    """
    Read ResFinder, VFDB and PlasmidFinder ABRicate output files.
    """

    results = defaultdict(
        lambda: {
            "resfinder": [],
            "vfdb": [],
            "plasmidfinder": [],
        }
    )

    for path in detection_dir.rglob("*.tsv"):

        database = database_from_filename(path)

        # Skip combined / summary files here to avoid duplicates
        if database is None:
            continue

        sample = detect_sample_from_filename(path)

        hits = read_abricate_file(path)

        for hit in hits:

            if not hit["database"]:
                hit["database"] = database

        results[sample][database].extend(hits)

    return dict(results)


# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

def mean_metric(hits, key):
    values = [
        h[key]
        for h in hits
        if h.get(key) is not None
    ]

    if not values:
        return ""

    return round(sum(values) / len(values), 2)


def gene_list(hits):
    return unique_sorted(
        hit.get("gene")
        for hit in hits
    )


def resistance_list(hits):
    values = []

    for hit in hits:

        if hit.get("resistance"):
            values.append(hit["resistance"])

        elif hit.get("product"):
            values.append(hit["product"])

    return unique_sorted(values)


def make_summary(annotation, detection):

    samples = sorted(
        set(annotation.keys())
        | set(detection.keys())
    )

    rows = []

    for sample in samples:

        ann = annotation.get(sample, {})
        features = ann.get("features", Counter())

        detect = detection.get(
            sample,
            {
                "resfinder": [],
                "vfdb": [],
                "plasmidfinder": [],
            }
        )

        amr = detect.get("resfinder", [])
        virulence = detect.get("vfdb", [])
        plasmids = detect.get("plasmidfinder", [])

        row = {
            "sample": sample,

            # Annotation
            "CDS": features.get("CDS", 0),
            "gene_features": features.get("gene", 0),
            "tRNA": features.get("tRNA", 0),
            "rRNA": features.get("rRNA", 0),
            "tmRNA": features.get("tmRNA", 0),

            "hypothetical_proteins":
                ann.get("hypothetical", 0),

            "annotated_gene_names":
                len(ann.get("genes", [])),

            # AMR
            "AMR_hits": len(amr),
            "AMR_unique_genes": len(gene_list(amr)),
            "AMR_genes": ", ".join(gene_list(amr)),
            "AMR_classes_products":
                ", ".join(resistance_list(amr)),

            "AMR_mean_identity":
                mean_metric(amr, "identity"),

            "AMR_mean_coverage":
                mean_metric(amr, "coverage"),

            # Virulence
            "virulence_hits": len(virulence),

            "virulence_unique_genes":
                len(gene_list(virulence)),

            "virulence_genes":
                ", ".join(gene_list(virulence)),

            # Plasmids
            "plasmid_hits": len(plasmids),

            "plasmid_unique":
                len(gene_list(plasmids)),

            "plasmid_markers":
                ", ".join(gene_list(plasmids)),
        }

        rows.append(row)

    return rows


# ------------------------------------------------------------
# OUTPUT
# ------------------------------------------------------------

def write_tsv(rows, path):

    if not rows:
        return

    path.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(
        path,
        "w",
        newline="",
        encoding="utf-8",
    ) as handle:

        writer = csv.DictWriter(
            handle,
            fieldnames=rows[0].keys(),
            delimiter="\t",
        )

        writer.writeheader()
        writer.writerows(rows)


def write_text_report(rows, path):

    path.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(
        path,
        "w",
        encoding="utf-8"
    ) as handle:

        for row in rows:

            handle.write(
                "=" * 70 + "\n"
            )

            handle.write(
                f"Sample: {row['sample']}\n"
            )

            handle.write(
                "=" * 70 + "\n\n"
            )

            handle.write(
                "ANNOTATION\n"
            )

            handle.write(
                f"  CDS                  : {row['CDS']}\n"
            )

            handle.write(
                f"  tRNA                 : {row['tRNA']}\n"
            )

            handle.write(
                f"  rRNA                 : {row['rRNA']}\n"
            )

            handle.write(
                f"  tmRNA                : {row['tmRNA']}\n"
            )

            handle.write(
                f"  Hypothetical proteins: "
                f"{row['hypothetical_proteins']}\n"
            )

            handle.write(
                f"  Named genes          : "
                f"{row['annotated_gene_names']}\n\n"
            )

            handle.write(
                "ANTIMICROBIAL RESISTANCE\n"
            )

            handle.write(
                f"  Hits                 : "
                f"{row['AMR_hits']}\n"
            )

            handle.write(
                f"  Unique genes         : "
                f"{row['AMR_unique_genes']}\n"
            )

            handle.write(
                f"  Genes                : "
                f"{row['AMR_genes'] or 'None'}\n"
            )

            handle.write(
                f"  Mean identity (%)    : "
                f"{row['AMR_mean_identity']}\n"
            )

            handle.write(
                f"  Mean coverage (%)    : "
                f"{row['AMR_mean_coverage']}\n\n"
            )

            handle.write(
                "VIRULENCE\n"
            )

            handle.write(
                f"  Hits                 : "
                f"{row['virulence_hits']}\n"
            )

            handle.write(
                f"  Genes                : "
                f"{row['virulence_genes'] or 'None'}\n\n"
            )

            handle.write(
                "PLASMIDS\n"
            )

            handle.write(
                f"  Hits                 : "
                f"{row['plasmid_hits']}\n"
            )

            handle.write(
                f"  Markers              : "
                f"{row['plasmid_markers'] or 'None'}\n\n"
            )


def print_summary(rows):

    print()
    print("=" * 80)
    print(" AMR OXFORD NANOPORE PIPELINE - RESULT OVERVIEW")
    print("=" * 80)

    for row in rows:

        print()
        print(f"[{row['sample']}]")

        print(
            f"  Annotation : "
            f"{row['CDS']} CDS | "
            f"{row['tRNA']} tRNA | "
            f"{row['rRNA']} rRNA | "
            f"{row['hypothetical_proteins']} hypothetical proteins"
        )

        print(
            f"  AMR        : "
            f"{row['AMR_unique_genes']} unique gene(s)"
        )

        if row["AMR_genes"]:
            print(
                f"               {row['AMR_genes']}"
            )

        print(
            f"  Virulence  : "
            f"{row['virulence_unique_genes']} unique gene(s)"
        )

        if row["virulence_genes"]:
            print(
                f"               {row['virulence_genes']}"
            )

        print(
            f"  Plasmids   : "
            f"{row['plasmid_unique']} marker(s)"
        )

        if row["plasmid_markers"]:
            print(
                f"               {row['plasmid_markers']}"
            )

    print()
    print("=" * 80)


def main():

    parser = argparse.ArgumentParser(
        description=(
            "Generate a quick overview of Prokka annotation "
            "and ABRicate detection results."
        )
    )

    parser.add_argument(
        "--annotation",
        default="results/annotation",
        help="Prokka results directory"
    )

    parser.add_argument(
        "--detection",
        default="results/detection",
        help="ABRicate results directory"
    )

    parser.add_argument(
        "--outdir",
        default="results/summary",
        help="Output directory"
    )

    args = parser.parse_args()

    annotation_dir = Path(args.annotation)
    detection_dir = Path(args.detection)
    outdir = Path(args.outdir)

    if not annotation_dir.exists():
        print(
            f"WARNING: annotation directory not found: "
            f"{annotation_dir}"
        )

    if not detection_dir.exists():
        print(
            f"WARNING: detection directory not found: "
            f"{detection_dir}"
        )

    annotation = (
        find_prokka_results(annotation_dir)
        if annotation_dir.exists()
        else {}
    )

    detection = (
        find_abricate_results(detection_dir)
        if detection_dir.exists()
        else {}
    )

    rows = make_summary(
        annotation,
        detection
    )

    if not rows:
        raise SystemExit(
            "No Prokka or ABRicate results were detected."
        )

    outdir.mkdir(
        parents=True,
        exist_ok=True
    )

    tsv_path = (
        outdir
        / "annotation_detection_overview.tsv"
    )

    text_path = (
        outdir
        / "annotation_detection_overview.txt"
    )

    write_tsv(
        rows,
        tsv_path
    )

    write_text_report(
        rows,
        text_path
    )

    print_summary(rows)

    print(
        f"\nTSV summary : {tsv_path}"
    )

    print(
        f"Text report : {text_path}"
    )


if __name__ == "__main__":
    main()
