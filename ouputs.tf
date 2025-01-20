output "static_key_id"{
    value= module.bucket.static_key_id 
    description="Идентификатор ключа доступа" 
}

output "static_key_secret"{
    value= module.bucket.static_key_secret
    description="Секретный ключ доступа" 
}
