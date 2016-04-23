#!/bin/bash
################################################################################
#                           The MIT License (MIT)                              #
#                     Copyright (c) 2015 Jean-Yves VET                         #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or  #
# sell copies of the Software, and to permit persons to whom the Software is   #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING      #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS #
# IN THE SOFTWARE.                                                             #
#                                                                              #
#------------------------------------------------------------------------------#
#   Author:    - Jean-Yves VET  (contact[at]jean-yves.vet)                     #
#                                                                              #
##----[ DESCRIPTION ]---------------------------------------------------------##
#  A strong password generator.                                                #
#                                                                              #
##----[ ARGUMENTS ]-----------------------------------------------------------##
#   -n <num>    Number of characters                                           #
#   -h          Display help                                                   #
#   -c          Enable colors                                                  #
################################################################################


##----[ PARAMETERS ]----------------------------------------------------------##

readonly NUM="0123456789"                       # String of numercial char.
readonly SCHAR="@#%&*+-=$"                      # String of special char.
readonly ALPHA_LOW="abcdefghijklmnopqrstuvwxyz" # String of lower case char.
readonly MIN_CHAR=8                             # Min number of char in pass.
readonly MAX_CHAR=16                            # Maxnumber of char/ in pass.
readonly MIN_MAX_LOW=(1 -)           # Array containing min max for lower char.
readonly MIN_MAX_UP=(1 -)            # Array containing min max for upper char.
readonly MIN_MAX_NUM=(1 -)           # Array containing min max for num. char.
readonly MIN_MAX_SCHAR=(1 1)         # Array containing min max for spec. char.
ENABLE_COLORS="false"                # Disable colors by default


##----[ GLOBAL VARIABLES ]----------------------------------------------------##

ALPHA_UP="`echo \"$ALPHA_LOW\" | tr '[:lower:]' '[:upper:]'`" # Gen. upper case.
LENGTH=$MAX_CHAR                       # Initialize length of the password
NB_LOW=${MIN_MAX_LOW[0]}               # Initialize min occurences of lower char
NB_UP=${MIN_MAX_UP[0]}                 # Initialize min occurences of upper char
NB_NUM=${MIN_MAX_NUM[0]}               # Initialize min occurences of num. char
NB_SCHAR=${MIN_MAX_SCHAR[0]}           # Initialize min occurences of spec. char
PASSWORD=""                            # Initialize password content


##----[ ERRORS ]--------------------------------------------------------------##

    declare -A ERRORS
    ERRORS["not_number"]="input argument is not a number."
    ERRORS["invalid_opt"]="invalid option."
    ERRORS["too_small"]="size too small to match the sum of each char min size."


##----[ WARNINGS ]------------------------------------------------------------##

    declare -A WARNINGS
    WARNINGS["min_size"]="minimum password size is set to \$MIN_CHAR."
    WARNINGS["max_size"]="maximum password size is set to \$MAX_CHAR."


##----[ FUNCTIONS ]-----------------------------------------------------------##

    ############################################################################
    # Print usage.                                                             #
    # Args:                                                                    #
    #        None                                                              #
    function usage()
    {
        echo "Usage: $(basename "$0") [OPTION]"
        echo "  -n <num>    Number of characters (min:$MIN_CHAR, max:$MAX_CHAR)"
        echo "  -h          Display help"
        echo "  -c          Enable colors"
    }

    ############################################################################
    # Print warning in stderr.                                                 #
    # Args:                                                                    #
    #      -$1: Warning code.                                                  #
    # Result: Print warning.                                                   #
    function print_warning()
    {
        # Extract argument
        local warning_code="${1}"

        # Get warning description
        eval "msg=\"${WARNINGS[${warning_code}]}\""

        # Check if colors are enabled
        if [ ${ENABLE_COLORS} = "true" ]; then
            echo -e "\033[1;31mwarning:\033[0m \033[31m${msg}\033[0m" 1>&2
        else
            echo "warning: ${msg}" 1>&2
        fi
    }

    ############################################################################
    # Print error in stderr.                                                   #
    # Args:                                                                    #
    #      -$1: Error code.                                                    #
    # Result: Print error.                                                     #
    function print_error()
    {
        # Extract argument
        local error_code="${1}"

        # Get error description
        eval "msg=\"${ERRORS[${error_code}]}\""

        # Check if colors are enabled
        if [ ${ENABLE_COLORS} = "true" ]; then
            echo -e "\033[1;31merror:\033[0m \033[31m${msg}\033[0m" 1>&2
        else
            echo "error: ${msg}" 1>&2
        fi
    }

    ############################################################################
    # Check input and get password length.                                     #
    # Args:                                                                    #
    #        All arguments provided.                                           #
    function check_arguments()
    {
        # Available options
        local options="hcn:"

        # Desactivate error handling by getops
        OPTERR=0

        # Look for color option first
        while getopts $options OPT; do
            case "$OPT" in
                c)
                    ENABLE_COLORS="true"
                    ;;
            esac
        done

        # Reinitialize index
        OPTIND=1

        # Parse arguments
        while getopts $options OPT; do
            case "$OPT" in
                h)
                    usage; exit 0
                    ;;
                n)
                    local regex='^[0-9]+$'

                    if [[ $OPTARG =~ $regex ]]; then
                        if [ $OPTARG -lt $MIN_CHAR ]; then
                            LENGTH=$MIN_CHAR
                            print_warning "min_size"
                        elif [ $OPTARG -le $MAX_CHAR ]; then
                            LENGTH=$OPTARG
                        else
                            print_warning "max_size"
                        fi
                    else
                        print_error "not_number"; exit 1
                    fi
                    ;;
                \?)
                    print_error "invalid_opt"
                    usage; exit 1
                    ;;
            esac
        done
    }

    ############################################################################
    # Compute characters left to add to the password based on min size of each #
    # character type.                                                          #
    # Args:                                                                    #
    #        None                                                              #
    function compute_left()
    {
        LEFT=$(( $LENGTH - $NB_LOW - $NB_UP - $NB_NUM - $NB_SCHAR ))

        # Ensure LEFT is still positive
        if [ $LEFT -lt 0 ]; then
			print_error "too_small"; exit 1
        fi
    }

    ############################################################################
    # Compute total occrences for the given character type.                    #
    # Args:                                                                    #
    #        $1 : in/out variable to retrieve/store occurence count            #
    function compute_occurence()
    {
        # Extract parameters
        local inoutvar="$1"
        local max="$2"

        # Init variables
        local res=$max
        eval "local val=\$$inoutvar"

        # Check if maximum characters LEFT may be used
        if [ $max == "-" ] || [ $max -gt $LEFT ]; then
            res=$LEFT
        fi

        # Add occurences to the character type, update characters LEFT
        if [ $max == "-" ] || [ $val -lt $max  ]; then
            # Compute randomly
            res=$(($RANDOM % ($res + 1)))
            LEFT=$(($LEFT - $res))
            res=$(($res + $val))

            eval "$inoutvar=\"$res\""
        fi
    }

    ############################################################################
    # Generate sub password for the given character type.                      #
    # Args:                                                                    #
    #        $1 : character type                                               #
    #        $2 : sub password size                                            #
    function sub_pass()
    {
        # Extract parameters
        local string_char="$1"
        local size="$2"
        local res=""

        local nb_chars=${#string_char}

        # Retrieve characters
        for i in `seq 1 $size`; do
            index=$(( $RANDOM % $nb_chars ))
            res="$res${string_char:${index}:1}"
        done

        PASSWORD="$PASSWORD$res"
    }

    ############################################################################
    # Shuffle characters in the password.                                      #
    # Args:                                                                    #
    #        None                                                              #
    function shuffle_pass()
    {
        PASSWORD=`echo "$PASSWORD" | fold -w1 | shuf | tr -d '\n'`
    }


##----[ MAIN ]----------------------------------------------------------------##

# Retrive and check all provided arguments
check_arguments $*

# Compute characters left to use to generate the password
compute_left

# Display warnings and errors
echo "Generating a $LENGTH characters password:"

# Compute size of each portion type
while [ $LEFT -gt 0 ]; do
    compute_occurence "NB_LOW"   ${MIN_MAX_LOW[1]}
    compute_occurence "NB_UP"    ${MIN_MAX_UP[1]}
    compute_occurence "NB_NUM"   ${MIN_MAX_NUM[1]}
    compute_occurence "NB_SCHAR" ${MIN_MAX_SCHAR[1]}
done

# Generate sub parts of the password
sub_pass "$ALPHA_LOW" "$NB_LOW"
sub_pass "$NUM"       "$NB_NUM"
sub_pass "$ALPHA_UP"  "$NB_UP"
sub_pass "$SCHAR"     "$NB_SCHAR"

# Shuffle all characters and output the password
shuffle_pass

echo $PASSWORD
