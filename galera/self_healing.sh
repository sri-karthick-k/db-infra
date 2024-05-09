mapfile -t ip_array < hosts.txt

ip_array_length=${#ip_array[@]}
inactive_nodes=()

# get the count of failed nodes
for oneIp in "${ip_array[@]}"; do
	result=$(ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo systemctl is-active mysqld.service")
    if [[ $result == "failed" || $result == "inactive" || $result == "activating" ]]; then
		inactive_nodes+=($oneIp)
    fi
	echo $oneIp - $result
done

# if all the nodes are failed
if [ $ip_array_length == ${#inactive_nodes[@]} ]; then
	for oneIp in "${ip_array[@]}"; do
		result=$(ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo cat /var/lib/mysql/grastate.dat | grep 'safe_to_bootstrap' | awk '{print \$2}'")
		if [ $result == 1 ]; then
			initialHealing="$oneIp"
		fi
	done

	# recover from the node that has the highest galera cluster sequence number
	ssh -q -o StrictHostKeyChecking=no ubuntu@"$initialHealing" "sudo galera_new_cluster"

fi

# recover only failed nodes
for oneIp in "${inactive_nodes[@]}"; do
	ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo systemctl start mysqld.service"
done
