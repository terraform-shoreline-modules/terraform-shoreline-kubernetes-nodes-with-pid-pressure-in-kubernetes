resource "shoreline_notebook" "nodes_with_pid_pressure_in_kubernetes" {
  name       = "nodes_with_pid_pressure_in_kubernetes"
  data       = file("${path.module}/data/nodes_with_pid_pressure_in_kubernetes.json")
  depends_on = [shoreline_action.invoke_ssh_pid_and_stats,shoreline_action.invoke_ssh_cat_proc_pid_status,shoreline_action.invoke_ssh_cat_proc_sys_kernel_pid_max,shoreline_action.invoke_misbehaving_process_killer,shoreline_action.invoke_calculate_pids]
}

resource "shoreline_file" "ssh_pid_and_stats" {
  name             = "ssh_pid_and_stats"
  input_file       = "${path.module}/data/ssh_pid_and_stats.sh"
  md5              = filemd5("${path.module}/data/ssh_pid_and_stats.sh")
  description      = "Get the PID usage of a process"
  destination_path = "/agent/scripts/ssh_pid_and_stats.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "ssh_cat_proc_pid_status" {
  name             = "ssh_cat_proc_pid_status"
  input_file       = "${path.module}/data/ssh_cat_proc_pid_status.sh"
  md5              = filemd5("${path.module}/data/ssh_cat_proc_pid_status.sh")
  description      = "Get the number of PIDs in use by a process"
  destination_path = "/agent/scripts/ssh_cat_proc_pid_status.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "ssh_cat_proc_sys_kernel_pid_max" {
  name             = "ssh_cat_proc_sys_kernel_pid_max"
  input_file       = "${path.module}/data/ssh_cat_proc_sys_kernel_pid_max.sh"
  md5              = filemd5("${path.module}/data/ssh_cat_proc_sys_kernel_pid_max.sh")
  description      = "Get the maximum number of PIDs available to a process"
  destination_path = "/agent/scripts/ssh_cat_proc_sys_kernel_pid_max.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "misbehaving_process_killer" {
  name             = "misbehaving_process_killer"
  input_file       = "${path.module}/data/misbehaving_process_killer.sh"
  md5              = filemd5("${path.module}/data/misbehaving_process_killer.sh")
  description      = "Check if there are any misbehaving or stuck processes in the node and kill them to free up PIDs."
  destination_path = "/agent/scripts/misbehaving_process_killer.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "calculate_pids" {
  name             = "calculate_pids"
  input_file       = "${path.module}/data/calculate_pids.sh"
  md5              = filemd5("${path.module}/data/calculate_pids.sh")
  description      = "Monitor the Kubernetes cluster carefully and identify which pods are using up the most PIDs. Once identified, adjust the PID thresholds for those pods to limit their ability to perform runaway process-spawning."
  destination_path = "/agent/scripts/calculate_pids.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_ssh_pid_and_stats" {
  name        = "invoke_ssh_pid_and_stats"
  description = "Get the PID usage of a process"
  command     = "`chmod +x /agent/scripts/ssh_pid_and_stats.sh && /agent/scripts/ssh_pid_and_stats.sh`"
  params      = ["PID","NODE_USERNAME","NODE_IP"]
  file_deps   = ["ssh_pid_and_stats"]
  enabled     = true
  depends_on  = [shoreline_file.ssh_pid_and_stats]
}

resource "shoreline_action" "invoke_ssh_cat_proc_pid_status" {
  name        = "invoke_ssh_cat_proc_pid_status"
  description = "Get the number of PIDs in use by a process"
  command     = "`chmod +x /agent/scripts/ssh_cat_proc_pid_status.sh && /agent/scripts/ssh_cat_proc_pid_status.sh`"
  params      = ["PID","NODE_USERNAME","NODE_IP"]
  file_deps   = ["ssh_cat_proc_pid_status"]
  enabled     = true
  depends_on  = [shoreline_file.ssh_cat_proc_pid_status]
}

resource "shoreline_action" "invoke_ssh_cat_proc_sys_kernel_pid_max" {
  name        = "invoke_ssh_cat_proc_sys_kernel_pid_max"
  description = "Get the maximum number of PIDs available to a process"
  command     = "`chmod +x /agent/scripts/ssh_cat_proc_sys_kernel_pid_max.sh && /agent/scripts/ssh_cat_proc_sys_kernel_pid_max.sh`"
  params      = ["NODE_USERNAME","NODE_IP"]
  file_deps   = ["ssh_cat_proc_sys_kernel_pid_max"]
  enabled     = true
  depends_on  = [shoreline_file.ssh_cat_proc_sys_kernel_pid_max]
}

resource "shoreline_action" "invoke_misbehaving_process_killer" {
  name        = "invoke_misbehaving_process_killer"
  description = "Check if there are any misbehaving or stuck processes in the node and kill them to free up PIDs."
  command     = "`chmod +x /agent/scripts/misbehaving_process_killer.sh && /agent/scripts/misbehaving_process_killer.sh`"
  params      = ["PID","NODE_NAME","NODE_USERNAME","NODE_IP"]
  file_deps   = ["misbehaving_process_killer"]
  enabled     = true
  depends_on  = [shoreline_file.misbehaving_process_killer]
}

resource "shoreline_action" "invoke_calculate_pids" {
  name        = "invoke_calculate_pids"
  description = "Monitor the Kubernetes cluster carefully and identify which pods are using up the most PIDs. Once identified, adjust the PID thresholds for those pods to limit their ability to perform runaway process-spawning."
  command     = "`chmod +x /agent/scripts/calculate_pids.sh && /agent/scripts/calculate_pids.sh`"
  params      = ["NEW_PID_THRESHOLD"]
  file_deps   = ["calculate_pids"]
  enabled     = true
  depends_on  = [shoreline_file.calculate_pids]
}

