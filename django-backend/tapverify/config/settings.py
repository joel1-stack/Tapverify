"""
TapVerify Django Settings
Use .env for secrets in production.
"""
import os
from pathlib import Path
from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='dev-key-change-in-production')
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
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='tapverify'),
        'USER': config('DB_USER', default='tapverify'),
        'PASSWORD': config('DB_PASSWORD', default='tapverify123'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Nairobi'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

LOGIN_URL = '/login/'

LOGIN_URL = '/login/'

RECEIPT_BASE_URL = config('RECEIPT_BASE_URL', default='https://tverify.co.ke')

AFRICASTALKING_USERNAME = config('AFRICASTALKING_USERNAME', default='')
AFRICASTALKING_API_KEY = config('AFRICASTALKING_API_KEY', default='')
AFRICASTALKING_SENDER_ID = config('AFRICASTALKING_SENDER_ID', default='TAPVERIFY')
AFRICASTALKING_AIRTIME_PRODUCT_CODE = config('AFRICASTALKING_AIRTIME_PRODUCT_CODE', default='TAPVERIFY')
AFRICASTALKING_USSD_SERVICE_CODE = config('AFRICASTALKING_USSD_SERVICE_CODE', default='*384*123#')

# Avalanche Fuji attestations
AVALANCHE_RPC = config('AVALANCHE_RPC', default='https://api.avax-test.network/ext/bc/C/rpc')
AVALANCHE_CHAIN_ID = config('AVALANCHE_CHAIN_ID', default=43113, cast=int)
AVALANCHE_ATTESTATION_ADDRESS = config('AVALANCHE_ATTESTATION_ADDRESS', default='')
AVALANCHE_PRIVATE_KEY = config('AVALANCHE_PRIVATE_KEY', default='')

# SasaPay (production keys for Tap Verify - VIEWTECH LIMITED)
SASAPAY_BASE_URL = config('SASAPAY_BASE_URL', default='https://sandbox.sasapay.app')
SASAPAY_CLIENT_ID = config('SASAPAY_CLIENT_ID', default='XNxeTbgFcKgRHYknbAmhKQApoHhl0P8jp9oGs5US')
SASAPAY_CLIENT_SECRET = config('SASAPAY_CLIENT_SECRET', default='iCzqvZ93tFBDbdkubiAo1qSvswKuF0bV52yfeCaQ2JoBLdb8tL6QV12bq5qEacNzpOdgW74wtqsWTN05JzkdbpXSnqapC5AJ5m4jALTiUhWwORAC20JsVFcsRROrnmYF')
SASAPAY_MERCHANT_CODE = config('SASAPAY_MERCHANT_CODE', default='600980')
SASAPAY_ACCOUNT_NUMBER = config('SASAPAY_ACCOUNT_NUMBER', default='600980')
SASAPAY_CALLBACK_URL = config('SASAPAY_CALLBACK_URL', default='https://api.tvrfy.co.ke/webhooks/sasapay/')

# Active payment rail: 'sasapay'
ACTIVE_PAYMENT_RAIL = config('ACTIVE_PAYMENT_RAIL', default='sasapay')

# SasaPay (sandbox keys for TapVerify — VIEWTECH LIMITED)
SASAPAY_BASE_URL = config('SASAPAY_BASE_URL', default='https://sandbox.sasapay.app')
SASAPAY_CLIENT_ID = config('SASAPAY_CLIENT_ID', default='XNxeTbgFcKgRHYknbAmhKQApoHhl0P8jp9oGs5US')
SASAPAY_CLIENT_SECRET = config('SASAPAY_CLIENT_SECRET', default='iCzqvZ93tFBDbdkubiAo1qSvswKuF0bV52yfeCaQ2JoBLdb8tL6QV12bq5qEacNzpOdgW74wtqsWTN05JzkdbpXSnqapC5AJ5m4jALTiUhWwORAC20JsVFcsRROrnmYF')
SASAPAY_MERCHANT_CODE = config('SASAPAY_MERCHANT_CODE', default='600980')
SASAPAY_ACCOUNT_NUMBER = config('SASAPAY_ACCOUNT_NUMBER', default='600980')
SASAPAY_CALLBACK_URL = config('SASAPAY_CALLBACK_URL', default='https://api.tvrfy.co.ke/webhooks/sasapay/')

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
