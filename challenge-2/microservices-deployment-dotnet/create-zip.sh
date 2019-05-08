#!/bin/bash
set -e

CD=$PWD

cd ./ValidationAzFunctions/bin/Release/netcoreapp2.1/publish/

rm ./ValidationAzFunctions.zip --force

zip -r ValidationAzFunctions.zip .

cd $CD

rm ./ValidationAzFunctions.zip --force

mv ./ValidationAzFunctions/bin/Release/netcoreapp2.1/publish/ValidationAzFunctions.zip ./