#!/bin/bash

# Путь к директории ccd
CCD_DIR="/etc/openvpn"

# Перебираем все директории, соответствующие шаблону /etc/openvpn/server-$proto-$port
for dir in "$CCD_DIR"/server-*; do
    # Проверяем, что это действительно директория
    if [ -d "$dir" ]; then
        # Перебираем все файлы в директории ccd
        for file in "$dir"/ccd/*; do
            # Проверяем, что это действительно файл и содержит #ticks_remaining
            if [ -f "$file" ] && grep -q "#ticks_remaining=" "$file"; then
                # Извлекаем текущее значение #ticks_remaining
                ticks_remaining=$(grep -E -o '^[^#]*#?ticks_remaining=[0-9]*' "$file" | cut -d'=' -f2)

                # Проверяем, что значение не пусто и больше 0
                if [ -n "$ticks_remaining" ] && [ "$ticks_remaining" -gt 0 ]; then
                    # Уменьшаем значение на 1
                    ((ticks_remaining--))

                    # Записываем новое значение обратно в файл
                    sed -i "s/#ticks_remaining=[0-9]*/#ticks_remaining=$ticks_remaining/" "$file"

                fi
            fi
        done
    fi
done
