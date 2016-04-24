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
#  Unit tests for strong password generator.                                   #
#                                                                              #
################################################################################


##----[ GLOBAL VARIABLES ]----------------------------------------------------##

TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPASS_ENABLE_TESTS=1

. $TEST_DIR/../spass.sh


##----[ UNIT TESTS ]----------------------------------------------------------##

test_check_arguments()
{
    # Check color enabling
    check_arguments "-c" > /dev/null  2>&1
    assertEquals "Enable colors return code" "0" "$?"
    assertEquals "Colors option" "$ENABLE_COLORS" "true"

    # Check minimum password size
    check_arguments "-n" "$(($MIN_CHAR - 1))" > /dev/null  2>&1
    assertEquals "Change password size (<MIN_CHAR) return code" "0" "$?"
    assertEquals "Minimum password size" "$MIN_CHAR" "$LENGTH"

    # Check maximum password size
    check_arguments "-n" "$(($MAX_CHAR + 1))" > /dev/null  2>&1
    assertEquals "Change password size (>MAX_CHAR) return code" "0" "$?"
    assertEquals "Maximum password size" "$MAX_CHAR" "$LENGTH"

    # Check password size
    check_arguments "-n" "$(($MAX_CHAR - 1))" > /dev/null  2>&1
    assertEquals "Change password size return code" "0" "$?"
    assertEquals "$LENGTH" "$(($MAX_CHAR - 1))"

    # Check password size not a number
    check_arguments "-n" "notnum" > /dev/null  2>&1
    assertEquals "Not not a number return code" "$ENOTNUM" "$?"

    # Check wrong argument
    check_arguments "-y" > /dev/null  2>&1
    assertEquals "Wrong argument return code" "$EINVOPT" "$?"
}

test_compute_left()
{
    # Check correct char left
    LENGTH=$(( $NB_LOW + $NB_UP + $NB_NUM + $NB_SCHAR + 1 ))
    compute_left > /dev/null  2>&1
    assertEquals "Correct char left return code" "0" "$?"

    # Check wrong char left
    LENGTH=$(( $NB_LOW + $NB_UP + $NB_NUM + $NB_SCHAR - 1 ))
    compute_left > /dev/null  2>&1
    assertEquals "Wrong char left return code" "$E2SMALL" "$?"
}

test_compute_occurences()
{
    # Check value increased
    LEFT=4
    INOUT=0
    compute_occurences "INOUT" "4" > /dev/null  2>&1
    assertTrue "Increased occurences" "[ $INOUT -ge 0 ] && [ $INOUT -le 4 ]"
    assertEquals "Updated (decreased) char LEFT" "$((4 - $INOUT))" "$LEFT"

    # Check value increased if successive calls
    local old_left=$LEFT
    local old_inout=$INOUT
    compute_occurences "INOUT" "4" > /dev/null  2>&1
    assertTrue "Still increased occurences" "[ $INOUT -ge $old_inout ]"
    assertTrue "Still decreased char LEFT" "[ $LEFT -le $old_left ]"

    # Check value already reached
    LEFT=4
    INOUT=4
    compute_occurences "INOUT" "4" > /dev/null  2>&1
    assertEquals "Ensure occurences is unmodified" "4" "$INOUT"
    assertEquals "Ensure char LEF is unmodified" "4" "$LEFT"

    # Check no char left to add
    LEFT=0
    INOUT=0
    compute_occurences "INOUT" "4" > /dev/null  2>&1
    assertEquals "Ensure no char left to add" "0" "$INOUT"
    assertEquals "Ensure char LEFT stays null" "0" "$LEFT"
}

test_sub_pass()
{
    # Check correct char left
    PASSWORD=""
    sub_pass "$ALPHA_LOW" "4" > /dev/null  2>&1
    assertEquals "Sub pass return code" "0" "$?"
    assertEquals "Ensure correct size for sub pass" "4" "${#PASSWORD}"
}

test_shuffle_pass()
{
    # Check password has been shuffled
    PASSWORD="1234Ab"
    local old_password=$PASSWORD
    shuffle_pass > /dev/null  2>&1
    assertEquals "Shuffling doe not change size" "${#old_password}" "${#PASSWORD}"
    assertNotSame "Shuffling string are different" "$old_password" "$PASSWORD"
}


##----[ MAIN ]----------------------------------------------------------------##

. shunit2-2.0.3/src/shell/shunit2
unset SPASS_ENABLE_TESTS
