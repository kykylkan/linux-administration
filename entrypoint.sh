#!/bin/sh
set -e

echo "⏳ Застосування міграцій..."
python manage.py migrate --noinput

echo "📦 Збирання статики..."
python manage.py collectstatic --noinput

echo "🚀 Запуск Gunicorn..."
exec gunicorn myapp.wsgi:application --bind 0.0.0.0:8000
