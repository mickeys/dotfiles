#!/usr/bin/env bash							# search PATH for bash ~ portable
#!/usr/local/bin/bash -x					# super debug mode for bad days :-/
# -----------------------------------------------------------------------------
# Grab the device IDs and write to a local file, to authorise them on the next
# OS build.
# -----------------------------------------------------------------------------

i=1											# canonical loop counter
while true
do
	adb wait-for-device						# wait for an adb device to appear
	devno=$( adb shell getprop ro.serialno )	# grab
	echo "$i ~ $devno"						# reward the human
	echo $devno >> ./devices.txt			# remember the device
	adb shell reboot -p						# shut down device to save battery
	(( i++ ))								# increment counter for happy human
done
