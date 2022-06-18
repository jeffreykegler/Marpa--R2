for arg;do
  if test "$arg" = major; then echo 8; continue; fi
  if test "$arg" = minor; then echo 6; continue; fi
  if test "$arg" = micro; then echo 7; continue; fi
  if test "$arg" = version; then echo 8.6.7; continue; fi
  echo Bad arg to $0: $arg
done
