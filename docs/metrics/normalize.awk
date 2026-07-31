# normalize.awk — one line per contractual review round: cycle, round, verdict, sha.
# A round is the unit of the review contract, not a row of the log: review.sh
# retries once on process failure (logging PROC_FAIL before the verdict), and an
# invalid verdict is logged as NO_VERDICT. Counting rows would inflate both.
#   awk -f normalize.awk snapshot.tsv > rounds.tsv     # rc MUST be 0
function die(msg) { printf "FAIL: line %d: %s\n", NR, msg > "/dev/stderr"; failed = 1; exit 1 }
BEGIN { FS = "\t"; OFS = "\t"; cyc = 0; prev = 0; failed = 0 }
$2 == "new" && ($4 == "1" || $4 == "-") { cyc++; prev = 0 }
$3 ~ /^[0-9]+$/ {
  cur = $3 + 0; att = $4 + 0
  if (cyc >= 1 && prev == 0 && cur != 1)
    die("cycle " cyc " opens at round " cur " instead of 1")
  if (prev > 0 && cur < prev)
    die("round goes back from " prev " to " cur " with no cycle boundary (missing `new` row?)")
  if (prev > 0 && cur > prev + 1)
    die("round jumps from " prev " to " cur " (missing round row?)")
  if (prev > 0 && cur == prev) {
    if (pverd != "PROC_FAIL" || $2 != pmode || $6 != psha || att != patt + 1)
      die("round " cur " repeats without being a valid retry")
  }
  key = cyc SUBSEP cur
  if (!(key in seen)) { seen[key] = 1; order[++n] = key; c[key] = cyc; r[key] = cur }
  v[key] = $5; s[key] = $6
  prev = cur; patt = att; pverd = $5; pmode = $2; psha = $6
}
END { if (failed) exit 1
      for (i = 1; i <= n; i++)
        { k = order[i]; print c[k], r[k], v[k], s[k] } }
