"""
TapVerify V1 - Django settings.
All secrets come from .env (see .env.example). Nothing sensitive is hardcoded here.
"""
from pathlib import Path

from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='dev-only-insecure-key')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*', cast=Csv())

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'tapverify.apps.core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'tapverify.apps.core.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'tapverify.config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'tapverify.config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'tapverify.apps.core.authentication.SecretaryTokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'tapverify.apps.core.authentication.IsSecretary',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Nairobi'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- Africa's Talking (SMS + OTP) ---
AFRICASTALKING_USERNAME = config('AFRICASTALKING_USERNAME', default='')
AFRICASTALKING_API_KEY = config('AFRICASTALKING_API_KEY', default='')
AFRICASTALKING_SENDER_ID = config('AFRICASTALKING_SENDER_ID', default='TAPVERIFY')
AFRICASTALKING_SANDBOX = config('AFRICASTALKING_SANDBOX', default=True, cast=bool)

# --- SasaPay (payment rail: checkout + webhooks) ---
SASAPAY_BASE_URL = config('SASAPAY_BASE_URL', default='https://sandbox.sasapay.app')
SASAPAY_CLIENT_ID = config('SASAPAY_CLIENT_ID', default='')
SASAPAY_CLIENT_SECRET = config('SASAPAY_CLIENT_SECRET', default='')
SASAPAY_MERCHANT_CODE = config('SASAPAY_MERCHANT_CODE', default='')
SASAPAY_ACCOUNT_NUMBER = config('SASAPAY_ACCOUNT_NUMBER', default='')
SASAPAY_CALLBACK_URL = config('SASAPAY_CALLBACK_URL', default='')
SASAPAY_MOCK_MODE = config('SASAPAY_MOCK_MODE', default=True, cast=bool)

# Base URL used when building member payment links sent by SMS, e.g. https://tapverify.co
PAYMENT_LINK_BASE = config(
    'PAYMENT_LINK_BASE',
    default=config('RECEIPT_BASE_URL', default='http://127.0.0.1:8000'),
).rstrip('/')

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {'console': {'class': 'logging.StreamHandler'}},
    'root': {'handlers': ['console'], 'level': 'INFO'},
}
