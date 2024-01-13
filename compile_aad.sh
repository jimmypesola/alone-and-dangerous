#!/bin/bash

acme aad.asm

if [ $? -eq 0 ]; then
  gvim aad_symbols.a &
  echo 'aad.asm successfully compiled!'
else
  echo 'Compile error!! Press ENTER to continue'
  read
fi
