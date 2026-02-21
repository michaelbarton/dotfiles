#!/usr/bin/env python3
"""
Merge multiple BAM files into a single SAM file, preserving reads that map to more than one of the given references.
"""

from typing import Optional

import pysam
import click
import collections
import sys


def merge_headers(
    header_list: list[pysam.AlignmentHeader], reference_id_whitelist: Optional[list[str]] = None
):
    """Merge multiple headers into a single header, removing duplicates while preserving order."""

    merged_header: dict[str, list[str]] = collections.defaultdict(list)

    for header in header_list:
        for header_type, header_values in header.to_dict().items():
            if header_type == "SQ":
                for header_value in header_values:
                    if not reference_id_whitelist or header_value["SN"] in reference_id_whitelist:
                        if header_value not in merged_header[header_type]:
                            merged_header[header_type].append(header_value)

    return pysam.AlignmentHeader.from_dict(merged_header)


def get_alignments(
    bam_files: list[str], reference_id_whitelist: Optional[list[str]] = None
) -> dict[str, list[pysam.AlignedSegment]]:
    """Get all alignments from the given BAM files, preserving reads that map to more than one of the given references.

    Args:
        bam_files: List of BAM files to read from.
        reference_id_whitelist: List of reference IDs to preserve. If None, all references will be preserved.

    Returns:
        Dictionary mapping read names to lists of alignments in different references.

    """

    # Create a dictionary of read names to reference IDs
    read_references: dict[str, set[str]] = collections.defaultdict(set)
    for bam_file in bam_files:
        with pysam.AlignmentFile(bam_file, "rb") as file_:
            for read in file_:
                if not read.is_unmapped and (
                    not reference_id_whitelist or read.reference_name in reference_id_whitelist
                ):
                    read_references[read.query_name].add(read.reference_name)

    # Create a dictionary of read names to alignments, preserving reads that map to more than one of the given references.
    read_to_alignment: dict[str, list[pysam.AlignedSegment]] = collections.defaultdict(list)
    for bam_file in bam_files:
        with pysam.AlignmentFile(bam_file, "rb") as file_:
            for read in file_:
                if len(read_references[read.query_name]) > 1:
                    read_to_alignment[read.query_name].append(read)

    return read_to_alignment


def write_multiple_references_reads(
    read_objs: dict[str, list[pysam.AlignedSegment]],
    header: pysam.AlignmentHeader,
    output_file: str,
) -> None:
    reference_id_mapping = {ref: i for i, ref in enumerate(header.references)}

    dst = output_file if output_file != "-" else sys.stdout
    with pysam.AlignmentFile(dst, "wh", header=header) as outf:
        for reads in read_objs.values():
            for read in reads:
                ref_name = read.reference_name
                # Create a new read object with the same information, but with the reference ID changed to the new reference ID
                if ref_name in reference_id_mapping:
                    new_read = pysam.AlignedSegment(header=outf.header)
                    new_read.query_name = read.query_name
                    new_read.query_sequence = read.query_sequence
                    new_read.flag = read.flag
                    new_read.reference_id = reference_id_mapping[ref_name]
                    new_read.reference_start = read.reference_start
                    new_read.mapping_quality = read.mapping_quality
                    new_read.cigar = read.cigar
                    new_read.next_reference_id = (
                        read.next_reference_id
                    )  # Note: This may need to be handled differently if mate pairs can be on different references
                    new_read.next_reference_start = read.next_reference_start
                    new_read.template_length = read.template_length
                    new_read.query_qualities = read.query_qualities
                    new_read.tags = read.tags
                    outf.write(new_read)


@click.command()
@click.argument(
    "bam_files",
    nargs=-1,
    type=click.Path(exists=True, file_okay=True, dir_okay=False),
    required=True,
)
@click.option(
    "--output_file", type=str, default="-", help='Output file. Use "-" for stdout.', required=False
)
@click.option(
    "--references",
    default="",
    help="Comma-separated list of references to filter by.",
    required=False,
)
def main(bam_files: list[str], output_file: str, references: str) -> None:
    reference_id_whitelist = set(references.split(",")) if references else None
    headers = merge_headers(
        [pysam.AlignmentFile(f).header for f in bam_files], reference_id_whitelist
    )
    read_to_alignment = get_alignments(bam_files, reference_id_whitelist)
    write_multiple_references_reads(read_to_alignment, headers, output_file)


if __name__ == "__main__":
    main()
