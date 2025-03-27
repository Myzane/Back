#!/bin/bash

# Load environment variables
source .env

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SQL_DIR="docker/mysql/sql_scripts_import"

# Drop and recreate database
reset_database() {
    echo -e "${BLUE}Dropping and recreating database...${NC}"

    # Connect as root to perform administrative tasks
    docker compose exec -T mysql mysql -uroot -p"${DB_ROOT_PASSWORD}" <<EOF
        DROP DATABASE IF EXISTS laravel;
        CREATE DATABASE laravel;
        DROP USER IF EXISTS 'laravel_user'@'%';
        DROP USER IF EXISTS 'laravel_user'@'localhost';
        CREATE USER 'laravel_user'@'%' IDENTIFIED BY 'localpass';
        CREATE USER 'laravel_user'@'localhost' IDENTIFIED BY 'localpass';
        GRANT ALL PRIVILEGES ON laravel.* TO 'laravel_user'@'%';
        GRANT ALL PRIVILEGES ON laravel.* TO 'laravel_user'@'localhost';
        FLUSH PRIVILEGES;
EOF




    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database reset successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to reset database${NC}"
        return 1
    fi
}

# Run Laravel migrations
run_migrations() {
    echo -e "${BLUE}Running Laravel migrations...${NC}"

    docker compose exec -T app php artisan migrate:fresh

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Migrations completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Migrations failed${NC}"
        return 1
    fi
}

# Import single file
# Import single file
import_file() {
    local file=$1
    echo -e "${BLUE}Importing ${file}...${NC}"

    # Extract the table name from the file path
    local table_name=$(basename "$file" .sql)

    # If it's the settings table, truncate it first
    if [ "$table_name" = "settings" ]; then
        docker compose exec -T mysql mysql -uroot -p"${DB_ROOT_PASSWORD}" "laravel" \
            -e "TRUNCATE TABLE settings;"
    fi

    # Import the file by piping its contents with relaxed settings
    docker compose exec -T mysql mysql -uroot -p"${DB_ROOT_PASSWORD}" "laravel" \
        --init-command="SET SESSION FOREIGN_KEY_CHECKS=0; SET sql_mode='NO_ENGINE_SUBSTITUTION';" < "$file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully imported ${file}${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to import ${file}${NC}"
        return 1
    fi
}

# Main import function
main() {
      reset_database
      if [ $? -ne 0 ]; then
          echo -e "${RED}Database reset failed, aborting import${NC}"
          exit 1
      fi

    if [ ! -d "$SQL_DIR" ]; then
        echo -e "${RED}Error: Directory $SQL_DIR does not exist${NC}"
        exit 1
    fi

    local failed=0

    run_migrations
    if [ $? -ne 0 ]; then
        echo -e "${RED}Migrations failed, aborting import${NC}"
        exit 1
    fi

    # Using traditional file list method
    files=($(find "$SQL_DIR" -name "*.sql" | sort))

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}No SQL files found in $SQL_DIR${NC}"
        exit 1
    fi

    echo -e "${BLUE}Found ${#files[@]} SQL files to import${NC}"

    for file in "${files[@]}"; do
        import_file "$file"
        if [ $? -ne 0 ]; then
            failed=1
            echo -e "${RED}Stopping import process due to error${NC}"
            break
        fi
    done

    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All files imported successfully!${NC}"
    else
        echo -e "${RED}Import process failed${NC}"
        exit 1
    fi
}

main