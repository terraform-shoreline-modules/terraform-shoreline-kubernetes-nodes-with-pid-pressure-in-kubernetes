
#!/bin/bash

# Get the list of pods running in the cluster
pods=$(kubectl get pods -o=name)

# Loop through each pod to calculate the number of PIDs it is using
for pod in $pods; do
  container_id=$(kubectl get $pod -o=jsonpath='{.status.containerStatuses[0].containerID}' | cut -d/ -f3)
  pid_count=$(docker exec $container_id ps -eLf | wc -l)
  echo "Pod $pod is using $pid_count PIDs"
done

# Identify the pods using up the most PIDs
most_pids_pod=$(kubectl get pods -o=jsonpath='{range .items[*]}{.metadata.name} {.status.containerStatuses[*].containerID} {.spec.containers[*].name} {.status.containerStatuses[*].state.running.startedAt} {print "\n"}{end}' | sort -nrk 2 | head -n 1 | awk '{print $1}')

# Adjust the PID thresholds for the most PIDs pod
kubectl patch pod $most_pids_pod -p '{"spec":{"securityContext":{"sysctls":[{"name":"kernel.pid_max","value":"${NEW_PID_THRESHOLD}"}]}}}}'