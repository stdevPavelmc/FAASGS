#!/bin/bash

# lang setting to express the time in 24 hours format {don't touch it}
LANG="C.UTF-8"; export LANG
LC_ALL="C.UTF-8"; export LC_ALL
LC_TIME="C.UTF-8"; export LC_TIME
LANGUAGE="C.UTF-8"; export LANGUAGE
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"
export PATH

# variables
path="/usr/local/bin/sats.sh"
CONFPATH="/etc/sat_data"
OUTPATH="/var/www/html/sat"
RTL_PPM=75.5
USERCONF="${CONFPATH}/user.conf"
source "${USERCONF}"

# proxy setting are defined in the USERCONF variable
export http_proxy
export https_proxy

main () {
	# check for arguments
    if [ "$#" -eq 0 ]; then
		echo "Updating data and scheduling new sats"
		# update sat orbit data
		update_sat_data
		# empty pass.txt
		cat /dev/null > $OUTPATH/passes.txt
		#Schedule Satellite Passes:
		schedule
	else
		# start recording if arg < 0 and pass data
		# $1 = Satellite Name
		# $2 = Frequency
		# $3 = FileName base
		# $4 = TLE File
		# $5 = EPOC start time
		# $6 = Time to capture
		# $7 = File Path
		rec_sat_data "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	fi
}

schedule() {
	# schedule in a cycle for the sats
	/usr/bin/jq -c .satellites[] ${CONFPATH}/sats.json | while read g ; do
		SAT=`echo ${g} | jq .name | tr -d '"'`
		NICK=`echo ${g} | jq .nick | tr -d '"'`
		FREQ=`echo ${g} | jq .freq | tr -d '"'`
		MINELEV=`echo ${g} | jq .minel | tr -d '"'`

		# default min elev
		if [ "$MINELEV" == "null" ] ; then
			MINELEV=20
		fi

		echo "=> $SAT/$NICK"
		set_sat_cycle "$NICK" "$FREQ" "$MINELEV"
	done
}

set_sat_cycle() {
	# $1 - satname (must not contains spaces, () or any other garbage)
	# $2 - freq

	# var expansion to make it mopre legible
	SAT=${1}
	FREQ=${2}
	MINEL=${3}

	# prediction
	PREDICTION=`mktemp`
	/usr/bin/predict -t ${CONFPATH}/data.txt -p ${1} > $PREDICTION

	# cutting upper/lower part of prediction
	LINE_START=`cat $PREDICTION | head -1`
	LINE_END=`cat $PREDICTION | tail -1`

	# extracting start/end unix time (UTT)
	AOSZ=`echo $LINE_START | cut -d " " -f 1`
	LOSZ=`echo $LINE_END | cut -d " " -f 1`
	# human format in UTZ (Z) / Local (L)
	AOSHZ=`echo $LINE_START | cut -d " " -f 3-4`
	AOSHL=`date --date="TZ=\"UTC\" $AOSHZ" +%Y%m%d-%H%M%S`
	AOSHLP=`date -d "$AOSHZ UTC" +"%a %b %d %X %Y"`

	# pass duration
	DURATION=`expr $LOSZ - $AOSZ`

	# extracting max elevation
	MAXELEV=`cat $PREDICTION | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

	# check pass elevation
	if [ ${MAXELEV} -gt ${MINEL} ] ; then
		echo "   ${AOSHLP}, ${MAXELEV}o, ${DURATION}s"

		# create at job
		echo "$path ${SAT} ${FREQ} ${AOSHL} ${AOSZ} ${DURATION} ${MAXELEV}" | at `date --date="TZ=\"UTC\" $AOSHZ" +"%H:%M %D"` 2> /dev/null

		# Put passes to pass file
		echo "${AOSHLP}, ${SAT} (${MAXELEV}), ${FREQ}" >> ${OUTPATH}/passes.txt
	fi
}

rec_sat_data () {
	# $1 = Satellite Name
	# $2 = Frequency
	# $3 = Sat folder base
	# $4 = EPOC start time
	# $5 = Time to capture
	# $6 = Max elev

	# variablle Expansions
	SAT=${1}
	FREQ=${2}
	BASE=${3}
	AOSZ=${4}
	DURATION=${5}
	MAXELEV=${6}

	# check if any RTL soft is working (another reception in progress)
	# in 15 second passes, 4 of them (1 minute)
	count=0
	while true ; do
		t=`ps aux | grep rtl | grep -v grep`
		if [ "$t" == "" -o $count -gt 3 ] ; then
			# no rtl is runnig, going for it
			break
		fi
		# not yet, wait 15 secons more
		echo "Wait 15s for the running RTL process to end..."
		count=`expr $count + 1`
		sleep 15
	done

	# final check
	if [ $count -gt 3 ] ; then
		# can't record, RTL is in use
		echo "Aborting, the RTL device is in use..."
	else
		# RTL is not in use
		echo "RTL-SDR device is not in use, going for it"

		# Working base dir
		WBASE="${OUTPATH}/${BASE}_${SAT}"
		mkdir -p ${WBASE}

		# SAT base file path
		WSATP="${WBASE}/${SAT}"

		# create the details file wuth the pass data
		# needed from the Web UI
		time_now=`date +"%a %b %d %Y %H:%M:%S"`
		# save pass data in NOAA.txt
		echo "${SAT},${FREQ},$time_now,${MAXELEV},${DURATION}s" > ${WBASE}/details.txt

		# bandwidth
		rxbw='25k'
		noaa=`echo ${SAT} | grep NOAA`
		if [ "$noaa" != "" ] ; then
			rxbw='50k'
		fi

		# start recording
		echo "Recording start..."
		if [ "${AUDIO_SBS}" == "yes" -o "${AUDIO_SBS}" == "Yes" ] ; then
			# step by step audio processing, temp files will be on RAM if armbian os
			timeout $5 rtl_fm -p "${RTL_PPM}" -f "${FREQ}M" -s "${rxbw}" \
				-g 44.5 -E wav -E deemp -F 9 - > /tmp/sat.wav
			sox -t wav /tmp/sat.wav ${WSATP}.wav rate 11025
			rm /tmp/sat.wav
		else
			# streamed (piped) capture only on fast/dedicated systems
			timeout $5 rtl_fm -p "${RTL_PPM}" -f "${FREQ}M" -s "${rxbw}" \
				g 44.5 -E deemp -F 9 - | \
				sox -t raw -r "${rxbw}" -e signed -b 16 -c 1 - ${WSATP}.wav rate 11025
		fi

		# will allow to erase the folder by the user?
		if [ "$ALLOW_REMOVE_FOLDER" == "no" -o "$ALLOW_REMOVE_FOLDER" == "No" ]; then
			touch "${OUTPATH}/${BASE}/noerase"
		fi

		# audio process
		echo "Audio processing"
		if [ "${noaa}" = "" ] ; then
			# Voice FM sat
			echo "It's a Audio Satellite"

			# process the audio
			sox ${WSATP}.wav -n spectrogram -o ${WSATP}.png

			# add labels to image
			# first line Pass data
			PASSDETAILS="${SAT}, ${FREQ}MHz, max elev ${MAXELEV}o, ${DURATION}s pass"
			convert -pointsize 20 -fill yellow -draw "text 65,65 '${PASSDETAILS}'" \
				-font /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
				${WSATP}.png ${WSATP}-1.png
			# second line QTH data
			QTH="RX by ${CALL}, ${NAME} in ${LOC}"
			convert -pointsize 20 -fill yellow -draw "text 65,88 '${QTH}'" \
				-font /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
				${WSATP}-1.png ${WSATP}-2.png
			# third Line date stamp
			convert -pointsize 20 -fill yellow -draw "text 65,111 '${time_now}'" \
				-font /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
				${WSATP}-2.png ${WSATP}.png
			rm ${WSATP}-*.png

			# convert it to mp3 as this are audio only, with full quality
			lame -a -b 32 -q 0 --add-id3v2 --ti ${WSATP}.png --silent \
				--ta "${CALL} (${LOC}) automatic Satellite Ground Station" \
				--tt "${SAT} rx at ${FREQ}MHz in ${LOC} by ${CALL}, ${time_now}, max elev ${MAXELEV}, ${DURATION}s pass" \
				--ty 2021 ${WSATP}.wav ${WSATP}.mp3
			rm ${WSATP}.wav
		else
			# NOAA process
			echo "It's a NOAA Satellite"

			# adjust the AOS time for the map slant
			NAOS=`expr ${AOSZ} + 90`

			# map options
			MAP_OPTS=""
			if [ "$APT_MAP_QTH" == "yes" ] ; then
				MAP_OPTS="-l 1 -n \"${LOC_NAME}, ${LOC_COUNTRY}\""
			else
				MAP_OPTS="-l 0"
			fi
			if [ "$APT_CITIES" == "yes" ] ; then
				MAP_OPTS="$MAP_OPTS -p 200000"
			fi
			if [ "$APT_ARTIFACTS" == "yes" ] ; then
				MAP_OPTS="$MAP_OPTS -K 1 -R 1 -C 1 -S 1 -f 1 -F 1"
			else
				MAP_OPTS="$MAP_OPTS -K 0 -R 0 -C 1 -S 0 -f 0 -F 0"
			fi

			# process options
			APT_OPTS=""
			if [ "$APT_AUTOCROP" != "yes" ] ; then
				APT_OPTS="$APT_OPTS -A"
			fi
			if [ "$APT_CROP_TELEMETRY" == "yes" ] ; then
				APT_OPTS="$APT_OPTS -c"
			fi
			if [ "$APT_OVERSAMPLE" == "yes" ] ; then
				APT_OPTS="$APT_OPTS -I"
			fi

			# creating map overlay
			NOAA=`echo ${SAT} | sed s/"1"/" 1"/`
			echo "wxmap -T \"${NOAA}\" -H \"${CONFPATH}/data.txt\" ${MAP_OPTS} -q -o ${NAOS} ${WSATP}-map.png" > /tmp/map.sh
			chmod +x /tmp/map.sh
			bash /tmp/map.sh
			rm /tmp/map.sh

			# creating standard image & tumbnail
			wxtoimg -m ${WSATP}-map.png,${SLANT_X},${SLANT_Y} -t n ${APT_OPTS} -e HVC -K \
				-q ${WSATP}.wav ${WSATP}.${APT_IMAGE_FORMAT}
			convert ${WSATP}.${APT_IMAGE_FORMAT} -resize 40% ${WBASE}/t${SAT}.jpg

			# creating colored image & tumbnail
			wxtoimg -m ${WSATP}-map.png,${SLANT_X},${SLANT_Y} -t n ${APT_OPTS} -e MSA \
				-q ${WSATP}.wav ${WSATP}C.${APT_IMAGE_FORMAT}
			convert ${WSATP}C.${APT_IMAGE_FORMAT} -resize 40% ${WBASE}/t${SAT}C.jpg

			# creating thermal image & tumbnail
			wxtoimg -m ${WSATP}-map.png,${SLANT_X},${SLANT_Y} -t n ${APT_OPTS} -e therm \
				-q ${WSATP}.wav ${WSATP}T.${APT_IMAGE_FORMAT}
			convert ${WSATP}T.${APT_IMAGE_FORMAT} -resize 40% ${WBASE}/t${SAT}T.jpg

			# creating 3d image & tumbnail
			wxtoimg -m ${WSATP}-map.png,${SLANT_X},${SLANT_Y} -t n ${APT_OPTS} -e anaglyph \
				-q ${WSATP}.wav ${WSATP}3D.${APT_IMAGE_FORMAT}
			convert ${WSATP}3D.${APT_IMAGE_FORMAT} -resize 40% ${WBASE}/t${SAT}3D.jpg
		fi

		# copy index to folder
		cp "${CONFPATH}/index.php" "${WBASE}/"
	fi

	# set file perms
	chown 33:33 -R "${WBASE}"
	chmod 0776 -R "${WBASE}"
}

update_sat_data () {
	# erase the dsat rx queue
	for i in `atq | awk '{print $1}'`; do atrm $i; done

	# create the conf dir
	if [ ! -d ${CONFPATH} ] || [ ! -d ${OUTPATH} ] ; then
		mkdir -p ${CONFPATH}
		mkdir -p ${OUTPATH}
	fi

	# TLEs
	# https://www.celestrak.com/NORAD/elements/amateur.txt
	# https://www.celestrak.com/NORAD/elements/active.txt
	# https://www.celestrak.com/NORAD/elements/weather.txt

	# downloading updated sat information
	wget -qr https://www.celestrak.com/NORAD/elements/active.txt -O ${CONFPATH}/data_temp.txt
	res=$?
	if [ $res -eq 0 ] ; then
		echo "Fresh data fetched, updating the good file"
		mv ${CONFPATH}/data_temp.txt ${CONFPATH}/data_good.txt

		echo "Filtering the sats we need and set simple names"
		cat /dev/null > ${CONFPATH}/data.txt
		/usr/bin/jq -c .satellites[] ${CONFPATH}/sats.json | while read g ; do
			SAT=`echo ${g} | jq .name | tr -d '"'`
			NICK=`echo ${g} | jq .nick | tr -d '"'`
			FREQ=`echo ${g} | jq .freq | tr -d '"'`
			MINELEV=`echo ${g} | jq .minel | tr -d '"'`

			cat ${CONFPATH}/data_good.txt | grep "${SAT}" -A2 >> ${CONFPATH}/data.txt
			sed -i s/"${SAT}"/"${NICK}"/ ${CONFPATH}/data.txt
		done
	else
		echo "Can't fetch fresh TLE data, using old one"
	fi
}

main "$@"
