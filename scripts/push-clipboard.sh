#!/usr/bin/env bash

# source: https://github.com/feschber/lan-mouse/issues/258#issuecomment-3117557919
# changes:
#   - add source link (github issue #258)
#   - replace "#!/bin/bash" shebang with "#!/usr/bin/env bash"
#   - replace WAYLAND_DISPLAY from "wayland-0" to "wayland-1"
#   - rename script from "pushclipboard" to "push-clipboard.sh"

declare -a timeout
declare -a read_t
declare -a ssh_options
ssh_key=
buildline=0
gfxsys=

usage() {
cat <<HELP
Usage:
	$0 [ -v ] [ -t {n} ] [ -4 | -6 ] [ -x | -w ] [ -i sshkey ] {target computer}
Copies the content of Wayland's clipboard to the target computer

Options:
	-t {n}	timeout for n seconds
	-4	connect SSH over IPv4
	-6	connect SSH over IPv6
	-w	use Wayland (auto-detected)
	-x	use X11 (fall-back)
	-v	verbose
	-i [sshkey]	Use sshkey as identity
	-f	build authorized_keys' forced-command line
HELP
	exit "$1"
}

# Process options
while getopts "t:46wxvi:f-:h" o; do
	case "${o}" in
		t)
			timeout=( timeout "${OPTARG}" )
			read_t=( '-t' "${OPTARG}" )
			;;
		4|6|v)	ssh_options+=( "-${o}" )	;;
		i)	ssh_key="${OPTARG}"
			if [[ ! -r "${ssh_key}" ]]; then
				echo "Cannot read ${ssh_key}" 1>&2
				exit 2
			else
				echo "Using ${ssh_key}"
			fi
			;;
		f)	buildline=1	;;
		w)	gfxsys=wayland	;;
		x)	gfxsys=x11	;;
		h)	usage 0	;;
		-)	case "${OPTARG}" in
				help)	usage 0	;;
				*)	printf 'Bad option %s\n\n' "${OPTARG}"; usage 2	1>&2	;;
			esac
			;;
		*)	printf 'Bad option %s\n\n' "${o}"; usage 2	1>&2	;;
	esac
done
shift $((OPTIND-1))

if [[ -z "${1}" ]] && (( ! buildline )); then
	usage 2
else
	target="${1}"
fi


# Search clipboard-specific SSH key
if [[ -z "${ssh_key}" ]]; then
	search_ssh_key=( ~/.ssh/id_*_clipboard )
	if [[ -r "${search_ssh_key[0]}" ]]; then
		ssh_key="${search_ssh_key[0]}"
		printf 'Found key:\t%s\n' "${ssh_key}"
	fi
fi

# Build forced command line for the authorized keys config
if (( buildline )); then
	echo '# forced command in ~/.ssh/authorized_keys'
	if [[ -z "${ssh_key}" ]]; then
		echo 'No key available to build a forced-command line' 1>&2
		exit 1
	fi
	echo "# Wayland"
	printf "command=\"/usr/bin/env WAYLAND_DISPLAY='wayland-1' wl-copy; echo copied\",no-agent-forwarding,no-pty,no-X11-forwarding %s\n" "$(< "${ssh_key%.pub}.pub" )"
	echo "# X11"
	printf 'command="xclip -display :0 -in -rmlastnl -selection clipboard; echo copied",no-agent-forwarding,no-pty,no-X11-forwarding %s\n' "$(< "${ssh_key%.pub}.pub" )"
	exit 0
fi


# Auto-detect display server
if [[ -n "${gfxsys}" ]]; then
	:
elif [[ "${XDG_SESSION_TYPE,,}" =~ wayland|x11 ]]; then
	gfxsys="${XDG_SESSION_TYPE,,}"
elif [[ -n "${WAYLAND_DISPLAY}" ]]; then
	gfxsys=wayland
	echo "Wayland detected"
elif [[ -n "${DISPLAY}" ]]; then
	gfxsys=x11
	echo "X11 detected"
fi

# Display-specific command
clipcmd=
if [[ "${gfxsys,}" == "x11" ]]; then
	clipcmd=( xclip -out -rmlastnl -selection clipboard ) # -display :0
else
	clipcmd=( wl-paste --no-newline )
fi


# Copy-Paste time!
echo "Pushing clipboard to ${target} using ${clipcmd[0]} on ${gfxsys^}..."

while read ${read_t:+ "${read_t[@]}" } -r result; do
	ssh_pid="$!"
	echo -e "${result}"
	kill -TERM "${ssh_pid}"
	exit 0
done < <(
	exec	\
		${timeout:+ "${timeout[@]}" }	\
		ssh	\
			${ssh_options:+ "${ssh_options[@]}" }	\
			${ssh_key:+ -o"ControlPath none" -o"IdentitiesOnly yes" -i "${ssh_key}"}	\
			"${target}"	\
			--	\
				/usr/bin/env WAYLAND_DISPLAY="wayland-1" wl-copy \;	\
				echo copied	\
			< <( "${clipcmd[@]}" )	\
	|| echo "fail ?" >&2
)

echo "timeout" >&2
exit 1
