# infra/modules/database/main.tf

# ---------------------------------------------------------
# POSTGRESQL (Relational Database)
# ---------------------------------------------------------

# 1. Security Group for Postgres (Only allows traffic on port 5432)
resource "aws_security_group" "postgres_sg" {
  name        = "enterprise-postgres-sg"
  description = "Allow internal database traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Only allows traffic from inside our VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. DB Subnet Group (Tells RDS which subnets it is allowed to use)
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "enterprise-db-subnet-group"
  subnet_ids = [var.private_subnet_id, var.private_subnet_2_id]
}

# 3. The Actual RDS Instance
resource "aws_db_instance" "postgres" {
  identifier             = "enterprise-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro" # Smallest, cheapest instance type
  allocated_storage      = 20
  username               = "dbadmin"
  password               = "SuperSecretPassword123!" # Fine for our 20-minute test
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  
  # CRITICAL FOR EPHEMERAL ENVIRONMENTS:
  skip_final_snapshot    = true # Prevents Terraform from hanging during destruction
  publicly_accessible    = false
}

# ---------------------------------------------------------
# REDIS (In-Memory Cache)
# ---------------------------------------------------------

# 4. Security Group for Redis (Only allows traffic on port 6379)
resource "aws_security_group" "redis_sg" {
  name        = "enterprise-redis-sg"
  description = "Allow internal cache traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Cache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "enterprise-redis-subnet-group"
  subnet_ids = [var.private_subnet_id, var.private_subnet_2_id]
}

# 6. The Actual ElastiCache Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "enterprise-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro" # Smallest, cheapest instance type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}
