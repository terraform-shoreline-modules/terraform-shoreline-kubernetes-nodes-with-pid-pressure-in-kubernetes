ssh $NODE_USERNAME@$NODE_IP 
cat /proc/${PID}/status | grep "Pid"