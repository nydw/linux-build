#===============================================================================
# Function will print out help on screen.
# Usage: print_usage
#===============================================================================
function _usage()
{
cat << EOF
Usage: $(basename $0) [-f <component file>] [-d] [-h] [-e] [-t] [component list]

Build Linux From Scratch (LFS) distribution

Options:
    -f,         Load component config file
    -d,         Run in debug mode
    -h,         Print help message
    -e,         Print the chroot environment
    -t,         Build toolchain from component list or file

Example:
    $(basename $0) -t conf/lfs-7.1-tools.cfg

EOF
}

#===============================================================================
# Function will setup a working environment for the toolchain.
#===============================================================================
function env_toolchain()
{
    # Get number of processors for concurrent building
    local CPUS="$(grep -c ^processor /proc/cpuinfo)"

    # Unset each variable and only keep the necessary ones.
    unset $(/usr/bin/env | egrep '^(\w+)=(.*)$' | \
        egrep -vw 'HOME|TERM|PATH|PWD|SHLVL|_|http_proxy|https_proxy|LFS' | /usr/bin/cut -d= -f1);

    set +h
    umask 022

    LC_ALL=POSIX
    LFS_TGT=$(uname -m)-proximus-linux-gnu
    PATH=$LFS$TOOLS/bin:/bin:/usr/bin
    PS1='\u:\w\$ '
    MAKEFLAGS="-j $CPUS"

    export LFS TOOLS LC_ALL LFS_TGT PATH PS1 MAKEFLAGS
}

#===============================================================================
# Function will enter the chroot environment. Must be root to run chroot!
#===============================================================================
function env_chroot()
{
    if [[ -z "$LFS" ]]; then
        echo "$0 Error: Variable \"LFS\" is not set"; exit 1
    fi
    if [[ -z "$TOOLS" ]]; then
        echo "$0 Error: Variable \"TOOLS\" is not set"; exit 1
    fi

cat << EOF
sudo chroot "$LFS" $TOOLS/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:$TOOLS/bin \
    $TOOLS/bin/bash --login +h
EOF
}

#===============================================================================
# Function with customized print.
#===============================================================================
function print_me()
{
    printf "$(/bin/date +"%F-%T") %-*s %s" "$1" "$2"
}

#===============================================================================
# Function will print ok in color.
#===============================================================================
function print_ok()
{
    printf '%b\n' "\e[1;32m[  OK  ]\e[m"
}

#===============================================================================
# Function will print fail in color.
#===============================================================================
function print_fail()
{
    printf '%b\n' "\e[1;31m[ FAIL ]\e[m"
    echo "================================================================================"
    echo "Dumping debug environement"
    echo "================================================================================"
    env

    echo "================================================================================"
    echo "Dumping debug error logs"
    echo "================================================================================"
    /usr/bin/tail -n 10 $LOGDIR/*.err
}
