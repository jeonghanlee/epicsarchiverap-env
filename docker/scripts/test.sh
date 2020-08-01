#!/usr/bin/env bash

function PRINT
{
    printf "Test %s\n" "$1";
}

echo "Env"
cat docker_env_default.conf
printf "filename_test\n"
bash docker_builder.bash -f filename_test -d
PRINT "1"
bash docker_builder.bash -o TEST1 -d
PRINT "2"
bash docker_builder.bash -o TEST1 -i TEST2 -d
PRINT "3"
bash docker_builder.bash -o TEST1 -i TEST2 -t TEST3 -d
PRINT "4"
bash docker_builder.bash -o TEST1 -i TEST2 -t TEST3 -a TEST4 -d
PRINT "3.5"
bash docker_builder.bash -o TEST1 -i TEST2 -t TEST3 -a TEST4 -v TEST3.5 -f TEST1.5 -d
