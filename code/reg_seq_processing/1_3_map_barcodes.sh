#!/opt/homebrew/bin/bash -i 

# get aliases
shopt -s expand_aliases

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help      Display this help message"
 echo " -w, --wt        File path to wild type sequences"
 echo " -g, --groups    File path to gene groups file"
 echo " -m, --mapping   File path to mapping data file"
 echo " -o, --out       File path to output"
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

      -w | --wt*)
        if ! has_argument $@; then
          echo "Wild type sequences file not specified." >&2
          usage
          exit 1
        fi

        WT_REL=$(extract_argument $@)
        WT=$(realpath $WT_REL)
        shift
        ;;
        
      -g | --groups*)
        if ! has_argument $@; then
          echo "File containing gene groups not provided." >&2
          usage
          exit 1
        fi

        GROUPS_REL=$(extract_argument $@)
        GENE_GROUPS=$(realpath $GROUPS_REL)
        shift
        ;;

      -m | --mapping*)
        if ! has_argument $@; then
          echo "File containing promoters and barcodes not provided." >&2
          usage
          exit 1
        fi

        MAPPING_REL=$(extract_argument $@)
        MAPPING=$(realpath $MAPPING_REL)
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
if [ ! "$WT" ] || [ ! "$GENE_GROUPS" ] || [ ! "$MAPPING" ] || [ ! "$OUT_FOLDER" ]; then
  echo "arguments -w, -g, m and -o must be provided" >&2;
  usage; exit 1
fi


# create output folder if not existing yet
if [ ! -d $OUT_FOLDER ] 
then 
    mkdir $OUT_FOLDER
fi

julia  1_3_map_barcodes.jl  $WT $GENE_GROUPS $MAPPING $OUT_FOLDER 