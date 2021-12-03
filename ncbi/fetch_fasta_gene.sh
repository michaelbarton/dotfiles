#!/bin/bash
# See: https://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.T._valid_values_of__retmode_and/

set -o nounset

ID=$1
OUT_FILE=~/.ncbi/gene/$(echo $1 | tr '.' '_').fa.gz

wget \
	"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${ID}&rettype=fasta_cds_na&retmode=text" \
	--quiet \
	--output-document - \
| pigz -11 > ${OUT_FILE}
