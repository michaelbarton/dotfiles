#!/bin/bash

set -o nounset
set -o errexit
set -o xtrace
shopt -s extglob

ID=$1
OUT_FILE=~/.ncbi/assembly/$(echo $1 | tr '.' '_').fa.gz
mkdir -p ~/.ncbi/assembly/

TMP_DIR=$(mktemp -d)
TMP_FILE=${TMP_DIR}/assembly.zip

wget \
	"https://api.ncbi.nlm.nih.gov/datasets/v1/genome/accession/${ID}/download?filename=${ID}.zip" \
	--quiet \
	--output-document - \
        > ${TMP_FILE}

cd ${TMP_DIR}
unzip ${TMP_FILE}

SRC_FILE=("${TMP_DIR}/ncbi_dataset/data/${ID}/*.fna")

pigz --best ${SRC_FILE} --stdout > ${OUT_FILE}
