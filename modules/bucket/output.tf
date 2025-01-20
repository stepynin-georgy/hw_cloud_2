output "static_key_id"{
    value=nonsensitive( yandex_iam_service_account_static_access_key.sa-static-key.access_key)
    description="Идентификатор ключа доступа" 
}

output "static_key_secret"{
    value=nonsensitive( yandex_iam_service_account_static_access_key.sa-static-key.secret_key)
    description="Секретный ключ доступа" 
}
