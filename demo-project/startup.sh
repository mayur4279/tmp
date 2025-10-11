#!/bin/sh
set -e

echo "=== Starting Employee Management System ==="

# Start PostgreSQL in background
echo "1. Starting PostgreSQL..."
/app/init-db.sh &

# Wait for PostgreSQL to be ready
echo "2. Waiting for PostgreSQL to be ready..."
until pg_isready -h localhost -U postgres -p 5432; do
    echo "Waiting for PostgreSQL..."
    sleep 3
done

echo "3. PostgreSQL is ready! Creating database..."
# Ensure database exists
psql -h localhost -U postgres -c "CREATE DATABASE employee_management;" 2>/dev/null || true

# Wait a bit more to ensure PostgreSQL is fully ready
sleep 5

echo "4. Starting Go Backend Application..."
# Start the Go application
DB_HOST=localhost DB_USER=postgres DB_PASSWORD=password DB_NAME=employee_management DB_PORT=5432 ALLOWED_ORIGINS=* /app/main

echo "5. Backend application started successfully!"