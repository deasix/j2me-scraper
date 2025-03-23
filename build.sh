#!/bin/bash
# 
# simple script for building a single executable by embedding 
# resources and utility scripts to the scraper script file

# capture logs
set -euo pipefail
log="/tmp/j2me-scraper-build.log"
exec > >(tee -a "$log") 2> >(tee -a "$log" >&2)
trap 'echo "Error occurred. See logs: $log"; exit 1' ERR

# system
tmp="$(mktemp -d)"

# resources
embedded="res.tar.gz"

# parameters
scrapers=(${@:-bin/*.sh})

# directories
mkdir -p "build"

# build
tar -czf "$tmp/$embedded" -C "res" $(ls res) \
   -C "../util" $(ls util)
   
for scraper in "${scrapers[@]}"; do
   echo -n "Building $scraper..."
   
   output="j2me-scraper-$(basename "$scraper")"
   cp "$scraper" "$tmp/$output" && cat \
      "$tmp/$embedded" >> "$tmp/$output"
   mv "$tmp/$output" "build/"
   echo "Done."
done

# cleanup
echo "Cleaning up..."
rm -r "$tmp"
rm "$log"

# exit
echo "Done."
exit 0
