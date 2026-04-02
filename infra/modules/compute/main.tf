# infra/modules/compute/main.tf

# ---------------------------------------------------------
# SECURITY GROUPS (Firewalls)
# ---------------------------------------------------------

# 1. Load Balancer Security Group (Accepts HTTP from anywhere)
resource "aws_security_group" "alb_sg" {
  name        = "enterprise-alb-sg"
  description = "Allow inbound HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Bastion Host Security Group (Accepts SSH from anywhere - we'll lock this down later)
resource "aws_security_group" "bastion_sg" {
  name        = "enterprise-bastion-sg"
  description = "Allow SSH to Bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For testing, we allow SSH from anywhere. 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. App Server Security Group (Strictly Internal)
resource "aws_security_group" "app_sg" {
  name        = "enterprise-app-sg"
  description = "Allow HTTP from ALB and SSH from Bastion"
  vpc_id      = var.vpc_id

  # Accept web traffic ONLY from the Load Balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
  }

  # Accept SSH connections ONLY from the Bastion Host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------
# COMPUTE RESOURCES (Servers & ALB)
# ---------------------------------------------------------

# 1. Fetch the latest Amazon Linux 2023 Machine Image (AMI)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. SSH Key Pair (Grabs the public key from your Arch Linux machine)
resource "aws_key_pair" "deployer" {
  key_name   = "enterprise-deployer-key"
  # Check your terminal: this path might need to be ~/.ssh/id_rsa.pub depending on how you generated it
  public_key = file("~/.ssh/id_ed25519.pub") 
}

# 3. The Bastion Host (Your secure jump-server in the Public Subnet)
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "enterprise-bastion-host"
  }
}

# 4. The App Server (Hidden in the Private Subnet, runs your website)
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  # This script runs automatically the exact second the server boots
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>SUCCESS: AWS Enterprise Ephemeral Architecture</h1><p>Routing via ALB to Private Subnet</p>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "enterprise-app-server"
  }
}

# 5. The Application Load Balancer (ALB)
resource "aws_lb" "web_alb" {
  name               = "enterprise-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.public_subnet_id, var.public_subnet_2_id] # Requires two zones!
}

# 6. ALB Target Group (Where the ALB sends the traffic)
resource "aws_lb_target_group" "app_tg" {
  name     = "enterprise-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# 7. Attach the App Server to the Target Group
resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}

# 8. ALB Listener (Listens on port 80 and forwards to the Target Group)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
