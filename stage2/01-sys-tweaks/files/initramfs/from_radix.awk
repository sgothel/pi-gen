#!/usr/bin/awk -f

function rtodec(str)
{
  # Code page 437 compatible
  # use base = 62, 82 or 143
  base = 62
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

 { print rtodec($0) }

