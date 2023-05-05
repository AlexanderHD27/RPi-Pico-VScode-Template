#!/usr/bin/bash
cd $1

rm -rf * !(*.h)
rm -rf .cmake
cmake ..