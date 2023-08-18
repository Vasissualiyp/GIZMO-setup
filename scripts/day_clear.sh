#!/bin/bash

# Get today's date in YYYY-MM-DD format
TODAY=$(date +"%Y-%m-%d")
TODAYDOT=$(date +"%Y.%m.%d")

# Remove directories matching the pattern
rm -f -r ./archive/${TODAY}*

rm -f -r ./output/${TODAYDOT}*
rm -f  ./output/DM+Baryons_${TODAYDOT}*

# Subtract a day from today's date
YESTERDAY=$(date -d "${TODAY} -1 day" +"%Y.%m.%d")

# Use vim to find and replace the date in the file
vim -c "%s/OutputDir\s*\.\/output\/[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}:/OutputDir                               .\/output\/${YESTERDAY}:/g" -c 'wq' zel.params

