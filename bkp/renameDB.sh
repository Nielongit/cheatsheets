#!/bin/bash

mysqlconn="mysql -u root -pmyPass09 -S /var/lib/mysql/mysql.sock -h localhost"
olddb=ShawPRRFLOW
newdb=ShawPRRFLOW_old

#$mysqlconn -e "CREATE DATABASE $newdb"
params=$($mysqlconn -N -e "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE table_schema='$olddb'")

for name in $params; do
      #$mysqlconn -e "RENAME TABLE $olddb.$name to $newdb.$name";
echo $olddb.$name $newdb.$name
done;

