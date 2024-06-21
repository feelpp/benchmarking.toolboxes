#!/bin/bash

# /testcases/.../fluid/.../TurekHron.cfg is an empty .cfg file

# --case option to be done

usage() {
    echo "Usage: $0 <machine> [-a|--all] [-tb name|--toolbox=name] [-c path|--case=path] [-h|--help]"
    echo "  <machine>                   Name of the machine "
    echo "  -a, --all                   Launch every test of every toolbox"
    echo "  -tb name, --toolbox name    Name of the toolbox (multiple names separated by ':')"
    echo "                              If no case provided, will launch every test from the toolbox"
    echo "  -c path, --case path        Path to the case .cfg file (multiple paths separated by ':', requires -tb)"
    echo "  -h, --help                  Display help"
}

split_arguments() {
    local input="$1"
    IFS=':' read -r -a result <<< "$input"
    echo "${result[@]}"
}

valid_machines=("discoverer" "gaya" "karolina" "meluxina" "local")
valid_toolboxes=("alemesh" "coefficientformpdes" "electric" "fluid" "fsi" "hdg" "heat" "heatfluid" "solid" "thermoelectric")



# +-------------------------------------------------+
# |                ARGUMENTS CHECK                  |
# +-------------------------------------------------+

if [ $# -lt 1 ] || [ "$*" == "-h" ] || [ "$*" == "--help" ]; then
    usage
    exit 0
fi

hostname=$1
shift

if ! [[ " ${valid_machines[@]} " =~ " $hostname " ]]; then
    echo "Error: $hostname machine is unknown"
    echo "Valid machines: ${valid_machines[@]}"
    exit 0
fi


toolboxes=()
cases=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            toolboxes=("${valid_toolboxes[@]}")
            shift
            ;;
        -tb|--toolbox)
            if [[ -n "$2" ]]; then
                toolboxes=($(split_arguments "$2"))
                for tb in "${toolboxes[@]}"; do
                    if ! [[ " ${valid_toolboxes[@]} " =~ " $tb " ]]; then
                        echo "Error: $tb toolbox is unknown"
                        echo "Valid toolboxes: ${valid_toolboxes[@]}"
                        exit 0
                    fi
                done
                shift 2
            else
                echo "Error: --toolbox requires an argument"
                exit 0
            fi
            ;;
        -c|--case)
            if [[ -n "$2" ]]; then
                cases="$2"
                shift 2
            else
                echo "Error: --case requires an argument"
                exit 0
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 0
            ;;
    esac
done

if [ -n "$cases" ] && [ "${#toolboxes[@]}" -eq 0 ]; then
    echo "Error: --case requires --toolbox to be specified."
    usage
    exit 1
fi

# +-------------------------------------------------+
# |                 PROCESS START                   |
# +-------------------------------------------------+


rm -rf ~/feelppdb
rm -rf ./build/reframe/output/ ./build/reframe/stage/ ./build/reframe/perflogs


export RFM_CONFIG_FILES=$(pwd)/src/feelpp/benchmarking/reframe/cluster-config/${hostname}.py
export RFM_PREFIX=$(pwd)/build/reframe/

disk_path="/home"
#disk_path="/data/home"
#disk_path="/data/scratch/"
#disk_path="/nvme0/"

export RFM_TEST_DIR=$(pwd)/src/feelpp/benchmarking/reframe/regression-tests/
export FEELPP_TOOLBOXES_CASES=/usr/share/feelpp/data/testcases/toolboxes/
export FEELPP_OUTPUT_PREFIX="${disk_path}/${USER}/feelppdbTANGUYYYY"

columns=$(tput cols)
current_date=$(date +%Y%m%d)

counter=0

for tb in "${toolboxes[@]}"; do
    echo -e "\n"
    yes '=' | head -n "$columns" | tr -d '\n'
    echo "[PROCESS LAUNCHED ON ${tb^^} TOOLBOX]"

    #toolboxCounter=0
    extended_path="${FEELPP_TOOLBOXES_CASES}/${tb}/cases"

    while read -r cfgPath; do
        counter=$((counter + 1))
        toolboxCounter=$((toolboxCounter + 1))

        echo ""
        yes '-' | head -n "$columns" | tr -d '\n'
        relative_path=${cfgPath#"$FEELPP_TOOLBOXES_CASES"}
        relative_dir=$(dirname "$relative_path")
        base_name=$(basename "${relative_path%.cfg}")

        report_path=$(pwd)/docs/modules/${hostname}/pages/reports/${toolbox}/${relative_dir}/${current_date}-${base_name}.json

        echo "[Launching $relative_path on $hostname]"
        #reframe -c $RFM_TEST_DIR/heatTest.py -S case=$cfgPath -r --system=$hostname --report-file=$report_path

    done < <(find "$extended_path" -type f -name "*.cfg")
    #echo "[$tb] .cfg files: $toolboxCounter"
done


echo -e "\n[TOTAL] .cfg files: $counter"
