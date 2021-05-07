

docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19
./ggsci << EOF
info replicat *
info extract *
EOF
"

