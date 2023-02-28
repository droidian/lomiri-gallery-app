#!/bin/sh

old_name=com.ubuntu.gallery
name=gallery.ubports
for base in "${XDG_CONFIG_HOME:-${HOME}/.config}" \
    "${XDG_DATA_HOME:-${HOME}/.local/share}" \
    "${XDG_CACHE_HOME:-${HOME}/.cache}"; do
    if [ -d "${base}/${old_name}" ]; then
        mv -T "${base}/${old_name}" \
            "${base}/${name}" 2>/dev/null
        fi
done

/usr/share/lomiri-gallery-app/lomiri-gallery-app-migrate.py

exit 0
