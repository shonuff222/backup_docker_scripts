#!/bin/bash

# Define the folder where backup files are located
BACKUPDIR="/backup/mysql"

# Display a numbered list of containers from the backup directory
echo "Available containers:"
CONTAINERS=($(for file in "$BACKUPDIR"/*.sql.gz; do IFS='-' read -r CONTAINER _ <<< "$(basename "$file" .sql.gz)"; echo "$CONTAINER"; done | sort -u))
for ((i=0; i<${#CONTAINERS[@]}; i++)); do
    echo "$((i+1)). ${CONTAINERS[$i]}"
done

# Prompt the user to select a container
read -p "Enter the number of the container: " CONTAINER_NUMBER
if [[ ! $CONTAINER_NUMBER =~ ^[0-9]+$ || $CONTAINER_NUMBER -lt 1 || $CONTAINER_NUMBER -gt ${#CONTAINERS[@]} ]]; then
    echo "Invalid input. Please enter a valid container number."
    exit 1
fi

# Get the selected container name
CONTAINER=${CONTAINERS[$((CONTAINER_NUMBER-1))]}

# Display a numbered list of databases for the selected container
echo "Available databases in container $CONTAINER:"
DATABASES=($(for file in "$BACKUPDIR"/*.sql.gz; do IFS='-' read -r FILE_CONTAINER FILE_DATABASE _ <<< "$(basename "$file" .sql.gz)"; if [ "$FILE_CONTAINER" == "$CONTAINER" ]; then echo "$FILE_DATABASE"; fi>
for ((i=0; i<${#DATABASES[@]}; i++)); do
    echo "$((i+1)). ${DATABASES[$i]}"
done

# Prompt the user to select a database
read -p "Enter the number of the database: " DATABASE_NUMBER
if [[ ! $DATABASE_NUMBER =~ ^[0-9]+$ || $DATABASE_NUMBER -lt 1 || $DATABASE_NUMBER -gt ${#DATABASES[@]} ]]; then
    echo "Invalid input. Please enter a valid database number."
    exit 1
fi

# Get the selected database name
DATABASENAME=${DATABASES[$((DATABASE_NUMBER-1))]}

# Display a numbered list of timestamps for the selected container and database
echo "Available timestamps for container $CONTAINER and database $DATABASENAME:"
TIMESTAMPS=($(for file in "$BACKUPDIR"/*.sql.gz; do IFS='-' read -r FILE_CONTAINER FILE_DATABASE FILE_TIMESTAMP _ <<< "$(basename "$file" .sql.gz)"; if [ "$FILE_CONTAINER" == "$CONTAINER" ] && [ "$FILE_DAT>
for ((i=0; i<${#TIMESTAMPS[@]}; i++)); do
    # Manually split and format the timestamp as YYYY-MM-DD HH:mm
    YEAR=${TIMESTAMPS[$i]:0:4}
    MONTH=${TIMESTAMPS[$i]:4:2}
    DAY=${TIMESTAMPS[$i]:6:2}
    HOUR=${TIMESTAMPS[$i]:8:2}
    MINUTE=${TIMESTAMPS[$i]:10:2}
    TIMESTAMP_FORMATTED="$YEAR-$MONTH-$DAY $HOUR:$MINUTE"
    echo "$((i+1)). $TIMESTAMP_FORMATTED"
done

# Prompt the user to select a timestamp
read -p "Enter the number of the timestamp: " TIMESTAMP_NUMBER
if [[ ! $TIMESTAMP_NUMBER =~ ^[0-9]+$ || $TIMESTAMP_NUMBER -lt 1 || $TIMESTAMP_NUMBER -gt ${#TIMESTAMPS[@]} ]]; then
    echo "Invalid input. Please enter a valid timestamp number."
    exit 1
fi

# Get the selected timestamp
TIMESTAMP=${TIMESTAMPS[$((TIMESTAMP_NUMBER-1))]}

# Get the selected filename
FILENAME="$CONTAINER-$DATABASENAME-$TIMESTAMP.sql.gz"

# Set the MySQL password in the MYSQL_PWD variable
MYSQL_PWD=$(docker exec $CONTAINER env | grep MYSQL_ROOT_PASSWORD | cut -d"=" -f2)

# Display confirmation prompt
read -p "Confirm recovery of DB $DATABASENAME in Container $CONTAINER from $TIMESTAMP_FORMATTED? (yes/y): " CONFIRMATION
if [[ ! $CONFIRMATION =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
    echo "Recovery canceled by user."
    exit 1
fi

# Execute the desired command and capture the output
OUTPUT=$(zcat "$BACKUPDIR/$FILENAME" | docker exec -i $CONTAINER /usr/bin/mysql -u root --password=$MYSQL_PWD $DATABASENAME 2>&1)

# Display the output
echo "Output of MySQL command:"
echo "$OUTPUT"
