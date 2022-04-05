#!/bin/sh
set -e
cd "$(dirname $0)"

PRINTER_HOST=mushu

scp -r $PRINTER_HOST:~/klipper_config/ .
rm klipper_config/printer-202*.cfg klipper_config/.moonraker*.bkp # delete backups

scp -r $PRINTER_HOST:~/klipper/.config-* .

ssh $PRINTER_HOST "cd klipper && git diff -u" >klipper.patch
