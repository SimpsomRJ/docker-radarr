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

###############  PushOver API  #####################################
#APP_TOKEN="YOUR_TOKEN_HERE"
#USER_TOKEN="YOUR_TOKEN_HERE"
####################################################################


fpath="$radarr_moviefile_path"
file=$(basename "$fpath")
ss=$(dirname "$fpath")
cd "$ss"

echo 
echo $file
mkvmerge -I "$file"
audio=$(mkvmerge -I "$file" | fgrep -v TrueHD | sed -ne '/^Track ID [0-9]*: audio .* language:\(por\|eng\|und\).*/ { s/^[^0-9]*\([0-9]*\):.*/\1/;H }; $ { g;s/[^0-9]/,/g;s/^,//;p }')
audiocount=$(echo $audio | tr "," "\n" | wc -l)
echo "1: found $audio ($audiocount) to keep"
    
subs=$(mkvmerge -I "$file" | sed -ne '/^Track ID [0-9]*: subtitles (SubRip\/SRT).* language:\(por\|eng\|und\).*/ { s/^[^0-9]*\([0-9]*\):.*/\1/;H }; $ { g;s/[^0-9]/,/g;s/^,//;p }')
subscount=$(echo $subs | tr "," "\n" | wc -l)
echo "2: found $subs ($subscount) to keep"
        
totalaudio=$(mkvmerge -I "$file" | grep audio | wc -l)
totalsubs=$(mkvmerge -I "$file" | grep subtitles | wc -l)
  
diffaudio=$(expr $totalaudio - $audiocount)
diffsubs=$(expr $totalsubs - $subscount)

echo "3: setting parameters"

if [ -z "$subs" ] ; then
  subs="-S"
else
  subs="-s $subs"
fi
    
if [ -z "$audio" ] ; then
  mkvmerge $subs -o "${file%.mkv}".edited.mkv "$file"; #keep Orignal audio
  mv "${file%.mkv}".edited.mkv "$file"
  echo "7: PGS/ASS/VobSub Subtitles found and removed!"
  # mv "$1" /media/Trash/;
  #if [ $APP_TOKEN != "YOUR_TOKEN_HERE" ] ; then #Don't modify
  #  wget https://api.pushover.net/1/messages.json --post-data="token=$APP_TOKEN&user=$USER_TOKEN&message=$file - Foreign movie processed.&title=RadarrM" -qO- > /dev/null 2>&1 &
  #fi
else
  if [ $diffaudio -gt 0 -o $diffsubs -gt 0 ] ; then
    audio="-a $audio";
    mkvmerge $subs $audio -o "${file%.mkv}".edited.mkv "$file";
    mv "${file%.mkv}".edited.mkv "$file"
    echo "4: Unwanted audio or subtitles found and removed!"		
    # mv "$1" /media/Trash/;
    #if [ $APP_TOKEN != "YOUR_TOKEN_HERE" ] ; then #Don't modify
    #  wget https://api.pushover.net/1/messages.json --post-data="token=$APP_TOKEN&user=$USER_TOKEN&message=$file - Audio or Subtitle removed.&title=RadarrM" -qO- > /dev/null 2>&1 &
    #fi
			
  else
    echo "4: Nothing found to remove. Will exit script now."
    #if [ $APP_TOKEN != "YOUR_TOKEN_HERE" ] ; then #Don't modify
    #  wget https://api.pushover.net/1/messages.json --post-data="token=$APP_TOKEN&user=$USER_TOKEN&message=$file - Nothing found to remove.&title=RadarrM" -qO- > /dev/null 2>&1 &
    #fi
  fi				
fi

