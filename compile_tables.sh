#!/bin/bash

acme coretables.asm
if [ $? -eq 0 ]; then
	gvim coretables_labels.a
	echo 'coretables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme outdoortables.asm
if [ $? -eq 0 ]; then
	gvim outdoortables_labels.a
	echo 'outdoortables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme d0tables.asm
if [ $? -eq 0 ]; then
	gvim d0tables_labels.a
	echo 'd0tables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi
