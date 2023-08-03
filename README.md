
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Nodes with PID Pressure in Kubernetes
---

Nodes with PID Pressure in Kubernetes is an incident type that occurs when a Kubernetes cluster node experiences PID pressure, meaning that it may not be able to start more containers. This is a rare condition where a pod or container spawns too many processes and starves the node of available process IDs. Each node has a limited number of process IDs to distribute amongst running processes; and if it runs out of IDs, no other processes can be started. Kubernetes lets you set PID thresholds for pods to limit their ability to perform runaway process-spawning, and a PID pressure condition means that one or more pods are using up their allocated PIDs and need to be examined.

### Parameters
```shell
# Environment Variables
export NODE_NAME="PLACEHOLDER"
export PID="PLACEHOLDER"
export NODE_IP="PLACEHOLDER"
export NODE_USERNAME="PLACEHOLDER"
export NEW_PID_THRESHOLD="PLACEHOLDER"

```

## Debug

### Get the list of nodes that have PID pressure
```shell
kubectl get node --selector=kubernetes.io/pid-pressure=true
```

### Get the list of pods that are using too many PIDs
```shell
kubectl top pods --all-namespaces | sort --reverse --key 3 | head
```

### Get the list of containers running on a node
```shell
kubectl describe node ${NODE_NAME}
```

### Get the PID usage of a process
```shell
ssh $NODE_USERNAME@$NODE_IP 
ps -o pid,ppid,%cpu,%mem,cmd ax | grep ${PID}
```

### Get the number of PIDs in use by a process
```shell
ssh $NODE_USERNAME@$NODE_IP 
cat /proc/${PID}/status | grep "Pid"
```

### Get the maximum number of PIDs available to a process
```shell
ssh $NODE_USERNAME@$NODE_IP 
cat /proc/sys/kernel/pid_max
```


## Repair
---

### Check if there are any misbehaving or stuck processes in the node and kill them to free up PIDs.
```shell

#!/bin/bash

# Set the node name
NODE=${NODE_NAME}

# Get the PID of the misbehaving process, if any
PID=$(ssh ${NODE_USERNAME}@${NODE_IP} "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $1}'")

# Check if a PID was returned
if [[ -n "$PID" ]]; then
  echo "Misbehaving process found with PID $PID."

  # Kill the process
  ssh ${NODE_USERNAME}@${NODE_IP} "kill $PID"

  # Check if the process was successfully killed
  if [[ $? -eq 0 ]]; then
    echo "Process with PID $PID has been killed successfully."
  else
    echo "Failed to kill process with PID $PID."
  fi
else
  echo "No misbehaving processes found."
fi

```

### Monitor the Kubernetes cluster carefully and identify which pods are using up the most PIDs. Once identified, adjust the PID thresholds for those pods to limit their ability to perform runaway process-spawning.
```shell

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

```