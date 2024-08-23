#!/bin/bash

echo "Анализ размера окружения Dendrite"
echo "================================="

# Создаем временный профиль
nix develop ~/Documents/flakes/dendrite/flake.nix --profile /tmp/dendrite-profile

# Получаем все пути зависимостей
paths=$(nix-store -qR /tmp/dendrite-profile)

# Вычисляем общий размер
total_size=$(du -ch $paths | tail -n1 | cut -f1)

echo "Общий размер окружения: $total_size"

# Показываем размер каждой зависимости
echo -e "\nРазмер всех зависимостей:"
du -sh $paths | sort -rh

# Очистка
nix-env -p /tmp/dendrite-profile --delete-generations old
rm /tmp/dendrite-profile