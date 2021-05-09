docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF1
create subdirs
EOF1

cat > /opt/oracle/product/ogg19/GLOBALS << EOF
GLOBALS
EOF

"

