import os

from django.core.exceptions import ImproperlyConfigured

from .base import *  # noqa

DEBUG = False

SECRET_KEY = os.environ.get("SECRET_KEY")
if not SECRET_KEY:
    raise ImproperlyConfigured("SECRET_KEY must be set in production")

allowed_hosts = os.environ.get("DJANGO_ALLOWED_HOSTS")
if not allowed_hosts:
    raise ImproperlyConfigured("DJANGO_ALLOWED_HOSTS must be set in production")

ALLOWED_HOSTS = [host.strip() for host in allowed_hosts.split(",") if host.strip()]
