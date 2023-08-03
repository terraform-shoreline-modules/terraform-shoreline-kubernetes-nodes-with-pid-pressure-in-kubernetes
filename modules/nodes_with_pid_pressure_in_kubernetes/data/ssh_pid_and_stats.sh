ssh $NODE_USERNAME@$NODE_IP 
ps -o pid,ppid,%cpu,%mem,cmd ax | grep ${PID}