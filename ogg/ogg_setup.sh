

docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF1
ADD EXTRACT extr1, INTEGRATED TRANLOG, BEGIN NOW
ADD REPLICAT repl1, EXTTRAIL dirdat/ex, NODBCHECKPOINT
DBLOGIN USERID c##ggadmin@ORCLCDB PASSWORD password1
REGISTER EXTRACT extr1 DATABASE CONTAINER (ORCLPDB1)
ADD EXTTRAIL /opt/oracle/product/ogg19/dirdat/ex, EXTRACT EXTR1
EOF1
"
