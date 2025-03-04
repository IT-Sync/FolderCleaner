#!/bin/bash

# Проверяем наличие необходимых утилит
command -v yq >/dev/null 2>&1 || { echo "Требуется утилита yq. Установите её с помощью: sudo apt-get install yq"; exit 1; }

# Путь к конфиг файлу
CONFIG_FILE="cleaner_config.yaml"

# Проверяем существование конфиг файла
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Конфигурационный файл $CONFIG_FILE не найден!"
    exit 1
fi

# Получаем количество директорий в конфиге
DIR_COUNT=$(yq eval '.cleanup.directories | length' "$CONFIG_FILE")

if [ "$DIR_COUNT" -eq 0 ]; then
    echo "В конфигурационном файле не указаны директории для очистки"
    exit 1
fi

echo "Найдено директорий для обработки: $DIR_COUNT"

# Проходим по всем директориям
for ((i=0; i<DIR_COUNT; i++)); do
    # Читаем параметры для текущей директории
    CLEANUP_PATH=$(yq eval ".cleanup.directories[$i].path" "$CONFIG_FILE")
    DAYS=$(yq eval ".cleanup.directories[$i].days" "$CONFIG_FILE")
    ENABLED=$(yq eval ".cleanup.directories[$i].enabled" "$CONFIG_FILE")
    RECURSIVE=$(yq eval ".cleanup.directories[$i].recursive" "$CONFIG_FILE")

    echo -e "\nОбработка директории #$((i+1)): $CLEANUP_PATH"

    # Проверяем, включена ли очистка
    if [ "$ENABLED" != "true" ]; then
        echo "Очистка отключена для этой директории"
        continue
    fi

    # Проверяем, существует ли директория
    if [ ! -d "$CLEANUP_PATH" ]; then
        echo "Директория $CLEANUP_PATH не существует!"
        continue
    fi

    # Формируем команду find в зависимости от рекурсивности
    if [ "$RECURSIVE" = "true" ]; then
        FIND_CMD="find \"$CLEANUP_PATH\" -type f"
    else
        FIND_CMD="find \"$CLEANUP_PATH\" -maxdepth 1 -type f"
    fi

    echo "Параметры:"
    echo "Срок для удаления: старше $DAYS дней"
    echo "Рекурсивный режим: $RECURSIVE"

    # Выполняем очистку
    $FIND_CMD -mtime +$DAYS -exec rm -v {} \;
done

echo -e "\nОчистка всех директорий завершена"
exit 0
