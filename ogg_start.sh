docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF
start mgr
start extract extr1
start replicat repl1
EOF
"

