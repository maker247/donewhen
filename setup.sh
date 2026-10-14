#!/bin/bash
set -e

echo "=== Creating user ==="
docker exec donewhen-donewhen-1 /app/donewhen user admin@example.com '@chikton334dev' && echo "User created OK" || echo "User may already exist"

echo "=== Creating workspace: ESPM ==="
docker exec donewhen-donewhen-1 /app/donewhen workspace create "ESPM" ESPM && echo "ESPM OK"

echo "=== Creating workspace: DMC ==="
docker exec donewhen-donewhen-1 /app/donewhen workspace create "DMC" DMC && echo "DMC OK"

echo "=== Creating workspace: ODOO-17 ==="
docker exec donewhen-donewhen-1 /app/donewhen workspace create "ODOO-17" ODO && echo "ODOO-17 OK"

echo "=== All done! ==="
