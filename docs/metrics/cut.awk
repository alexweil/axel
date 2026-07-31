# cut.awk — reconstructs the round-log snapshot at a cut commit.
# Fails if the SHA is absent or appears more than once: a recorte that fails
# open is worse than having none at all.
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
