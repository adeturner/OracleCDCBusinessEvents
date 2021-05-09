docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF
view report extr1
view report repl1
EOF
"

