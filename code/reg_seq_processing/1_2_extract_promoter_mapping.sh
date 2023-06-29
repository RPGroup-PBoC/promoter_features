#!/opt/homebrew/bin/bash
# 
# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help    Display this help message"
 echo " -i, --in      File path to input file"
 echo " -g, --index   File path to index file"
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

      -i | --in*)
        if ! has_argument $@; then
          echo "Input file not specified." >&2
          usage
          exit 1
        fi

        IN_REL=$(extract_argument $@)
        IN=$(realpath $IN_REL)
        shift
        ;;
        
      -g | --index*)
        if ! has_argument $@; then
          echo "Index file not specified." >&2
          usage
          exit 1
        fi

        INDEX_REL=$(extract_argument $@)
        INDEX=$(realpath $INDEX_REL)
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
if [ ! "$IN" ] || [ ! "$INDEX" ] || [ ! "$OUT_FOLDER" ]; then
  echo "arguments -i, -g and -o must be provided" >&2;
  usage; exit 1
fi


# create output folder if not existing yet
if [ ! -d $OUT_FOLDER ] 
then 
    mkdir $OUT_FOLDER
fi

## Make temporary directory
# the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=$(mktemp -d "$DIR"/tmpXXXXX)

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# Declare dictionary
declare -A dict

while IFS=' ' read -r value key; do
    dict[$key]=$value
done < $INDEX



# load file > find primer sequence > check for length > find index, barcode and promoter > store by index
echo "Filtering and extracting barcodes"
cat $IN | awk '/TATTAGGCTTCTCCTCAGCG/' | awk -v o=$WORK_DIR '{ if (length($0) == 295 || length($0)==299)
    {ind_loc=index($0, "TATTAGGCTTCTCCTCAGCG"); Index=substr($0, ind_loc+20, 4);prom=substr($0, 21, 160); bc=substr($0,256,20); printf "%s\t%s\n", prom, bc >> (o"/"Index".txt") };}' 

echo "Count unique pairs"
for FILE in $WORK_DIR/*;do
    filename="${FILE##*/}"
    filename="${filename%.*}" 
    if ([[ ${dict[$filename]} ]])
    then 
        sort -T "." --parallel 20 $FILE| uniq -c | sort -T "." -bgr  --parallel 20|  awk -v OFS="\t" '$1=$1' > $OUT_FOLDER"/"${dict[$filename]}"_mapping_counted.csv";
    fi
done
