#!/bin/bash

if [ ! -f aad.d64 ]; then
	./pack_aad.sh
fi
./run_vice.sh aad.d64
