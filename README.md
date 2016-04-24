StrongPass
=========

Bash script to generate a strong password of a given size.


Running StrongPass
-------------------

    Usage: spass.sh [OPTION]
      -n <num>    Number of characters (min:8, max:16)
      -h          Display help
      -c          Enable colors

Example
-------

    ./spass.sh -n 14

    Generating a 14 characters password:
    5C1Ml#OqFMVm3b


Running unit tests
------------------

    wget -O - "http://downloads.sourceforge.net/shunit2/shunit2-2.0.3.tgz" | tar zx
    bash tests/test_strongpass.sh

