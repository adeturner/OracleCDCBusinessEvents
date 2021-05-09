

docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19

./ggsci << EOF2
stop extract *
stop replicat *
EOF2
"
