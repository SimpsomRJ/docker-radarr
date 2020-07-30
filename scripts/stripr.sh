#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>> /config/logs/striplog.txt 2>&1
####################################################################
# Credits for the code.                                            #
#  https://github.com/theskyisthelimit/ubtuntumkvtoolnix           #
#                                                                  #
# I've just made some tweaks.                                      #
####################################################################

fpath="$radarr_moviefile_path"
file=$(basename "$fpath")
ss=$(dirname "$fpath")
cd "$ss"

echo 
echo $file
DETAILS=$(mkvmerge -I "$file")

audio=$(echo "$DETAILS" | grep -P '^Track ID [0-9]*: audio \((?!TrueHD).* language:(por|eng|und).*' | sed -ne '{ s/^[^0-9]*\([0-9]*\):.*/\1/;H }; $ { g;s/[^0-9]/,/g;s/^,//;p }')
audiocount=$(echo $audio | tr "," "\n" | wc -l)
echo "1: found $audio ($audiocount) to keep"
    
subs=$(echo "$DETAILS" | sed -ne '/^Track ID [0-9]*: subtitles (SubRip\/SRT).* language:\(por\|eng\|und\).*/ { s/^[^0-9]*\([0-9]*\):.*/\1/;H }; $ { g;s/[^0-9]/,/g;s/^,//;p }')
subscount=$(echo $subs | tr "," "\n" | wc -l)
echo "2: found $subs ($subscount) to keep"
        
totalaudio=$(echo "$DETAILS" | grep audio | wc -l)
totalsubs=$(echo "$DETAILS" | grep subtitles | wc -l)
  
diffaudio=$(expr $totalaudio - $audiocount)
diffsubs=$(expr $totalsubs - $subscount)

if [ -z "$audio" ] && [ -z "$subs" ] ; then
  echo "3: Nothing found to remove. Will exit script now."
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
  echo "5: Unwanted audio or subtitles found and removed!"		
fi

exit

