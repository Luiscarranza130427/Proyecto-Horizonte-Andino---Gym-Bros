<?php

return [
    'paths'=>['api/*','sanctum/csrf-cookie'],
    'allowed_methods'=>['*'],
    // CORS_ALLOWED_ORIGINS (lista separada por comas) fija los origenes del panel
    // y la web. Sin definirla se conserva el comportamiento anterior.
    'allowed_origins'=>env('CORS_ALLOWED_ORIGINS')
        ? array_values(array_filter(array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS')))))
        : (env('MP_ENABLED', false) ? array_filter([env('FRONTEND_URL')]) : ['*']),
    'allowed_origins_patterns'=>[],
    'allowed_headers'=>['*'],
    'exposed_headers'=>[],
    'max_age'=>0,
    'supports_credentials'=>false,
];
