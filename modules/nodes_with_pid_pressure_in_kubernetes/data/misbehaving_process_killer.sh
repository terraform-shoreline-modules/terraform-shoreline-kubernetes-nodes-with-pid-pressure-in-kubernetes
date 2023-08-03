
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