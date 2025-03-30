.PHONY: db-import db-backup db-reset db-status up stop down

SQL_DIR ?= docker/mysql/sql_scripts_import

up:
	@echo "🚀 Starting all containers..."
	@docker compose up -d

# Stop all containers
stop:
	@echo "🛑 Stopping all containers..."
	@docker compose stop

# Remove all containers, networks created by up
down:
	@echo "🧹 Removing all containers and networks..."
	@docker compose down

# Import all SQL files
db-import:
	@echo "🔄 Starting database import from $(SQL_DIR)..."
	@chmod +x ./docker/mysql/import.sh
	@./docker/mysql/import.sh

# Create database backup
db-backup:
	@echo "📦 Creating database backup..."
	@mkdir -p ./database/backups
	@docker compose exec mysql mysqldump -u"$$DB_USERNAME" -p"$$DB_PASSWORD" "$$DB_DATABASE" > ./database/backups/backup_$$(date +%Y%m%d_%H%M%S).sql

# Reset and import fresh database
db-reset:
	@echo "🔄 Resetting database..."
	@docker compose exec app php artisan migrate:fresh
	@make db-import

# Check database status
db-status:
	@echo "📊 Checking database status..."
	@docker compose exec mysql mysql -u"$$DB_USERNAME" -p"$$DB_PASSWORD" "$$DB_DATABASE" -e "SHOW TABLES;"

# List SQL files that will be imported
db-list-files:
	@echo "📄 SQL files to be imported (in order):"
	@find $(SQL_DIR) -name "*.sql" | sort
