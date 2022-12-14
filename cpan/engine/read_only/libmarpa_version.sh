for arg;do
  if test "$arg" = major; then echo 11; continue; fi
  if test "$arg" = minor; then echo 0; continue; fi
  if test "$arg" = micro; then echo 2; continue; fi
  if test "$arg" = version; then echo 11.0.2; continue; fi
  echo Bad arg to $0: $arg
done
