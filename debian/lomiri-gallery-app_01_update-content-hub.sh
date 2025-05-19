#!/bin/bash

set -e

# Copyright (C) 2024 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script removes obsolete app names from com.lomiri.content.hub.source
# and com.lomiri.content.hub.destination gsettings user configurations.

peers=("pictures" "videos")

deprecated_appnames=("gallery-app" "gallery.ubports")

for peer in "${peers[@]}"; do

	# Retrieve source peers as shell array
	eval "src_peers_current=$(gsettings get com.lomiri.content.hub.source $peer | sed -e "s/\[/\(/g" -e "s/\]/\)/g" -e "s/',/'/g")"

	# Retrieve destination peers as shell array
	eval "dst_peers_current=$(gsettings get com.lomiri.content.hub.destination $peer | sed -e "s/\[/\(/g" -e "s/\]/\)/g" -e "s/',/'/g")"

	#echo "SRC_CURRENT ($peer): ${src_peers_current[@]}"
	#echo "DST_CURRENT ($peer): ${dst_peers_current[@]}"

	src_peers_updated=()
	dst_peers_updated=()

	for src_peer in ${src_peers_current[@]}; do
		if ! echo " ${deprecated_appnames[@]} " | grep -q " ${src_peer} "; then
			src_peers_updated+=(${src_peer})
		fi
	done

	for dst_peer in ${dst_peers_current[@]}; do
		if ! echo " ${deprecated_appnames[@]} " | grep -q " ${dst_peer} "; then
			dst_peers_updated+=(${dst_peer})
		fi
	done

	#echo "SRC_UPDATED ($peer): ${src_peers_updated[@]}"
	#echo "DST_UPDATED ($peer): ${dst_peers_updated[@]}"

	gsettings set com.lomiri.content.hub.source $peer "$(echo "['${src_peers_updated[@]}']" | sed -e "s/ /', '/g")"
	gsettings set com.lomiri.content.hub.destination $peer "$(echo "['${dst_peers_updated[@]}']" | sed -e "s/ /', '/g")"

done

exit 0
