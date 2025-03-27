USE mysql;
CREATE USER IF NOT EXISTS 'laravel_user'@'%' IDENTIFIED BY 'localpass';
GRANT ALL PRIVILEGES ON laravel.* TO 'laravel_user'@'%';
FLUSH PRIVILEGES;
