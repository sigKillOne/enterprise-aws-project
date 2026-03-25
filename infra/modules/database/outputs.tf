# infra/modules/database/outputs.tf

output "postgres_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "The connection endpoint for the PostgreSQL database"
}

output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "The connection endpoint for the Redis cache cluster"
}
