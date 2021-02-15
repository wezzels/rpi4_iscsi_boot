grep '^Serial' /proc/cpuinfo \
    | cut -d ':' -f 2 \
    | sed -E 's/ +0+(.*)/\1/'
