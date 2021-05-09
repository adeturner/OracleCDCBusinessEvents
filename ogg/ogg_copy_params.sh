docker exec -it ADEDB bash -c "
cd /opt/oracle/product/ogg19/dirprm
cat > extr1.prm << EOF1
`cat extr1.prm`
EOF1

cat > repl1.prm << EOF2
`cat repl1.prm`
EOF2

cat extr1.prm repl1.prm
"
