#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  prox-dist.sh
#
#         USAGE:  See prox-dist -h
#
#   DESCRIPTION:  This program is meant to be a tool for automatically building
#                 Linux From Scratch (LFS).
#
#                 1. Parse arguments from command line.
#                 2. Load...
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  path to env is different in chroot
#                 path to binaries will not work in chroot env
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  2013-03-13 09:00:00 IST
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================

#===============================================================================
# Global variables (immutable)
#===============================================================================
# Set the program file name
readonly PROGNAME=$(basename $0)

# Set the program directory path
readonly PROGDIR=$(readlink -m $(dirname $0))
#readonly PROGDIR=$( cd "$( dirname "$0" )" && pwd )

# Save all the program arguments
readonly ARGS="$@"

# Set the LFS variable
LFS=${PROGDIR}/lfs

TOOLS=/tmp/tools                            # Set the TOOLS variable
SOURCES=$LFS/usr/src/sources                # Set the SOURCES variable
LOGDIR=""                                   # Set the LOGDIR dynamically

component_list=                             # Init list of components to zero
component_file=                             # Init build component to zero
env_chroot="false"                          # Default is not to print chroot env
env_toolchain="false"                       # Default is not to build toolchain
component_file_defined="false"

source lib/functions.sh                     # Import functions from library
source lib/build.sh                         # Import the build functions

handle_arguments $PROGNAME $ARGS

while getopts ':def:ht-' opt; do
  case "$opt" in
    d)  set -x ;;
    e)  env_chroot="true" ;;
    f)
        if [ ! -f "$OPTARG" ]; then
            echo "$0 Error: Component file \"$OPTARG\" does not exist" >&2
            exit 1
        fi
        component_file_defined="true"
        component_file="$OPTARG"
        ;;
    h)
        print_usage $PROGNAME
        ;;
    t)
        env_toolchain="true"
        ;;
    ?)
        print_usage $PROGNAME
        echo "Error: Invalide option -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Error: Missing option argument for -$OPTARG" >&2
        exit 1
        ;;
  esac
done

# Decrements the argument pointer so it points to next argument
shift $(($OPTIND - 1))
# $1 now refer to the first non-option item supplied on the command-line
component_list="$1"

if [ "$component_file_defined=" = "true" ] && [ ! -f "$component_file" ]; then
    echo "$0 Error: Component file \"$component_file\" does not exist" >&2
    exit 1
fi

# Check if the optional file argument has been typed
if [ "$component_file_defined=" = "true" ]; then
    if [ ! -f "$OPTARG" ]; then
        echo "$0 Error: Component file \"$OPTARG\" does not exist" >&2
        exit 1
    fi
fi

# Check if component file is not defined and that the component list exists
if [ ! -f "$component_list" ] && [ -z "$component_file" ]; then
    echo "$0 Error: Component list \"$component_list\" does not exist";
    exit 1
fi

# Create TOOLS symbolic link
if [ ! -f $TOOLS ] && [ ! -L $TOOLS ]; then
   echo "Creating symlink"
   ln -svnf $LFS$TOOLS $TOOLS
fi

# Create the LFS directory
/bin/mkdir -pv $LFS

# Setup the build environment and export shell variables
if [ "$env_toolchain" = "true" ]; then
    env_toolchain
elif [ "$env_chroot" = "true" ]; then
    env_chroot
else
    echo "Error: Choose an environment"
    exit 1
fi

# Load config file into array and remove comments and other things we don't need
component_array=()
if [ "$component_list" ]; then
    while read line; do
        component_array+=(${line/\#*/})
    done < "$component_list"
fi
# Append component file given from command line
component_array+=(${component_file})

# Start building
for component in ${component_array[@]}; do
    # Set the log directory
    LOGDIR="$SOURCES/log/${component##*/}" && /bin/mkdir -p "$LOGDIR" || exit 1

    # Print the script
    echo "================================================================================"
    echo "Running: ${component}"
    echo "Log dir: ${LOGDIR}"
    echo "================================================================================"

    # Run the actual package build scipt
    source $(eval echo "$component")
done

echo "================================================================================"
echo "Finished building"
echo "================================================================================"
