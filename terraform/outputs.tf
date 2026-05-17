# ============================================================
# OUTPUTS
# Muestran información útil al terminar el "terraform apply"
# ============================================================
output "front_ip_publica" {
  description = "IP publica del servidor Front (acceso desde Internet)"
  value       = aws_instance.front.public_ip
}

output "back_ip_privada" {
  description = "IP privada del Back (solo accesible desde el Front)"
  value       = aws_instance.back.private_ip
}

output "data_ip_privada" {
  description = "IP privada del Data (solo accesible desde el Back)"
  value       = aws_instance.data.private_ip
}
