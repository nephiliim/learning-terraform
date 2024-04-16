data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filer.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filer.owner] 
}


module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.Environment.name
  cidr = "${var.environment.network_prefix}var.environment.network_prefix}0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.Environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

enable_nat_gateway
  
  tags = {
    Terraform = "true"
    Environment = var.Environment.name
  }
}



module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.4.1"
  # insert the 1 required variable here

  name = "${var.environment.name}-blog"
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns   = module.blog_alb.target_group_arns
  security_groups     = [module.Blog_sg.security_group_id]
  image_id            = data.aws_ami.app_ami.id
  instance_type       = var.instance_type


}


module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.environment.name}-blog-alb"
  vpc_id  = "module.blog_vpc.vpc_id"
  subnets =  module.blog_vpc.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = var.environment.network_prefix
      to_port     = var.environment.network_prefix}
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "var.environment.network_prefix"
    }

    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = var.environment.network_prefix}"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "var.environment.network_prefix}/16"
    }
  }


  listeners = {
    ex-http-https-redirect = {
      port     = var.environment.network_prefix}
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_var.environment.network_prefix}1"
      }
    
    }
  }

  tags = {
    Environment = var.environment.name
  }
}

module "Blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  name = "${var.environment.name}-blog"
 
  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-var.Environment.network_prefix}-tcp","https-443-tcp"]
  ingress_cidr_blocks = [var.environment.network_prefix}"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = [var.environment.network_prefix}"]
}



