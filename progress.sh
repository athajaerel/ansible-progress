#!/usr/bin/env bash
set -euo pipefail

# put LOGFILE= and PLAYBOOK= in config file... won't work from other dirs so not awesome
[ -e ./config ] && . ./config

ERMSG="No match found. Running off main playbook?"

# TODO: delete at end of playbook run
# generate roles list if not already done
[ ! -e /tmp/roles.txt ] && ansible-playbook --list-tasks ${PLAYBOOK} 2>/dev/null | awk '/ : / {print $1}' | uniq >/tmp/roles.txt

NUM_ROLES=$(wc -l </tmp/roles.txt)
echo "Found ${NUM_ROLES} roles.
"

# get current and previous roles
ROLES=$(grep '|  TASK' ${LOGFILE} | cut -d\  -f 8 | grep -v Gathering | uniq | cut -c 2- | tail -1)

# BUG: doesn't find matches when running roles off the main playbook
# BUG: doesn't find matches when roles/plays are skipped
# find window of roles matching current and previous
WINDOW=$(ag -A5 -B5 "${ROLES}" /tmp/roles.txt || true)

if [[ "x${WINDOW}" == "x" ]]; then
	echo "${ERMSG}"
fi

# improve window
C=0
for LINE in ${WINDOW}; do
	if [ ${C} -eq 5 ]; then
		echo ">> ${LINE}"
	else
		echo "   ${LINE}"
	fi
	C=$((${C}+1))
done
