docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF1
info extract extr1
info replicat repl1
EOF1
"

