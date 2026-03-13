output "dev_vm_internal_ip" {
  description = "Dev VM internal IP"
  value       = module.dev_vm.internal_ip
}

output "dev_vm_instance_group" {
  description = "Dev VM instance group self link (for LB backend)"
  value       = module.dev_vm.instance_group
}

output "dev_vm_name" {
  description = "Dev VM name"
  value       = module.dev_vm.instance_name
}

output "dev_lb_external_ip" {
  description = "Dev Load Balancer external IP"
  value       = module.dev_lb.external_ip
}
