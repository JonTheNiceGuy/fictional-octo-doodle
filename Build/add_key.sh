#!/bin/bash
if [ ! -e "$2" ]
then
  echo "ADD_KEY INFO: Making empty target: $2"
  mkdir -p "$(dirname "$2")"
  touch "$2"
  chmod 700 "$(dirname "$2")"
  chown "$3:$3" "$(dirname "$2")"
  chmod 600 "$2"
  chown "$3:$3" "$2"
fi
echo "ADD_KEY INFO: Checking file is a public key, or collection of public keys."
if file "$(readlink -f "$1")" | grep -E 'OpenSSH [-A-Za-z0-9]+ public key' >/dev/null 2>/dev/null
then
  echo "ADD_KEY INFO: Parsing file for keys."
  while IFS="" read -r line || [ -n "$p" ]
  do
    type="$(echo "$line" | cut -d\  -f1)"
    if echo "$type" | grep -E '^ssh-[-A-Za-z0-9]+|^ecdsa-[-A-Za-z0-9]+' 2>/dev/null >/dev/null
    then
      key="$(echo "$line" | cut -d\  -f2)"
      check="$(grep "$type $key" "$2" 2>/dev/null)"
      comment="$(echo "$line" | cut -d\  -f3-)"
      if [ -z "$comment" ]
      then
        comment="[NONE]"
      fi
      echo "ADD_KEY INFO: Line contains an SSH key. (Comment: $comment)"
      if [ -z "$check" ]
      then
        echo "ADD_KEY INFO: This key is not in target. Adding."
        echo "$line" >> "$2"
      fi
    else
      echo "ADD_KEY INFO: Line did not contain an SSH key: $line"
    fi
  done < "$1"
fi
echo "ADD_KEY INFO: Finished."