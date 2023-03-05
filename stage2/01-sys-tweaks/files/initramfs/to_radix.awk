#!/usr/bin/awk -f

function dector(num)
{
  # Code page 437 compatible
  # use base = 62, 82 or 143
  base = 62
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

 { print dector(strtonum($0)) }

