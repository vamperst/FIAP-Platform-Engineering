output "instance_id" {
  description = "ID da instancia EC2 (util para inspecionar/identificar o recurso na AWS)."
  value       = aws_instance.example.id
}

output "instance_public_dns" {
  description = "DNS publico da instancia."
  value       = aws_instance.example.public_dns
}
