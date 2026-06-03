#!/bin/bash

LOGFILE=/root/backup/${WSL_DISTRO_NAME}.log

if [ ! -e /root/ ]; then
    echo "ERROR: root is broken, cannot backup ${WSL_DISTRO_NAME}" | tee -a $LOGFILE
    exit
fi

{
    echo ""; echo "=====> Starting ${WSL_DISTRO_NAME} Backup"; echo "=====> "`date '+%F %T'`; echo ""

    echo ""; echo "==> Renaming image files in /root/notes/images/ <=="; echo ""
    cd /root/notes
    mv *.png images
    cd images
    for file in *; do rename 's/[^a-zA-Z0-9._-]/-/g' "$file"; done
    for file in *; do rename 'y/A-Z/a-z/' "$file"; done
    for file in *; do rename 's/[_-]+/-/g' "$file"; done
    cd /

    echo ""; echo "==> Syncing files <=="; echo ""

    mkdir -p /root/backup/${WSL_DISTRO_NAME}/
    # time rsync --archive --verbose --exclude=backup/ /root/ /root/backup/${WSL_DISTRO_NAME}/ 
    time rsync --archive --verbose --exclude=backup/ --exclude=notes/.git/ /root/ "/mnt/c/Users/hshabbir/OneDrive - Evertz Micro Systems/Desktop/${WSL_DISTRO_NAME}"

    echo ""; echo "=====> "`date '+%F %T'` FINISHED ${WSL_DISTRO_NAME}; echo ""
    echo "=====> "`date '+%F %T'` FINISHED ${WSL_DISTRO_NAME} > /root/backup-logs

} 2>&1 | tee ${LOGFILE}
