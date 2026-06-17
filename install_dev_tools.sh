#!/usr/bin/env bash

# =============================================================================
# install_dev_tools.sh
# Автоматичне встановлення Docker, Docker Compose, Python 3.9+ та Django
# Підтримувані системи: Ubuntu / Debian
# =============================================================================

set -euo pipefail

# ── Кольори для виводу ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ── Хелпери ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Перевірка ОС ──────────────────────────────────────────────────────────────
check_os() {
    if [[ ! -f /etc/debian_version ]]; then
        error "Скрипт підтримує лише Ubuntu / Debian."
    fi
}

# ── Перевірка прав root ───────────────────────────────────────────────────────
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Запустіть скрипт з правами root: sudo $0"
    fi
}

# ── Оновлення індексу пакетів ─────────────────────────────────────────────────
update_packages() {
    info "Оновлення списку пакетів..."
    apt-get update -qq
}

# ── Docker ────────────────────────────────────────────────────────────────────
install_docker() {
    if command -v docker &>/dev/null; then
        warn "Docker вже встановлено: $(docker --version)"
        return
    fi

    info "Встановлення Docker..."

    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Додаємо офіційний GPG-ключ Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Додаємо репозиторій Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    # Запускаємо та вмикаємо сервіс
    systemctl enable --now docker

    success "Docker встановлено: $(docker --version)"
}

# ── Docker Compose ────────────────────────────────────────────────────────────
install_docker_compose() {
    if docker compose version &>/dev/null 2>&1; then
        warn "Docker Compose (plugin) вже встановлено: $(docker compose version)"
        return
    fi

    if command -v docker-compose &>/dev/null; then
        warn "Docker Compose (standalone) вже встановлено: $(docker-compose --version)"
        return
    fi

    info "Встановлення Docker Compose plugin..."
    apt-get install -y -qq docker-compose-plugin

    success "Docker Compose встановлено: $(docker compose version)"
}

# ── Python 3.9+ ───────────────────────────────────────────────────────────────
install_python() {
    # Перевіряємо наявну версію Python 3
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
        PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

        if [[ "$PYTHON_MAJOR" -ge 3 && "$PYTHON_MINOR" -ge 9 ]]; then
            warn "Python $PYTHON_VERSION вже встановлено."
            return
        else
            info "Знайдено Python $PYTHON_VERSION (< 3.9). Встановлюємо новішу версію..."
        fi
    fi

    info "Встановлення Python 3.9+..."
    apt-get install -y -qq python3 python3-pip python3-venv

    success "Python встановлено: $(python3 --version)"
}

# ── Django ────────────────────────────────────────────────────────────────────
install_django() {
    # Перевіряємо наявність Django
    if python3 -c "import django" &>/dev/null 2>&1; then
        DJANGO_VERSION=$(python3 -c "import django; print(django.__version__)")
        warn "Django $DJANGO_VERSION вже встановлено."
        return
    fi

    info "Встановлення Django через pip..."

    # Встановлюємо pip якщо відсутній
    if ! command -v pip3 &>/dev/null; then
        apt-get install -y -qq python3-pip
    fi

    pip3 install --quiet django

    success "Django встановлено: $(python3 -c "import django; print(django.__version__)")"
}

# ── Підсумок ──────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Встановлення завершено успішно!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Docker:          $(docker --version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Docker Compose:  $(docker compose version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Python:          $(python3 --version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Django:          $(python3 -c "import django; print(django.__version__)" 2>/dev/null || echo 'не знайдено')"
    echo ""
}

# ── Точка входу ───────────────────────────────────────────────────────────────
main() {
    echo ""
    info "=== Скрипт встановлення DevOps-інструментів ==="
    echo ""

    check_os
    check_root
    update_packages
    install_docker
    install_docker_compose
    install_python
    install_django
    print_summary
}

main "$@"
