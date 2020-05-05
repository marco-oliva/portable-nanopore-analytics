####Monitor
#Output format:
#Time    native_heap    stack    temperature
pid=$(pgrep $1) 
start=$(date +%s)
echo "pid: $pid"
echo "Time\tNative\tHeap\tStack\tTemperature"
#while the monitored process is running
while  [ pid -ne "" -a -e /proc/$pid ]
do
	#Time from start
	now=$(date +%s)
	elapsed=$((now-start))

	##Memory usage
	out=$(dumpsys meminfo $pid | egrep '(Native|Stack)' | tail -n 2 | tr -d [:alpha:][:punct:][:blank:] | tr '\n' ' ')
	native_heap=$(echo $out | cut -d ' ' -f1)
	stack=$(echo $out | cut -d ' ' -f2)

	##CPU temp
    cpu_temp=$(dumpsys 2>/dev/null  | grep "CPU temperatures:" | awk '{print $3}' | tr -d "[,") 
	##Print
	echo "$elapsed\t$native_heap\t\t$stack\t$cpu_temp"

	sleep 2
done
