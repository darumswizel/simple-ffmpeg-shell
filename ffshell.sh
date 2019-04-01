#!/usr/bin/env bash
#Does accept multiple inputs but they are run sequentially
#total streams
streamArr=()

videoArr=()
videoMetaArr=()
videoTypeArr=()
videoChoice=0 #user input video stream choice

audioArr=()
audioMetaArr=()
audioTypeArr=()
audioChoice=0 #user input subtitle stream choice

subtitleArr=()	
subtitleTypeArr=()
subtitleMetaArr=()
subtitleChoice=0 #user input subtitle stream choice

ffprobeOut=() #ffprobe output array. each element is the next line
verboseFl=0 #full ffprobe output

inputSize=0 #number of ffprobe output lines 

#$1: User Input 
#$2: Number of Streams
inRangeCode=0
in_range () {
	compare=$(($2-1))
	#echo "$1 and $compare"
	if (( $1 > $compare )) || (( $1 < -1)); then
		#echo "nah man"
		inRangeCode=-1
	elif (( $1 == -1)); then
		inRangeCode=-1
	else
		#echo "ayy there it is"
		inRangeCode=$1
	fi
}

#$1: index number
#$2: total number of lines
#$3: type
meta_check () {
	total=$(($2-1))
	index=$(($1+1))
	sType=$3
	entry="null"
	if (( $index >= $total )); then
		echo "no available meta"
	else
		#echo "${ffprobeOut[$index]}"	
		if [[ ${ffprobeOut[$index]} =~ (.*)(M|m)"etadata"(.*) ]]; then
			index=$((index+1))
			if [[ ${ffprobeOut[$index]} =~ (.*)(T|t)"itle"(.*) ]]; then
				entry="${ffprobeOut[$index]}"
				#echo "$entry"
			fi
		fi
	fi
	if [[ $sType == "audio" ]]; then
		#echo "$entry -$sType-"
		audioMetaArr+=("$entry")
	elif [[ $sType == "subtitle" ]]; then
		#echo "$entry -$sType-"
		subtitleMetaArr+=("$entry")
	else [[ $sType == "video" ]]
		#echo "$entry -$sType-"
		videoMetaArr+=("$entry")
	fi
}

if [ 1 -eq 0 ]; then
#$1: Type of Stream
#$2: User Input
sLen=0
stream_check () {
	sType=$1
	if [[ sType == "audio" ]]; then
		sLen=${audioArr[@]}
	elif [[ sType == "subtitle" ]]; then
		sLen=${subtitleArr[@]}	
	else [[ sType == "video" ]]
		sLen=${videoArr[@]}
	fi
	echo -e "\n--${sLen[0]}--\n"
	if (( $sLen == 0 )); then
		echo "No Video Tracks"
		videoChoice=-1
	elif (( $sLen == 1 )); then
		#echo "One Video"
		videoChoice=0
		#echo "${videoArr[videoChoice]}"
	else
		count=0
		echo -e "\n\t-Video Streams-"
		for i in "${videoArr[@]}"; do
			firstChunk=${i%%,*}
			mainContent=${firstChunk##*:\ }
			#echo "$firstChunk"
			echo "$count) | $firstChunk"
			type=${mainContent##*:}
			type=${type#\ }
			type=${type%%\ *}
			echo "$type"
			videoTypeArr+=("$type")
			count=$((count+1))
		done
		echo "Type the number corresponding to the video stream you want to use, followed by [ENTER]:"
		read videoChoice
		in_range $videoChoice ${#videoArr[@]} 
		echo "$inRangeCode"
		videoChoice=inRangeCode
	fi
}
fi

#set flags for input
for i in "$@"; do
	if [[ $i == "-v" ]]; then
		verboseFl=1
	fi
done
#loop through command line arguments
for i in "$@"; do
	#currently only check if extra arguments are files
	if [[ -e $i && $i != "-v" ]]; then 
		streamArr=()
		videoArr=()
		videoMetaArr=()
		videoTypeArr=()
		audioArr=()
		audioMetaArr=()
		audioTypeArr=()
		subtitleArr=()	
		subtitleTypeArr=()
		subtitleMetaArr=()
		base=${i##*/}
		temp=${base%.*}
		dir=${i%$base}
		for i in ls "$dir"*; do
			subExt=${i##*.}
			#echo "$subExt"
			if [[ $subExt =~ (srt|ass) ]]; then
				subtitleArr+=("$i")
				subtitleTypeArr+=($subExt)
			fi
		done
		#will likely be changing containers
		base="$temp"
		ext=${i##*.}
		echo -e "\nbase: $base dir: $dir ext: $ext"
		#get file information, redirect sterr
		info="$(ffprobe -i "$i" -hide_banner 2>&1)"
		if (( verboseFl == 1 )); then
			for i in "$info"; do
				echo "$i"
			done
		fi
		#echo -e "\n${#info[@]}"
		IFS='\n' read -ra ADDR <<< "$info"
		ffprobeOut=()
		ffprobeOutSize=${#ffprobeOut[@]}
		#read each line of ffprobe output
		#for line in "${ffprobeOut[@]}"; do
		while read -r line; do
			ffprobeOut+=("$line")
		done <<< "$info"
		outLen=${#ffprobeOut[@]}
		for ((i = 0; i < $outLen; i++)); do
			#echo "... ${ffprobeOut[i]} ..."
			#echo "...$i..."
			#i=$((i-1))
			line=${ffprobeOut[i]}

			if [[ $line =~ (S|s)"tream"(.*) ]]; then
				#echo "$line"	
				streamArr+=("$line")
				if [[ $line =~ (.*)(V|v)"ideo"(.*) ]]; then
					videoArr+=("$line")
					meta_check $i $outLen "video"
					#this is causing issues if no metadata is available
					#Possibly skips next stream
				elif [[ $line =~ (.*)(A|a)"udio"(.*) ]]; then
				       	audioArr+=("$line")
					meta_check $i $outLen "audio"
				elif [[ $line =~ (.*)(: )(S|s)"ubtitle"(.*) ]]; then
					subtitleArr+=("$line")
					meta_check $i $outLen "subtitle"
				else
					echo "$line"
					echo "Unidentified Stream"
				fi	

			fi
		done
		#print out all streams

		echo -e "\n\t--- Streams ---"
		echo "Number of video streams: ${#videoArr[@]} | Number of audio streams: ${#audioArr[@]} | Number of subtitle streams: ${#subtitleArr[@]}"
		#yooo=0
		#echo -e "\n${ffprobeOut[yooo]}"
		#echo -e "\n\n---------------------------------"
		#echo "number of stream pieces: $temp"
		#for i in ${streamArr[@]}; do
			#
		#done
		videoChoice=0
		if (( ${#videoArr[@]} == 0 )); then
			echo "No Video Tracks"
			videoChoice=-1
		elif (( ${#videoArr[@]} == 1 )); then
			#echo "Default to Single Video Stream"
			videoChoice=0
			#echo "${videoArr[videoChoice]}"
		else
			count=0
			echo -e "\n\t-Video Streams-"
			count=0
			echo -e "\n\t-Video Streams-"
			#for i in "${videoArr[@]}"; do
			for ((in = 0; in < ${#videoArr[@]}; in++)); do
				i=${videoArr[in]}
				met=${videoMetaArr[0]}
				firstChunk=${i%%,*}
				mainContent=${firstChunk##*:\ }
				#echo "$firstChunk"
				echo "$count) | $firstChunk"
				mainMetaContent=${met#*:\ }
				if [[ $met == "null" ]]; then
					mainMetaContent=""
				fi
				echo -e "$mainMetaContent\n"
				type=${mainContent##*:}
				type=${mainContent##*:}
				type=${type#\ }
				type=${type%%\ *}
				#echo "$type"
				videoTypeArr+=("$type")
				count=$((count+1))
			done
			echo "Type the number corresponding to the video stream you want to use, followed by [ENTER]:"
			read videoChoice
			in_range $videoChoice ${#videoArr[@]} 
			echo "$inRangeCode"
			videoChoice=$inRangeCode
		fi
		audioChoice=0
		if (( ${#audioArr[@]} == 0 )); then
			echo "No Audio Stream"
			audioChoice=-1
		else
			count=0
			echo -e "\n\t-Audio Streams-"
			#for i in $(seq 1 ${#audioArr[@]}); do
			#	echo $i
			#done
			for ((in = 0; in < ${#audioArr[@]}; in++)); do
				i=${audioArr[in]}
				met=${audioMetaArr[in]}
			#for i in "${audioArr[@]}"; do
				firstChunk=${i%%,*}
				mainContent=${firstChunk##*:\ }
				#echo "$firstChunk"
				echo "$count) | $firstChunk"
				mainMetaContent=${met#*:\ }
				if [[ $met == "null" ]]; then
					mainMetaContent=""
				fi
				echo -e "$mainMetaContent\n"
				type=${mainContent##*:}
				type=${type#\ }
				type=${type%%\ *}
				#echo "$type"
				audioTypeArr+=("$type")
				count=$((count+1))
			#done			
			done
			
			echo "Type the number corresponding to the audio stream you want to use (-1 for no audio), followed by [ENTER]:"
			read audioChoice
			in_range $audioChoice ${#audioArr[@]} 
			#echo "$inRangeCode"
			#echo "$audioChoice"
			audioChoice=$inRangeCode
		fi
		subtitleChoice=0
		if (( ${#subtitleArr[@]} == 0 )); then
			echo "No Subtitle Streams"
			subtitleChoice=-1
			#echo "$subtitleChoice"
		else
			count=0
			echo -e "\n\t-Subtitle Streams-"
			#for i in "${subtitleArr[@]}"; do
			for ((in = 0; in < ${#subtitleArr[@]}; in++)); do
				i=${subtitleArr[in]}
				met=${subtitleMetaArr[in]}
				firstChunk=${i%%,*}
				mainContent=${firstChunk##*:\ }
				#echo "$firstChunk"
				echo "$count) | $firstChunk"
				mainMetaContent=${met#*:\ }
				if [[ $met == "null" ]]; then
					mainMetaContent=""
				fi
				echo -e "$mainMetaContent\n"
				type=${mainContent##*:}
				type=${mainContent##*:}
				type=${type#\ }
				type=${type%%\ *}
				#echo "$type"
				subtitleTypeArr+=("$type")
				count=$((count+1))
			done
			echo "Type the number corresponding to the subtitle stream you want to use (-1 for no subtitles), followed by [ENTER]:"
			read subtitleChoice
			in_range $subtitleChoice ${#subtitleArr[@]} 
			subtitleChoice=$inRangeCode
		fi
		if (( $subtitleChoice == -1 )); then
			echo "$subtitleChoice"
		fi
	#Skip argument if it isnt a file
	else
		if [[ $i != "-v" ]]; then
			echo "$i is not a file"
		fi
	fi
	echo -e "\n=========="
	echo -e "\nVideo Choice: $videoChoice Audio Choice: $audioChoice Subtitle Choice: $subtitleChoice"
done
