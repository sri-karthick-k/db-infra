mapfile -t ip_array < hosts.txt

for oneIp in "${ip_array[@]}"; do
	result=$(ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo cat /var/lib/mysql/grastate.dat | grep 'safe_to_bootstrap' | awk '{print \$2}'")
    if [ $result == 1 ]; then
	initialHealing="$oneIp"
    fi
done

# recover
ssh -q -o StrictHostKeyChecking=no ubuntu@"$initialHealing" "sudo galera_new_cluster"
for oneIp in "${ip_array[@]}"; do
	if [ $oneIp != $initialHealing ]; then
		ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo systemctl start mysqld.service"
	fi
done