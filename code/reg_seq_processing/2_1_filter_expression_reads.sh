#!/opt/homebrew/bin/bash -i
# Find working directiory


# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help    Display this help message"
 echo " -i, --read1   File path to read 1"
 echo " -o, --out     File path to output"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;

      -i | --read1*)
        if ! has_argument $@; then
          echo "Read 1 not specified." >&2
          usage
          exit 1
        fi

        READ1_REL=$(extract_argument $@)
        READ1=$(realpath $READ1_REL)
        shift
        ;;

      -o | --out*)
        if ! has_argument $@; then
          echo "Output directory not specified." >&2
          usage
          exit 1
        fi

        OUT_FOLDER_REL=$(extract_argument $@)
        if [ ! -d $OUT_FOLDER_REL ]
            then 
             mkdir $OUT_FOLDER_REL
        fi  
        OUT_FOLDER=$(realpath $OUT_FOLDER_REL)

        shift
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

# Main script execution
handle_options "$@"

# mandatory arguments
if [ ! "$READ1" ] || [ ! "$OUT_FOLDER" ]; then
  echo "arguments -i and -o must be provided" >&2;
  usage; exit 1
fi

# make output folder if not existing
if [ ! -d $OUT_FOLDER ] 
then 
    mkdir $OUT_FOLDER
fi

# Find file name
filename="${READ1##*/}"
filename="${filename%.*}" 


HTML=$OUT_FOLDER"/mapping_fastp_report.html"
JSON=$OUT_FOLDER"/mapping_fastp_report.json"
fastp -i $READ1 -o $OUT_FOLDER/test_filtered.fastq  --verbose --html $HTML --json $JSON --report_title $html_report --thread '12'  --average_qual '30'  --n_base_limit '0' --unqualified_percent_limit '10'