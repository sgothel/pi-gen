function rtodec(str, base)
{
  # Code page 437 compatible
  # use base = 62, 82 or 143
  max_base = 143
  symbols = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#%&()+,-.;=@[]^_{}~ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿½¼¡«»αßΓπΣσµτΦΘΩδ∞φε"

  if( base > max_base ) {
    printf "Error: rtodec base %d > max_base %d\n", base, max_base
    exit
  }

  res = 0
  for(i=1; i < length(str); i++) {
    res += index(symbols, substr(str, i, 1)) - 1
    res *= base
  }
  res += index(symbols, substr(str, length(str), 1)) - 1
  return res
}

function dector(num, base)
{
  # Code page 437 compatible
  # use base = 62, 82 or 143
  max_base = 143
  symbols = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#%&()+,-.;=@[]^_{}~ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿½¼¡«»αßΓπΣσµτΦΘΩδ∞φε"

  if( base > max_base ) {
    printf "Error: dector base %d > max_base %d\n", base, max_base
    exit
  }

  res = ""
  do {
    res = substr(symbols, num%base + 1, 1) res
    num = int(num/base)
  } while ( num != 0 )
  res3 = "00" res; # zero padded 3-digit result
  return substr(res3, length(res3) - 3 + 1);
}

BEGIN {
  max_base = 143
  # use base = 62, 82 or 143
  if( 0 == base ) {
    base = 62
  } else if( base > max_base ) {
    printf "Error: base %d > max_base %d\n", base, max_base
    exit
  }
  r1_max = dector(base-1, base)
  r1_max_s = substr(r1_max, 3)
  r2_max = r1_max_s r1_max_s
  r3_max = r1_max_s r1_max_s r1_max_s
  min = rtodec("0", base)
  max = rtodec(r3_max, base)
  test_vfat_max = rtodec(r2_max, base)
  printf "Test base %d: [%06d-%06d] <-> ['%s'-'%s'], %d years (max/365d) \n", base, min, max, dector(min, base), dector(max, base), (max/365)
  if( 1 == test_vfat ) {
      printf "and vfat testing: [%06d-%06d] <-> ['%s'-'%s']\n", min, test_vfat_max, dector(min, base), dector(test_vfat_max, base)
  }
  print
  print "test 0"
  print rtodec("0", base)
  print rtodec("000", base)
  print dector(0, base)
  print 
  print "test 1"
  print rtodec("1", base)
  print rtodec("001", base)
  print dector(1, base)
  print 
  print "test r1_max"
  {
      v0_d = rtodec(r1_max, base)
      v1_s = dector(base-1, base)
      if( r1_max != v1_s ) {
        printf "Error r1_max: exp %s != has %s\n", r1_max, v1_s
        exit
      }
      if( (base-1) != v0_d ) {
        printf "Error r1_max: exp %s != has %s\n", (base-1), v0_d
        exit
      }
      printf "r1_max: %s, %s\n", v1_s, v0_d
  }
  print 
  print "test r3_max"
  {
      v0_d = rtodec(r3_max, base)
      v1_s = dector(max, base)
      if( r3_max != v1_s ) {
        printf "Error r3_max: exp %s != has %s\n", r3_max, v1_s
        exit
      }
      if( max != v0_d ) {
        printf "Error r3_max: exp %s != has %s\n", max, v0_d
        exit
      }
      printf "r3_max: %s, %s\n", v1_s, v0_d
  }
  print 
  rad = ""
  dec = 0
  iter = 0
  for(iter=min; iter<=max; ++iter) {
    rad = dector(iter, base)
    dec = rtodec(rad, base)
    if( iter != dec ) {
        printf "ERROR: %d == '%s' == %d\n", iter, rad, dec
        exit
    }
    if( 1 == test_vfat && iter <= test_vfat_max ) {
        fname = "/mnt/tst/test_" rad
        printf "%d\n", dec > fname
        close(fname)
        if( 0 == getline line_in < fname ) {
            printf "ERROR: vfat '%s': radix '%s', line '%s', getline failed\n", fname, rad, line_in
            exit
        }
        close(fname)
        dec_in = strtonum(line_in)
        if ( dec != dec_in ) {
            printf "ERROR: vfat '%s': radix '%s', line '%s', exp %d != has %d\n", fname, rad, line_in, dec, dec_in
            exit
        } else {
            # printf "vfat '%s': radix '%s', exp %d == has %d\n", fname, rad, dec, dec_in
            # OK: rm_cmd = "rm '" fname "'"
            rm_cmd = "rm \"" fname "\""
            # Error: rm_cmd = "rm " fname
            # printf "%s\n", rm_cmd
            system(rm_cmd)
        }
    }
  }
  printf "Unit test OK: [%06d-%06d] <-> ['%s'-'%s']\n", min, max, dector(min, base), dector(max, base)
}

