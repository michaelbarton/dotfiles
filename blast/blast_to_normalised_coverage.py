#!/usr/bin/env python3
"""
Accepts a tab-delimited blast output file. Generates a coverage CSV file containing the columns: reference_id, position,
coverage depth.
"""

import collections
import csv
from typing import Dict, List

import click
import pysam
import pandas
import pydantic

from pathlib import Path

BLAST_COLS = [
    "qseqid",
    "sseqid",
    "pident",
    "length",
    "mismatch",
    "gapopen",
    "qstart",
    "qend",
    "sstart",
    "send",
    "evalue",
    "bitscore",
]


class Contig(pydantic.BaseModel):
    id: str
    length: int
    pseudo_offset: int


class Reference(pydantic.BaseModel):
    id: str
    src_file: Path
    contigs: List[Contig]

    def count(self) -> int:
        return sum((1 for x in self.contigs))

    def length(self) -> int:
        return sum((x.length for x in self.contigs))


def parse_fasta_file(src_file: Path) -> Reference:
    contigs: List[Contig] = []
    offset = 0
    for record in pysam.FastxFile(src_file):
        contigs.append(Contig(id=record.name, length=len(record.sequence), pseudo_offset=offset))
        offset += len(record.sequence)
    return Reference(
        id=src_file.name.replace("_genomic.fna.gz", ""), src_file=src_file, contigs=contigs
    )


def parse_blast_file(input_file) -> Dict[str, Dict[int, int]]:
    # Coverage dict
    coverage = collections.defaultdict(collections.Counter)
    blast_rows = pandas.read_csv(input_file, sep="\t", header=None, names=BLAST_COLS).iterrows()
    for _, row in blast_rows:
        for i in range(row["qstart"], row["qend"]):
            coverage[row["sseqid"]][i] += 1
    return coverage


@click.command("Blast TSV to coverage CSV")
@click.option(
    "-i",
    "--input-file",
    help="Blast TSV file.",
    type=click.Path(exists=True, file_okay=True, dir_okay=False),
    required=True,
)
@click.option(
    "-o",
    "--output-file",
    help="Output coverage CSV",
    type=click.Path(exists=False, file_okay=True, dir_okay=False),
    required=True,
)
@click.option(
    "-s",
    "--src-fasta",
    help="Source FASTA file directory.",
    type=click.Path(exists=True, file_okay=False, dir_okay=True),
    required=True,
)
def main(input_file: str, src_fasta: str, output_file: str):

    references: Dict[str, Reference] = {}
    for src_file in Path(src_fasta).glob("*"):
        if not (".fa" in src_file.suffixes or ".fna" in src_file.suffixes):
            continue
        reference = parse_fasta_file(src_file)
        references[reference.id] = reference

    contig_lookup: Dict[str, Contig] = {}
    reference_lookup: Dict[str, Reference] = {}
    for reference in references.values():
        for contig in reference.contigs:
            contig_lookup[contig.id] = contig
            reference_lookup[contig.id] = reference

    coverage = parse_blast_file(input_file)

    with open(output_file, "w") as out_fh:
        csv_writer = csv.DictWriter(
            out_fh,
            fieldnames=[
                "reference_id",
                "entry_id",
                "contig_position",
                "contig_normalised_position",
                "assembly_position",
                "assembly_normalised_position",
                "coverage",
            ],
        )
        csv_writer.writeheader()
        for contig_id, positions in coverage.items():
            contig = contig_lookup[contig_id]
            reference = reference_lookup[contig_id]
            for contig_position, coverage in positions.items():
                contig_position_normalised = contig_position / contig.length
                assembly_position = contig_position + contig.pseudo_offset
                assembly_position_normalised = assembly_position / reference.length()

                csv_writer.writerow(
                    {
                        "reference_id": reference.id,
                        "entry_id": contig_id,
                        "contig_position": contig_position,
                        "contig_normalised_position": contig_position_normalised,
                        "assembly_position": assembly_position,
                        "assembly_normalised_position": assembly_position_normalised,
                        "coverage": coverage,
                    }
                )


if __name__ == "__main__":
    main()
