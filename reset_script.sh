#!/bin/bash

CCD_DIR="$path_to_conf/ccd/"


# Проход по всем файлам в папке ccd
for file in $CCD_DIR*; do
    if [ -f "$file" ]; then
        # Проверка наличия строки #connected=true в файле
        if grep -q "#connected=true" "$file"; then
            # Замена строки на #connected=false
            sed -i 's/#connected=true/#connected=false/' "$file"
        fi
    fi
done
