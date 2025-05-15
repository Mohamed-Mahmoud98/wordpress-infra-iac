
provider "aws" {
  alias  = "virginia"
  region = var.region_virginia
  access_key = ""
  secret_key = ""
  token = ""
}


# VPC Module
module "vpc" {

  providers = {
    aws = aws.virginia
  }
  source                = "./modules/vpc"
  vpc_cidr              = "10.0.0.0/16"
  vpc_name              = "main_vpc_virginia"
  public_subnet_a_cidr  = "10.0.1.0/24"
  public_subnet_b_cidr  = "10.0.3.0/24"
  private_subnet_a_cidr = "10.0.2.0/24"
  az_a                  = "us-east-1a"
  az_b                  = "us-east-1b"
}

# Gateways Module
module "gateways" {

  providers = {
    aws = aws.virginia
  }
  source             = "./modules/gateways"
  vpc_id             = module.vpc.vpc_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  name_prefix        = "main"
}

# Security Groups
module "wordpress_sg_virginia" {
  providers = {
    aws = aws.virginia
  }
  source      = "./modules/security_group"
  name        = "wordpress_sg_virginia"
  description = "Allow HTTP/HTTPS and SSH to WordPress instances"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${module.ansible_control_server.private_ip}/32"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "wordpress-sg"
  }
}

module "ansible_sg_virginia" {
  providers = {
    aws = aws.virginia
  }
  source      = "./modules/security_group"
  name        = "ansible_sg_virginia"
  description = "Allow SSH to all instances"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "ansible-sg"
  }
}

module "mariadb_sg_virginia" {
  providers = {
    aws = aws.virginia
  }
  source      = "./modules/security_group"
  name        = "mariadb_sg_virginia"
  description = "Allow MariaDB connections from WordPress"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${module.ansible_control_server.private_ip}/32"]
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["${module.wordpress_instance_a.private_ip}/32", "${module.wordpress_instance_b.private_ip}/32"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "mariadb-sg"
  }
}

# EC2 Instances
module "wordpress_instance_a" {
  providers = {
    aws = aws.virginia
  }
  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.public_subnet_a_id
  security_group_ids         = [module.wordpress_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "wordpress_instance_a AZ 1"
    user_data = <<-EOF
              #!/bin/bash
              # Update and install Apache
              apt update -y
              apt install -y apache2

              # Enable and start Apache
              systemctl enable apache2
              systemctl start apache2

              # Get the private IP address of the instance
              PRIVATE_IP=$(hostname -I | awk '{print $1}')

              # Create an index.html with the IP address
              echo "<html><body><h1>Instance IP: $PRIVATE_IP</h1></body></html>" > /var/www/html/index.html
            EOF

}

module "wordpress_instance_b" {
  providers = {
    aws = aws.virginia
  }
  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.public_subnet_b_id
  security_group_ids         = [module.wordpress_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "wordpress_instance_a AZ 2"
  user_data = <<-EOF
              #!/bin/bash
              # Update and install Apache
              apt update -y
              apt install -y apache2

              # Enable and start Apache
              systemctl enable apache2
              systemctl start apache2

              # Get the private IP address of the instance
              PRIVATE_IP=$(hostname -I | awk '{print $1}')

              # Create an index.html with the IP address
              echo "<html><body><h1>Instance IP: $PRIVATE_IP</h1></body></html>" > /var/www/html/index.html
            EOF

}

module "ansible_control_server" {
  providers = {
    aws = aws.virginia
  }
  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.public_subnet_a_id
  security_group_ids         = [module.ansible_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "ansible_controlServer"
    # Add user_data to install Ansible
  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo apt update -y
              sudo apt upgrade -y
              
              # Install dependencies for Ansible
              sudo apt install -y python3 python3-pip git

              # Install Ansible using pip
              sudo pip3 install ansible -y
              sudo apt install ansible-core -y

              # Verify Ansible installation (log to file for debugging)
              ansible --version >> /var/log/ansible_version.log
            EOF

}

module "mariadb_instance" {
  providers = {
    aws = aws.virginia
  }
  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.private_subnet_a_id
  security_group_ids         = [module.mariadb_sg_virginia.security_group_id]
  associate_public_ip_address = false
  name                       = "mariadb_instance"

  user_data = ""
}



module "alb_sg_virginia" {
  providers = {
    aws = aws.virginia
  }
  source      = "./modules/security_group"
  name        = "alb_sg_virginia"
  description = "Allow HTTP access to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "alb_sg_virginia"
  }
}

# ALB Module
module "alb_virginia" {
  providers = {
    aws = aws.virginia
  }
  source = "./modules/alb"
  name                        = "app-lb-virginia"
  internal                    = false
  load_balancer_type          = "application"
  security_group_ids          = [module.alb_sg_virginia.security_group_id]
  subnet_ids                  = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]
  enable_deletion_protection = false
  tags                        = {
    Name = "AppLBVirginia"
  }
  vpc_id             = module.vpc.vpc_id
  target_group_name  = "app-tg-virginia"
  target_group_port  = 80
  target_group_protocol = "HTTP"
  instance_id_map = {
    "wordpress-a" = module.wordpress_instance_a.instance_id
    "wordpress-b" = module.wordpress_instance_b.instance_id
  }
}





