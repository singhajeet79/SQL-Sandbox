#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'admin';
    CREATE DATABASE sakila;
    CREATE DATABASE employee_example;
    GRANT ALL PRIVILEGES ON DATABASE sakila TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE employee_example TO postgres;
EOSQL
