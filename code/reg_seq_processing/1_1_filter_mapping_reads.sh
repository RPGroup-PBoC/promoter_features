#!/opt/homebrew/bin/bash -i 

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help    Display this help message"
 echo " -i, --read1   File path to read 1"
 echo " -I, --read2   File path to read 2"
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

        READ1=$(extract_argument $@)

        shift
        ;;
      -I | --read2*)
        if ! has_argument $@; then
          echo "Read 2 not specified." >&2
          usage
          exit 1
        fi

        READ2=$(extract_argument $@)

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
if [ ! "$READ1" ] || [ ! "$READ2" ] || [ ! "$OUT_FOLDER" ]; then
  echo "arguments -i, -I and -o must be provided" >&2;
  usage; exit 1
fi


if [ ! -d $OUT_FOLDER ] 
then 
    mkdir $OUT_FOLDER
fi

OUT=$OUT_FOLDER"/mapping_merged.fastq"

HTML=$OUT_FOLDER"/mapping_fastp_report.html"
JSON=$OUT_FOLDER"/mapping_fastp_report.json"

fastp --in1 $READ1 --in2 $READ2 --merged_out $OUT  --verbose --html $HTML --json $JSON --report_title $html_report --thread '6' --merge --overlap_len_require '3' --n_base_limit '0' 