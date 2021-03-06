#!/usr/bin/env bash
# Convert IMGT germlines sequences to IgBLAST database
#
# Author:  Jason Anthony Vander Heiden
# Date:    2016.11.21
#
# Arguments:
#   -i = Input directory containing germlines in the form <species>/vdj/imgt_<species>_<chain><segment>.fasta
#   -o = Output directory for the built database. Defaults to current directory.
#   -h = Display help.

# Default argument values
OUTDIR="."

# Print usage
usage () {
    echo -e "Usage: `basename $0` [OPTIONS]"
    echo -e "  -i  Input directory containing germlines in the form:"
    echo -e "      <species>/vdj/imgt_<species>_<chain><segment>.fasta."
    echo -e "  -o  Output directory for the built database."
    echo -e "  -h  This message."
}

# Get commandline arguments
while getopts "i:o:h" OPT; do
    case "$OPT" in
    i)  GERMDIR=$(realpath $OPTARG)
        GERMDIR_SET=true
        ;;
    o)  OUTDIR=$OPTARG
        OUTDIR_SET=true
        ;;
    h)  usage
        exit
        ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)  echo "Option -$OPTARG requires an argument" >&2
        exit 1
        ;;
    esac
done

# Exit if no germline directory provided
if ! $GERMDIR_SET; then
    echo "You must specify an input directory using the -i option" >&2
    exit 1
fi

# Create and set directories
OUTDIR=$(realpath ${OUTDIR})
mkdir -p ${OUTDIR}/fasta
TMPDIR=$(mktemp -d)

# Create fasta files of each species, chain and segment combination
for SPECIES in human mouse
do
    for CHAIN in IG TR
    do
        for SEGMENT in V D J
        do
            cat ${GERMDIR}/${SPECIES}/vdj/imgt_${SPECIES}_${CHAIN}?${SEGMENT}.fasta \
                > $TMPDIR/imgt_${SPECIES,,}_${CHAIN,,}_${SEGMENT,,}.fasta
            #SEGMENT_FASTA="${GERMDIR}/${SPECIES}/vdj/imgt_${SPECIES}_${CHAIN}?${SEGMENT}.fasta"
            #if [ -f "${SEGMENT_FASTA}" ]; then
            #    cat ${SEGMENT_FASTA} > "${TMPDIR}/imgt_${SPECIES,,}_${CHAIN,,}_${SEGMENT,,}.fasta"
            #fi
        done
    done
done

# Parse each created fasta file to create igblast database
cd ${TMPDIR}
for F in $(ls *.fasta)
do
	clean_imgtdb.py ${F} ${OUTDIR}/fasta/${F}
	makeblastdb -parse_seqids -dbtype nucl -in ${OUTDIR}/fasta/${F} \
        -out ${OUTDIR}/database/${F%%.*}
done

# Remove temporary fasta files
cd -; rm -rf $TMPDIR
