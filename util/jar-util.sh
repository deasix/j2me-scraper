#!/bin/bash
#
# extract a file from a jar
# usage: icon="$(extract "$myjar" "icon.png" "$tmp")"
# usage: manifest="$(extract "$myjar" "META-INF/MANIFEST.MF" "$tmp")"
function extract() {
   local jar="$1" # filename of jar
   local res="$2" # file to extract
   local out="$3" # output directory
   
   unzip -jo "$jar" "$res" -d "$out" > /dev/null 2>&1
   echo "$out/$(basename "$res")"
}

# extract value from manifest.mf
# usage: name="$(scrape "$manifest" "MIDlet-Name")"
function scrape() {
   local src="$1" # manifest.mf
   local sid="$2" # search key
   
   result=$(grep "^$sid:" "$src" || true) # Ignore failure
   echo "$result" | awk -F': ' '{print $2}' | tr -d '\r\n' | xargs
}
