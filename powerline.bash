#!/bin/bash
# cf. https://gitlab.com/bersace/powerline.bash

if [ -f /.dockerenv ] ; then
	container=docker
fi


# This value is used to hold the return value of the prompt sub-functions. This
# hack avoid calling functions un subprocess to get ret from stdout.
__powerline_retval=""

__powerline_split() {
	local sep="$1"
	local str="$2"
	local OIFS="${IFS-__UNDEF__}"
	IFS="$sep"
	__powerline_retval=(${str})
	if [ "${OIFS}" = "__UNDEF__" ] ; then
		unset IFS
	else
		IFS="${OIFS}"
	fi
}

# Gets the current working directory path, but shortens the directories in the
# middle of long paths to just their respective first letters.
function __powerline_shorten_dir {
	# Break down the local variables.
	local short_pwd
	local dir="$1"

	__powerline_split / "${dir##/}"
	dir_parts=("${__powerline_retval[@]}")
	local number_of_parts=${#dir_parts[@]}

	# If there are less than 6 path parts, then do no shortening.
	if [[ "$number_of_parts" -lt "5" ]]; then
		__powerline_retval="${dir}"
		return
	fi
	# Leave the last 2 part parts alone.
	local last_index="$(( number_of_parts - 3 ))"
	local short_pwd=""

	# Check for a leading slash.
	if [[ "${dir:0:1}" == "/" ]]; then
		# If there is a leading slash, add one to `short_pwd`.
		short_pwd+='/'
	fi

	for i in "${!dir_parts[@]}"; do
		# Append a '/' before we do anything (provided this isn't the first part).
		if [[ "$i" -gt "0" ]]; then
		short_pwd+='/'
		fi

		# Don't shorten the first/last few arguments - leave them as-is.
		if [[ "$i" -lt "2" || "$i" -gt "$last_index" ]]; then
		short_pwd+="${dir_parts[i]}"
		else
		# This means that this path part is in the middle of the path. Our logic
		# dictates that we shorten parts in the middle like this.
		short_pwd+="${dir_parts[i]:0:1}"
		fi
	done

	# Return the resulting short pwd.
	__powerline_retval="$short_pwd"
}

# Parses git status --porcelain=v2 output in an array
function __powerline_parse_git_status_v2() {
	local status="$1"
	# branch infos as returned by status : sha, name, upstream, ahead/behind
	local branch_infos=()
	local dirty=
	local ab
	local detached=

	while read line ; do
		# If line starts with '# ', it's branch info
		if [ -z "${line### branch.*}" ] ; then
		branch_infos+=("${line#\# branch.* }")
		else
		# Else, it's a changes. The worktree is dirty
		dirty=1
		break
		fi
	done <<< "${status}"

	# Try to provide a meaningful info if we are not on a branch.
	if [ "${branch_infos[1]}" == "(detached)" ] ; then
		detached=1
		if desc="$(git describe --tags --abbrev=7 2>/dev/null)" ; then
		branch="${desc}"
		else
		# Au pire des cas, utiliser la SHA du commit courant.
		branch="${branch_infos[0]:0:7}"
		fi
	else
		branch="${branch_infos[1]}"
	fi

	ab="${branch_infos[3]-}"
	__powerline_retval=("${branch}" "${dirty}" "${ab}" "${detached}")
}

# Analyser la sortie v1 de git status --porcelain
function __powerline_parse_git_status_v1() {
	local status="$1"

	local branch
	local detached=
	local dirty=

	__powerline_split $'\n' "$status"
	local lines=("${__powerline_retval[@]}")

	for line in "${lines[@]}" ; do
		if [ "${line}" = "## HEAD (no branch)" ] ; then
		detached=1
		if desc="$(git describe --tags --abbrev=7 2>/dev/null)" ; then
			branch="${desc}"
		else
			# Au pire des cas, utiliser la SHA du commit courant.
			branch="$(git rev-parse --short HEAD)"
		fi
		elif [ -z "${line####*}" ] ; then
		__powerline_split '...' "${line#### }"
		branch="${__powerline_retval[0]}"
		else
		# Les autres lignes sont des lignes de modification.
		dirty=1
		break
		fi
	done

	# On bidonne l'état de synchronisation, faute d'information dans git status.
	local ab="+0 -0"

	__powerline_retval=("${branch}" "${dirty}" "${ab}" "${detached}")
}

# Sélectionner le format de git status à analyser
__powerline_git_version="$(git --version 2>/dev/null)"
__powerline_git_version="${__powerline_git_version#git version }"

# la V2 affiche en une commande l'état de synchronisation.
if printf "2.11.0\n%s" "${__powerline_git_version}" | sort --version-sort --check=quiet ; then
	__powerline_git_cmd=(git status --branch "--porcelain=v2")
	__powerline_git_parser=__powerline_parse_git_status_v2
else
	__powerline_git_cmd=(git status --branch --porcelain)
	__powerline_git_parser=__powerline_parse_git_status_v1
fi


__powerline_get_foreground() {
	local R=$1
	local G=$2
	local B=$3

	# Les terminaux 256 couleurs ont 6 niveaux pour chaque composant. Les
	# valeurs réelles associées aux indices entre 0 et 5 sont les suivantes.
	local values=(0 95 135 175 215 255)
	# Indice de luminosité entre 0 et 9 calculé à partir des composants RGB.
	local luminance
	# On associe une couleur de texte pour chaque niveau de luminosité entre 0
	# et 9. Du gris clair au gris foncé en passant par blanc et noir.
	local foregrounds=(252 253 253 255 255 16 16 235 234 234)

	# cf. https://fr.wikipedia.org/wiki/SRGB#Caract%C3%A9ristiques_principales
	luminance=$(((${values[${R}]} * 2126 + ${values[${G}]} * 7152 + ${values[${B}]} * 722) / 280000))

	# Tronquer la partie décimale et assurer le 0 initial.
	LC_ALL=C printf -v luminance "%.0f" $luminance

	# Récupérer la couleur de texte selon la luminosité
	__powerline_retval=${foregrounds[$luminance]}

	# Afficher le résultat pour test visuel.
	if [ -n "${DEBUG-}" ] ; then
		fg=${__powerline_retval}
		bg=$((16 + 36 * R + 6 * G + B))
		fgbg="$fg/$bg"
		text="${LOGNAME}@${HOSTNAME}"
		printf "\\e[38;5;${fg};48;5;${bg}m $text \\e[0m RGB=%s L=%d %7s" "${RGB}" $luminance $fgbg
	fi
}

# Un segment est une fonction bash préfixé par `__powerline_segment_`. Le retour
# est un table contenant des chaînes au format :
# `<t|p>:<bg_color>:<fg_color>:<text>`. Chaque chaîne correspond à un segment.

__powerline_init_hostname() {
	# Comme le segment hostname est fixe tout au long de l'exécution du
	# shell, on le précalcule.
	local bg
	local rgb
	local fg
	local text
	local hash

	if [ -z "${HOSTNAME-}" ] && [ -f /etc/hostname ] ; then
		read -r HOSTNAME < /etc/hostname
	fi
	USER="${USER-${USERNAME-${LOGNAME-}}}"
	# N'appeler whoami qui si besoin
	if [ -z "${USER}" ] ; then
		USER=$(whoami)
	fi

	text="${USER}@${HOSTNAME-*unknown*}"

	# Calculer la couleur à partir du texte à afficher.
	hash=$(sum <<< "${text}")
	bg=$((1${hash// /} % 215))
	rgb=($((bg / 36)) $(((bg % 36) / 6)) $((bg % 6)))
	bg=$((16+bg))

	# Assurer la lisibilité en déterminant la couleur du texte en fonction de la
	# clareté du fond.
	__powerline_get_foreground "${rgb[@]}"
	fg=${__powerline_retval}

	__powerline_hostname_segment="p:48;5;${bg}:38;5;${fg}:${POWERLINE_HOSTNAME_ICON-}${text}"
}

__powerline_segment_hostname() {
	__powerline_retval=("$__powerline_hostname_segment")
}

__powerline_segment_k8s() {
	__powerline_retval=()
	local seg

	local ctx=$(kubectl config current-context)
	local ns=$(kubectl config view  --output jsonpath='{.contexts[?(@.name == "'"$ctx"'")].context.namespace}')

	if [ "${POWERLINE_K8S_CTX_SHOW:-0}" == "1" ]; then
		seg="${ctx}/${ns}"
	else
		seg="${ns}"
	fi

	__powerline_retval=("p:38;5;27:15:${POWERLINE_K8S_ICON-}$seg")
}

__powerline_segment_openstack() {
	__powerline_retval=()
	if [ -z "${OS_USERNAME-}${OS_APPLICATION_CREDENTIAL_ID-}" ] ; then
		return;
	fi

	local text
	if [ -n "${OS_USERNAME-}" ] ; then
		text="${OS_USERNAME}"
	else
		text="${OS_APPLICATION_CREDENTIAL_ID::8}"
	fi

	text+="@"
	if [ -n "${OS_PROJECT_NAME-}" ] ; then
		text+="${OS_PROJECT_NAME}"
	else
		text+="${OS_AUTH_URL##http*//}"
	fi

	local bg="48;5;251"
	local fg="38;5;236"
	local icon_color="\\[\\e[38;5;160m\\]"
	__powerline_retval=(
		"p:${bg}:${fg}:${icon_color}${POWERLINE_OPENSTACK_ICON-¤} \\[\\e[${fg}m\\]${text}"
	)
}

__powerline_segment_maildir() {
	__powerline_retval=()
	newmails=(${POWERLINE_MAILDIR}/new/*)
	local count="${#newmails[@]}"
	if [ ${newmails[0]} = ${POWERLINE_MAILDIR}'/new/*' ] ; then
		# nullglob option not activated, dir is empty so the glob returns the pattern
		return
	fi
	local bg="48;5;11"
	local fg="38;5;20"
	__powerline_retval=("p:${bg}:${fg}:\\[\\e[1m\\]${POWERLINE_NEWMAIL_ICON-M} ${count}")
}

__powerline_segment_pwd() {
	local colors
	local next_sep
	local short_pwd

	__powerline_shorten_dir "$(dirs +0)"
	local short_pwd="${__powerline_retval}"

	__powerline_split / "${short_pwd}"
	local parts=("${__powerline_retval[@]}")

	__powerline_retval=()
	local sep=p
	for part in "${parts[@]}" ; do
		if [ "${part}" = '~' ] || [ "${part}" = "" ] ; then
		colors="48;5;31:38;5;15"
		next_sep=p  # plain
		else
		colors="48;5;237:38;5;250"
		# Les segments suivants auront un séparateur léger
		next_sep=t  # thin
		fi
		if [ "${part}" = '~' ] ; then
		part=${POWERLINE_HOME_ICON-'~'}
		fi
		if [ -z "${part}" ] ; then
		continue
		fi
		if [ 0 -eq "${#__powerline_retval[@]}" ] ; then
		part="${POWERLINE_PWD_ICON-}${part}"
		fi
		__powerline_retval+=("${sep}:${colors}:${part}")
		sep=${next_sep}
	done
}

__powerline_pyenv_version_name() {
	local dir=$PWD
	__powerline_retval=${PYENV_VERSION-}
	if [ -n "${__powerline_retval}" ] ; then
		return
	fi
	while [ "${dir}" ] ; do
		if [ -f ${dir}/.python-version ] ; then
			if read __powerline_retval < ${dir}/.python-version 2>/dev/null ; then
				# read a trouvé quelque choses (et l'a enregistré), c'est tout bon.
				return
			fi
		fi
		# Sinon, on remonte d'un cran dans l'arborescence.
		dir=${dir%/*}
	done
	# L'existence de ${PYENV_ROOT} a déjà été testée dans le segment "python".
	if [ -f ${PYENV_ROOT}/version ] ; then
		read __powerline_retval < ${PYENV_ROOT}/version 2>/dev/null
	fi
}

__powerline_segment_python() {
	local text

	if [ -v VIRTUAL_ENV ] ; then
		# Les virtualenv python classiques
		text=${VIRTUAL_ENV##*/}
	elif [ -v PYENV_ROOT ] ; then
		# Les virtualenv et versions pyenv
		__powerline_pyenv_version_name
		text=$__powerline_retval
	fi

	if [ -n "${text}" ] ; then
		__powerline_retval=("p:48;5;25:38;5;220:${POWERLINE_PYTHON_ICON-}${text}")
	else
		__powerline_retval=()
	fi
}

__powerline_segment_status() {
	local ec=$1

	if [ "$ec" -eq 0 ] ; then
		__powerline_retval=()
		return
	fi

	__powerline_retval=("p:48;5;1:38;5;234:\\[\\e[1m\\]${POWERLINE_FAIL_ICON-✘ }$ec")
}

__powerline_segment_git() {
	local branch
	local colors
	local ab
	local ab_segment=''
	local detached
	local status_symbol

	if ! status="$(LC_ALL=C.UTF-8 "${__powerline_git_cmd[@]}" 2>/dev/null)" ; then
		__powerline_retval=()
		return
	fi
	$__powerline_git_parser "${status}"
	branch="${__powerline_retval[0]}"
	ab="${__powerline_retval[2]}"
	detached="${__powerline_retval[3]}"

	# Colorer la branche selon l'existance de modifications.
	if [ -n "${__powerline_retval[1]}" ] ; then
		# Modifications présentes.
		branch_fg="38;5;230"
		branch_bg="48;5;124"
		status_symbol="*"
	else
		# Pas de modifications.
		branch_fg="38;5;0"
		branch_bg="48;5;148"
	fi
	icon="\\[\\e[38;5;166m\\]${POWERLINE_GIT_ICON-}"
	colors="${branch_bg}:${branch_fg}"
	anchor=$'\u2693' # Émoji: ⚓
	anchor="${POWERLINE_GIT_DETACHED_ICON-${anchor}}"

	__powerline_retval=("p:${colors}:${icon}\\[\\e[${branch_fg}m\\]${detached:+ ${anchor}}${branch}${status_symbol-}")

	# Compute ahead/behind segment
	if [ -n "${ab##+0*}" ] ; then
		# No +0, the local branch is ahead upstream.
		ab_segment="⬆"
	fi
	if [ -n "${ab##+* -0}" ] ; then
		# No -0, the local branch is behind upstream.
		ab_segment+="⬇"
	fi
	if [ -n "${ab_segment}" ] ; then
		__powerline_retval+=("p:48;5;240:38;5;250:${ab_segment}")
	fi
}


# A render function is a bash function starting with `__powerline_render_`. It puts
# a PS1 string in `__powerline_retval`.

__powerline_render_default() {
	local bg=''
	local fg
	local ps=''
	local segment
	local text
	local separator

	for segment in "${__powerline_segments[@]}" ; do
		__powerline_split ':' "${segment}"
		local infos=("${__powerline_retval[@]}")

		local old_bg=${bg-}
		# Recoller les entrées 2 et suivantes avec :
		printf -v text ":%s" "${infos[@]:3}"
		text=${text:1}
		# Nettoyer le \n ajouté par <<<
		text="${text##[[:space:]]}"
		text="${text%%[[:space:]]}"
		# Sauter les segments vides
		if [ -z "${text}" ] ; then
		continue
		fi

		# D'abord, afficher le chevron avec la transition de fond.
		bg=${infos[1]%%:}
		fg=${infos[2]%%:}
		if [ -n "${old_bg}" ] ; then
		if [ "${infos[0]}" = "t" ] ; then
			# Séparateur léger, même couleurs que le texte
			separator=${POWERLINE_THINSEP-}
			colors="${fg};${bg}"
		else
			separator=${POWERLINE_SEP-}
			colors="${old_bg/48;/38;};${bg}"
		fi
		ps+="\\[\\e[0;${colors}m\\]${separator}"
		fi
		# Ensuite, afficher le segment, coloré
		ps+="\\[\\e[0;${bg}m\\e[${fg}m\\] ${text} "
	done

	# Afficher le dernier chevron, transition du fond vers rien.
	old_bg=${bg-}
	bg='49'
	if [ -n "${old_bg}" ] ; then
		ps+="\\[\\e[${old_bg/48;/38;}m\\e[${bg}m\\]${POWERLINE_SEP-${__default_sep}}"
	fi
	# Changer le titre de la fenêtre ou de l'onglet, par ex. POWERLINE_WINDOW_TITLE="\h"
	if [ -v POWERLINE_WINDOW_TITLE ] ; then
		ps+="\\[\e]0;${POWERLINE_WINDOW_TITLE}\a\\]"
	fi

	# Retourner l'invite de commande
	__powerline_retval="${ps}"
}


# Show dollar line.
__powerline_dollar() {
	local fg
	local last_exit_code=$1
	# Déterminer la couleur du dollar
	if [ $last_exit_code -gt 0 ] ; then
		fg=${ERROR_FG-"1;38;5;161"}
	else
		fg=0
	fi
	# Afficher le dollar sur une nouvelle ligne, pas en mode powerline
	__powerline_retval="\\[\\e[${fg}m\\]\\\$\\[\\e[0m\\] "
}

__update_ps1() {
	local last_exit_code=${1-$?}
	local __powerline_segments=()
	local segname

	for segname in ${POWERLINE_SEGMENTS-hostname pwd status} ; do
		"__powerline_segment_${segname}" $last_exit_code
		__powerline_segments+=("${__powerline_retval[@]}")
	done

	local __ps1=""
	"__powerline_render_${POWERLINE_STYLE-default}"
	__ps1+="${__powerline_retval}"
	__powerline_dollar $last_exit_code
	__ps1+="\n${__powerline_retval}"
	PS1="${__ps1}"
}

__powerline_autosegments() {
	# Détermine les segments pertinent pour l'environnement.
	__powerline_retval=()

	local remote;
	remote=${SSH_CLIENT-${SUDO_USER-${container-}}}
	if [ -n "${remote}" ] ; then
		__powerline_retval+=(hostname)
	fi

	if [ -v POWERLINE_MAILDIR ] ; then
		__powerline_retval+=(maildir)
	fi

	__powerline_retval+=(pwd)

	if type -p python >/dev/null ; then
		__powerline_retval+=(python)
	fi

	if type -p git >/dev/null ; then
		__powerline_retval+=(git)
	fi

	if type -p python >/dev/null ; then
		__powerline_retval+=(openstack)
	fi

	if type -p kubectl >/dev/null && [ -f "${KUBECONFIG-${HOME}/.kube/config}" ]; then
		__powerline_retval+=(k8s)
	fi

	__powerline_retval+=(status)
}

__powerline_autoicons() {
	# Configurer les séparateurs
	local mode
	mode=${POWERLINE_ICONS-auto}
	if [ "${mode}" = "auto" ] ; then
		case "$TERM" in
		*256color) mode=powerline;;
		*) mode=compat;:
		esac
	fi

	case "${mode}" in
		compat)
			: ${POWERLINE_SEP:=$'\u25B6'}
			: ${POWERLINE_THINSEP:=$'\u276F'}
			: ${POWERLINE_K8S_ICON:=*}
			;;
		powerline)
			: ${POWERLINE_SEP:=$'\uE0B0'}
			: ${POWERLINE_THINSEP:=$'\uE0B1'}
			: ${POWERLINE_GIT_ICON:=$'\uE0A0 '}  # de la police Powerline
			: ${POWERLINE_K8S_ICON:=$'\u2638 '}
			;;
		flat)
			: ${POWERLINE_SEP:=}
			: ${POWERLINE_THINSEP:=}
			;;
		icons-in-terminal)
			: ${POWERLINE_SEP:=$'\uE0B0'}
			: ${POWERLINE_THINSEP:=$'\uE0B1'}
			: ${POWERLINE_NEWMAIL_ICON:=$'\uE0E4'}
			: ${POWERLINE_FAIL_ICON:=$'\uF057 '}
			: ${POWERLINE_GIT_DETACHED_ICON:=$'\uF0C1 '}
			: ${POWERLINE_GIT_ICON:=$'\uEDCE  '}
			: ${POWERLINE_HOSTNAME_ICON:=$'\uE4BA  '}
			: ${POWERLINE_OPENSTACK_ICON:=$'\uE574 '}
			: ${POWERLINE_PWD_ICON:=$'\uE015  '}
			: ${POWERLINE_PYTHON_ICON:=$'\uEE10 '}
			: ${POWERLINE_K8S_ICON:=$'\u2638 '}
			;;
		*)
			echo "POWERLINE_ICONS=${mode} inconnu." >&2
			;;
	esac
}

__powerline_init_segments() {
	local segment
	local init
	for segment in ${POWERLINE_SEGMENTS} ; do
		init=__powerline_init_$segment
		if type -t $init &> /dev/null ; then
			$init
		fi
	done
}

# Initialiser les segments à partir de l'environnement.
__powerline_autoicons
__powerline_autosegments
: "${POWERLINE_SEGMENTS:=${__powerline_retval[*]}}"
__powerline_init_segments

if [ -z "${PROMPT_COMMAND-}" ] ; then
	PROMPT_COMMAND='__update_ps1 $?'
fi
