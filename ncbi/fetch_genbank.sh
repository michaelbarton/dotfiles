#!/bin/bash
# See: https://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.T._valid_values_of__retmode_and/

set -o nounset

ID=$1
OUT_FILE=~/.ncbi/genome/$(echo $1 | tr '.' '_').gb.gz

wget \
	"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${ID}&rettype=gbwithparts&retmode=text" \
	--quiet \
	--output-document - \
| pigz -11 > ${OUT_FILE}
