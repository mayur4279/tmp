#!/bin/sh
set -e

echo "Initializing PostgreSQL..."

# Initialize database if not exists
if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    echo "Initializing database directory..."
    su-exec postgres initdb -D /var/lib/postgresql/data

    # Configure PostgreSQL to accept connections
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
    echo "listen_addresses = '*'" >> /var/lib/postgresql/data/postgresql.conf
fi

# Start PostgreSQL
echo "Starting PostgreSQL..."
su-exec postgres pg_ctl -D /var/lib/postgresql/data -l /var/lib/postgresql/logfile start

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
until su-exec postgres pg_isready; do
    echo "PostgreSQL is not ready yet, waiting..."
    sleep 2
done

# Create database and user
echo "Creating database and user..."
su-exec postgres createdb employee_management 2>/dev/null || true

# Set password for postgres user
su-exec postgres psql -c "ALTER USER postgres WITH PASSWORD 'password';" 2>/dev/null || true
su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE employee_management TO postgres;" 2>/dev/null || true

echo "PostgreSQL is ready and accepting connections!"
echo "Database: employee_management"
echo "User: postgres"
echo "Host: localhost"
echo "Port: 5432"

# Keep PostgreSQL running in foreground
su-exec postgres postgres -D /var/lib/postgresql/data