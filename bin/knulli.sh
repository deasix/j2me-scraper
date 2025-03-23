#!/bin/bash
#
# Simple script for adding metadata to J2ME games on knulli/batocera.

# capture logs
set -euo pipefail
log="/tmp/j2me-scraper.log"
exec > >(tee -a "$log") 2> >(tee -a "$log" >&2)
trap 'echo "Error occurred. See logs: $log"; exit 1' ERR

# system
r="${1:-""}"
tmp="$(mktemp -d)"

#  j2me
d_j2me_impr="$r/userdata/screenshots"
d_j2me_roms="$r/userdata/roms/j2me"
d_j2me_imgs="$d_j2me_roms/images"

# scraper
d_scpr_roms="$(readlink -f "$(dirname "$0")")"
d_scpr_imgs="$d_scpr_roms/images"

# files
f_j2me_conf="$d_j2me_roms/gamelist.xml"
f_scpr_conf="$d_scpr_roms/gamelist.xml"
f_scpr_name="j2me-scraper.sh"

# resources
f_j2me_img="j2me-default.png"
f_scpr_img="j2me-scraper-default.png"
f_util_xml="$tmp/xml-util.py"
f_util_jar="$tmp/jar-util.sh"

# helpers
function new_data() {
   local src="$1" # filename
   local tag="$2" # tag name
   local val="$3" # tag value
   local pid="$4" # path value
   
   "$f_util_xml" "$src" "game" "$tag" "$val" "path" "./$pid"
}

function new_entry() {
   local src="$1" # filename
   local pid="$2" # path value
   
   "$f_util_xml" "$src" "gameList" "game" "<path>./$pid</path>"
}

function new_config() {
   local src="$1" # filename
   
   "$f_util_xml" "$src" "gameList"
}

# embedded resources
echo "Unpacking files..."
sed -n '/^# TARBALL_DATA/,$p' "$0" | \
   tail -n +2 | tar -xzm -C "$tmp"

# utility scripts
source $f_util_jar

# scraper metadata
if [ ! -f "$d_scpr_roms/$f_scpr_name" ]; then
   cp "$0" "$d_scpr_roms/$f_scpr_name"
   rm "$0" # self delete script
fi

[ ! -f "$f_scpr_conf" ] && new_config "$f_scpr_conf"
if ! grep -q "<path>./$f_scpr_name</path>" "$f_scpr_conf"; then
   echo "Adding scraper metadata..."
   
   scpr_base="${f_scpr_name%.*}"
   scpr_boxa="$scpr_base-thumb.png"
   scpr_imge="$scpr_base-image.png"

   mkdir -p "$d_scpr_imgs"
   cp "$tmp/$f_scpr_img" "$d_scpr_imgs"
   [ ! -f "$d_scpr_imgs/$scpr_boxa" ] && scpr_boxa="$f_scpr_img"
   [ ! -f "$d_scpr_imgs/$scpr_imge" ] && scpr_imge="$f_scpr_img"
   
   new_entry "$f_scpr_conf" "$f_scpr_name"
   new_data "$f_scpr_conf" "name" "J2ME Scraper" "$f_scpr_name"
   new_data "$f_scpr_conf" "desc" "Scrape J2ME Games" "$f_scpr_name"
   new_data "$f_scpr_conf" "image" "./images/$scpr_imge" "$f_scpr_name"
   new_data "$f_scpr_conf" "thumbnail" "./images/$scpr_boxa" "$f_scpr_name"
   new_data "$f_scpr_conf" "developer" "deasix" "$f_scpr_name"
   new_data "$f_scpr_conf" "publisher" "deasix.github.io" "$f_scpr_name"
fi

# j2me metadata
if [ -d "$d_j2me_roms" ]; then
   mkdir -p "$d_j2me_imgs"
   cp "$tmp/$f_j2me_img" "$d_j2me_imgs"
   [ ! -f "$f_j2me_conf" ] && new_config "$f_j2me_conf"
   
   for j2me in "$d_j2me_roms"/*.jar; do
      j2me_file="$(basename "$j2me")"
      j2me_base="$(basename "$j2me" .jar)"
   
      if ! grep -q "<path>./$j2me_file</path>" "$f_j2me_conf"; then
         echo "Scraping $j2me_file..."
         
         j2me_mani="$(extract "$j2me" "META-INF/MANIFEST.MF" $tmp)"
         j2me_name="$(scrape "$j2me_mani" "MIDlet-Name")"
         j2me_desc="$(scrape "$j2me_mani" "MIDlet-Description")"
         j2me_publ="$(scrape "$j2me_mani" "MIDlet-Vendor")"
         j2me_devl="$(scrape "$j2me_mani" "Developer")"
         j2me_boxa="$j2me_base-thumb.png"
         j2me_imge="$j2me_base-image.png"
         
         # try to extract boxart
         if [ ! -f "$d_j2me_imgs/$j2me_boxa" ]; then
            icon="$(scrape "$j2me_mani" "MIDlet-Icon")"
            icon="$(extract "$j2me" "$(basename "$icon")" "$tmp")"
            [ -f "$icon" ] && cp "$icon" "$d_j2me_imgs/$j2me_boxa"
         fi
         
         # try to import image
         if [ ! -f "$d_j2me_imgs/$j2me_imge" ] && [ -d "$d_j2me_impr" ] ; then
            impr="$(ls -t "$d_j2me_impr" | grep "$j2me_base" | head -n 1 || true)"
            [ -n "$impr" ] && cp "$d_j2me_impr/$impr" "$d_j2me_imgs/$j2me_imge"
         fi
         
         # use default | redundant checks but readable
         [ ! -f "$d_j2me_imgs/$j2me_boxa" ] && j2me_boxa="$f_j2me_img"
         [ ! -f "$d_j2me_imgs/$j2me_imge" ] && j2me_imge="$f_j2me_img"
         
         # fill missing values
         j2me_path="./$j2me_file"
         j2me_boxa="./images/$j2me_boxa"
         j2me_imge="./images/$j2me_imge"
         j2me_name="${j2me_name:-"$j2me_base"}"
         j2me_desc="${j2me_desc:-"Java Mobile Game"}"
         j2me_devl="${j2me_devl:-"Sun Microsystems"}"
         j2me_publ="${j2me_publ:-"Sun Microsystems"}"
         
         new_entry "$f_j2me_conf" "$j2me_file"
         new_data "$f_j2me_conf" "name" "$j2me_name" "$j2me_file"
         new_data "$f_j2me_conf" "desc" "$j2me_desc" "$j2me_file"
         new_data "$f_j2me_conf" "image" "$j2me_imge" "$j2me_file"
         new_data "$f_j2me_conf" "thumbnail" "$j2me_boxa" "$j2me_file"
         new_data "$f_j2me_conf" "developer" "$j2me_devl" "$j2me_file"
         new_data "$f_j2me_conf" "publisher" "$j2me_publ" "$j2me_file"
      fi
   done
fi

exit 0
# TARBALL_DATA
