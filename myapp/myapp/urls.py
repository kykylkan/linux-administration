from django.contrib import admin
from django.urls import path
from django.http import HttpResponse


def index(request):
    return HttpResponse(
        "<h1>Django + PostgreSQL + Nginx</h1>"
        "<p>Проєкт успішно запущено у Docker! 🐳</p>"
        '<p><a href="/admin/">Адмін-панель</a></p>'
    )


urlpatterns = [
    path("", index),
    path("admin/", admin.site.urls),
]
