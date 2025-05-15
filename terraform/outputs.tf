output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_a_id" {
  value = module.vpc.public_subnet_a_id
}

output "public_subnet_b_id" {
  value = module.vpc.public_subnet_b_id
}

output "private_subnet_a_id" {
  value = module.vpc.private_subnet_a_id
}

output "wordpress_instance_id" {
  value = module.wordpress_instance_a.instance_id
}

output "wordpress_instance_b_id" {
  value = module.wordpress_instance_b.instance_id
}

output "wordpress_instance_a_public_ip" {
  value = module.wordpress_instance_a.public_ip
}

output "wordpress_instance_b_public_ip" {
  value = module.wordpress_instance_b.public_ip
}

output "mariadb_instance_id" {
  value = module.mariadb_instance.instance_id
}

output "ansible_instance_b_public_ip" {
  value = module.ansible_control_server.public_ip
}
