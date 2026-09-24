<?php

return [
    'enabled' => env('MP_ENABLED', false),
    'access_token' => env('MP_ACCESS_TOKEN'),
    'webhook_secret' => env('MP_WEBHOOK_SECRET'),
    'notification_url' => env('MP_NOTIFICATION_URL'),
    'frontend_url' => env('FRONTEND_URL'),
    'live_mode' => env('MP_LIVE_MODE', false),
    'logo' => env('ONBOARDING_LOGO'),
    'color_1' => '#E50914',
    'color_2' => '#111111',
];
