mapfile -t ip_array < hosts.txt

for oneIp in "${ip_array[@]}"; do
    ssh -q -o StrictHostKeyChecking=no ubuntu@"$oneIp" "sudo cat /var/lib/mysql/grastate.dat | grep 'safe_to_bootstrap' | awk '{print \$2}'"
done
