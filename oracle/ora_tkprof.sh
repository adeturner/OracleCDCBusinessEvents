docker exec -it ADEDB bash -c "

sqlplus / as sysdba << EOF
@?/rdbms/admin/utlxplan.sql
CREATE PUBLIC SYNONYM PLAN_TABLE FOR SYS.PLAN_TABLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYS.PLAN_TABLE TO PUBLIC;
EOF

tkprof $1 tkprof.out explain=target/password1@//localhost:1521/ORCLPDB1 table=sys.plan_table sys=no

cat tkprof.out

"
