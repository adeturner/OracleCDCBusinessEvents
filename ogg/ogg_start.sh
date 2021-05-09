docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF1
start mgr
EOF1

echo Sleeping whilst mgr starts... 
sleep 5

./ggsci << EOF2
start extract extr1
start replicat repl1
EOF2
"

