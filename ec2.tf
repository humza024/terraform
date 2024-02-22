resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "key_name" {}
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

resource "aws_launch_template" "terraform_instance" {
  instance_type          = "t2.micro"
  image_id               = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.terraform_security_group.id]
  user_data              = filebase64("${path.module}/ecs.sh")
  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  tags = {
    Name = "Terraform-Instance"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

}
resource "aws_autoscaling_group" "terraform_ecs_asg" {
  vpc_zone_identifier = [aws_subnet.terraform_public_subnet.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  launch_template {
    id      = aws_launch_template.terraform_instance.id
    version = "$Latest"
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}
