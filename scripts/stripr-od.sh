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

fpath="$1"
file=$(basename "$fpath")
ss=$(dirname "$fpath")
cd "$ss"

echo
date

if [ ! -r "$file" ] ; then 
  echo 'Cannot read "$fpath"'
  exit 1
fi

echo $file
DETAILS=$(mkvmerge -J "$file")
echo "$DETAILS"

audio=$(echo "$DETAILS" | jq '[.tracks[] | select (.type=="audio" and (.properties.language | test("eng|por|und"))) | select (.codec | test("truehd"; "i") | not) | .id] | map(tostring) | join(",")' | cut -f2 -d\")
audiocount=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="audio" and (.properties.language | test("eng|por|und"))) | select (.codec | test("truehd"; "i") | not) | .id' | wc -l)
echo "1: Found audio tracks $audio ($audiocount) to keep"

subs=$(echo "$DETAILS" | jq '[.tracks[] | select (.type=="subtitles" and (.codec | test("srt"; "i")) and (.properties.language | test("eng|por|und"))) | .id] | map(tostring) | join(",")' | cut -f2 -d\")
subscount=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="subtitles" and (.codec | test("srt"; "i")) and (.properties.language | test("eng|por|und"))) | .id'| wc -l)
echo "2: Found subtitle tracks $subs ($subscount) to keep"

totalaudio=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="audio") | .id' | wc -l)
totalsubs=$(echo "$DETAILS" | jq '.tracks[] | select (.type=="subtitles") | .id' | wc -l)

diffaudio=$(expr $totalaudio - $audiocount)
diffsubs=$(expr $totalsubs - $subscount)

echo "3: setting parameters"

if [ -z "$subs" ]
then  
  subs="-S"
else  
  subs="-s $subs"
fi

if [ -z "$audio" ] ; then
  mkvmerge $subs -o "${file%.mkv}".edited.mkv "$file"; #keep Orignal audio
  mv "${file%.mkv}".edited.mkv "$file"
  echo "4: PGS/ASS/VobSub Subtitles found and removed!"
else
  if [ $diffaudio -gt 0 -o $diffsubs -gt 0 ] ; then
    audio="-a $audio";
    mkvmerge $subs $audio -o "${file%.mkv}".edited.mkv "$file";
    mv "${file%.mkv}".edited.mkv "$file"
    echo "4: Unwanted audio or subtitles found and removed!"        
  else
    echo "4: Nothing found to remove. Will exit script now."
  fi          
fi

exit

