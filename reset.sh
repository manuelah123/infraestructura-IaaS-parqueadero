#!/bin/bash

echo " Reseteando base de datos..."

DB1=$(incus exec db-node1 -- hostname -I | awk '{print $1}')

# Recrear base de datos
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 -e "DROP DATABASE IF EXISTS parqueadero CASCADE;"
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 -e "CREATE DATABASE parqueadero;"

# Cargar schema
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 --database=parqueadero < ~/parking-project/database/init.sql

echo " Base de datos reseteada"
