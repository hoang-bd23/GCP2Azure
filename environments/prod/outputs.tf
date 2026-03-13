output "prod_vm_internal_ip" {
  description = "Prod VM internal IP"
  value       = module.prod_vm.internal_ip
}

output "prod_vm_instance_group" {
  description = "Prod VM instance group self link (for LB backend)"
  value       = module.prod_vm.instance_group
}

output "prod_vm_name" {
  description = "Prod VM name"
  value       = module.prod_vm.instance_name
}

output "prod_lb_external_ip" {
  description = "Prod Load Balancer external IP"
  value       = module.prod_lb.external_ip
}
