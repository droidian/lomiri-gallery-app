#!/usr/bin/python3

import os
import shutil
import sqlite3
import sys
from pathlib import Path

organization = "gallery.ubports"
application = "gallery.ubports"
old_application = "com.ubuntu.gallery"
camera_application = "camera.ubports"
old_camera_application = "com.ubuntu.camera"

xdg_config_home = Path(os.environ.get("XDG_CONFIG_HOME",
                                      Path.home() / ".config"))
xdg_data_home = Path(
    os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")
)
old_config_file = xdg_config_home / organization / f"{old_application}.conf"
new_config_file = xdg_config_home / organization / f"{application}.conf"
if old_config_file.is_file() and not new_config_file.exists():
    old_config_file.rename(new_config_file)

old_pictures_path = Path.home() / "Pictures" / old_camera_application
pictures_path = Path.home() / "Pictures" / camera_application
if old_pictures_path.is_dir() and not pictures_path.exists():
    old_pictures_path.rename(pictures_path)

db_file = xdg_data_home / organization / "database" / "gallery.sqlite"
if db_file.is_file():
    con = sqlite3.connect(db_file)
    with con:
        con.execute(
            f"UPDATE MediaTable SET filename = replace(filename, "
            f"'/{old_camera_application}/', '/{camera_application}/')",
        )
    con.close()

if len(sys.argv) > 1:
    os.execvp(sys.argv[1], sys.argv[1:])
