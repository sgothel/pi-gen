#!/bin/bash

zfs create -o encryption=on -o keyformat=passphrase $1



