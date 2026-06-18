FROM python:3.11-slim

# Встановлення системних залежностей
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Робоча директорія
WORKDIR /app

# Встановлення Python-залежностей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо код проєкту
COPY myapp/ .

# Копіюємо entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Порт Django
EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
