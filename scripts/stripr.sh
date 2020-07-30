#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>> /config/logs/striplog.txt 2>&1
####################################################################
# Credits for the code.                                            #
#  https://github.com/theskyisthelimit/ubtuntumkvtoolnix           #
#  https://github.com/MarcelCosta79/RadarrM                        #
#                                                                  #
# I've just made some tweaks.                                      #
####################################################################

fpath="$radarr_moviefile_path"
file=$(basename "$fpath")
ss=$(dirname "$fpath")
cd "$ss"

echo
date
echo $file
DETAILS=$(mkvmerge -J "$file")
echo "$DETAILS"

audio=$(echo "$DETAILS" | jq '[.tracks[] | select (.type=="audio" and (.properties.language | test("eng|por|und"))) | select (.codec | test("truehd"; "i") | not) | .id] | map(tostring) | join(",")' | cut -f2 -d\")
audiocount=$(echo $audio | tr "," "\n" | wc -l)
echo "1: Found audio tracks $audio ($audiocount) to keep"

subs=$(echo "$DETAILS" | jq '[.tracks[] | select (.type=="subtitles" and (.codec | test("srt"; "i")) and (.properties.language | test("eng|por|und"))) | .id] | map(tostring) | join(",")' | cut -f2 -d\")
subscount=$(echo $subs | tr "," "\n" | wc -l)
echo "2: Found subtitle tracks $subs ($subscount) to keep"

#totalaudio=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="audio") | .id' | wc -l)
#totalsubs=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="subtitles") | .id' | wc -l)

#diffaudio=$(expr $totalaudio - $audiocount)
#diffsubs=$(expr $totalsubs - $subscount)

if [ -z "$audio" ] && [ -z "$subs" ] ; then
  echo "3: Nothing to remove. Will exit script now."
elif [ -z "$audio" ] ; then
  subs="-s $subs"
  mkvmerge $subs -o "${file%.mkv}".edited.mkv "$file"; #keep Orignal audio
  mv "${file%.mkv}".edited.mkv "$file"
  echo "4: Kept orginal audio. Unwanted Subtitles found and removed!"
else
  if [ -z "$subs" ] ; then
    subs="-S"
  else
    subs="-s $subs"
  fi
  audio="-a $audio";
  mkvmerge $subs $audio -o "${file%.mkv}".edited.mkv "$file";
  mv "${file%.mkv}".edited.mkv "$file"
  echo "5: Unwanted audio and/or subtitles found and removed!"
fi

exit

