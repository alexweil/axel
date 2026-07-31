# cut.awk — reconstruye el snapshot del round log a un commit de corte.
# Falla si el SHA no aparece o aparece más de una vez: un recorte que falla
# abierto es peor que no tenerlo.
#   awk -v cut=<sha> -f cut.awk <round-log> > snapshot.tsv
BEGIN { FS = "\t" }
{ line[NR] = $0 }
$6 == cut { hit++; stop = NR }
END {
  if (hit != 1) {
    printf "FAIL: %d row(s) with cut SHA %s; exactly 1 required\n", hit+0, cut > "/dev/stderr"
    exit 1
  }
  for (i = 1; i <= stop; i++) print line[i]
}
