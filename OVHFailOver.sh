#!/bin/sh
#
#
#	FailOver OCF RA. Does nothing except track its own state.
#	Use it only as a testing tool or example for how to write
#	a resource agent.
#
# Copyright (c) 2004 SUSE LINUX AG, Lars Marowsky-Bree
#                    All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#

#######################################################################
# Initialization:

: ${OCF_FUNCTIONS_DIR=${OCF_ROOT}/lib/heartbeat}
. ${OCF_FUNCTIONS_DIR}/ocf-shellfuncs

# Parameter defaults

OCF_RESKEY_state_default="${HA_RSCTMP}/FailOver-${OCF_RESOURCE_INSTANCE}.state"
OCF_RESKEY_fake_default="failover"

: ${OCF_RESKEY_state=${OCF_RESKEY_state_default}}
: ${OCF_RESKEY_fake=${OCF_RESKEY_fake_default}}

#######################################################################

meta_data() {
	cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="FailOver">
<version>1.0</version>

<longdesc lang="en">
Script ran on failover
</longdesc>
<shortdesc lang="en">Example stateless resource agent</shortdesc>

<parameters>
<parameter name="state" unique="1">
<longdesc lang="en">
Location to store the resource state in.
</longdesc>
<shortdesc lang="en">State file</shortdesc>
<content type="string" default="${OCF_RESKEY_state_default}" />
</parameter>

<parameter name="fake" unique="0">
<longdesc lang="en">
Fake attribute that can be changed to cause a reload
</longdesc>
<shortdesc lang="en">Fake attribute that can be changed to cause a reload</shortdesc>
<content type="string" default="${OCF_RESKEY_fake_default}" />
</parameter>

</parameters>

<actions>
<action name="start"        timeout="20s" />
<action name="stop"         timeout="20s" />
<action name="monitor"      timeout="20s" interval="10s" depth="0" />
<action name="reload"       timeout="20s" />
<action name="migrate_to"   timeout="20s" />
<action name="migrate_from" timeout="20s" />
<action name="meta-data"    timeout="5s" />
<action name="validate-all"   timeout="20s" />
</actions>
</resource-agent>
END
}

#######################################################################

failover_usage() {
	cat <<END
usage: $0 {start|stop|monitor|migrate_to|migrate_from|validate-all|meta-data}

Expects to have a fully populated OCF RA-compliant environment set.
END
}

failover_start() {
    failover_monitor
    if [ $? =  $OCF_SUCCESS ]; then
	python3 /usr/local/bin/script.py
	return $OCF_SUCCESS
    fi
    touch ${OCF_RESKEY_state}
}

failover_stop() {
    failover_monitor
    if [ $? =  $OCF_SUCCESS ]; then
	rm ${OCF_RESKEY_state}
    fi
    return $OCF_SUCCESS
}

failover_monitor() {
	# Monitor _MUST!_ differentiate correctly between running
	# (SUCCESS), failed (ERROR) or _cleanly_ stopped (NOT RUNNING).
	# That is THREE states, not just yes/no.
	
	if [ -f ${OCF_RESKEY_state} ]; then
	    return $OCF_SUCCESS
	fi
	if false ; then
		return $OCF_ERR_GENERIC
	fi

	if ! ocf_is_probe && [ "$__OCF_ACTION" = "monitor" ]; then
		# set exit string only when NOT_RUNNING occurs during an actual monitor operation.
		ocf_exit_reason "No process state file found"
	fi
	return $OCF_SUCCESS
}

failover_validate() {
    
    # Is the state directory writable? 
    state_dir=`dirname "$OCF_RESKEY_state"`
    touch "$state_dir/$$"
    if [ $? != 0 ]; then
	ocf_exit_reason "State file \"$OCF_RESKEY_state\" is not writable"
	return $OCF_ERR_ARGS
    fi
    rm "$state_dir/$$"

    return $OCF_SUCCESS
}

case $__OCF_ACTION in
meta-data)	meta_data
		exit $OCF_SUCCESS
		;;
start)		failover_start;;
stop)		failover_stop;;
monitor)	failover_monitor;;
migrate_to)	ocf_log info "Migrating ${OCF_RESOURCE_INSTANCE} to ${OCF_RESKEY_CRM_meta_migrate_target}."
	        failover_stop
		;;
migrate_from)	ocf_log info "Migrating ${OCF_RESOURCE_INSTANCE} from ${OCF_RESKEY_CRM_meta_migrate_source}."
	        failover_start
		;;
reload)		ocf_log info "Reloading ${OCF_RESOURCE_INSTANCE} ..."
		;;
validate-all)	failover_validate;;
usage|help)	failover_usage
		exit $OCF_SUCCESS
		;;
*)		failover_usage
		exit $OCF_ERR_UNIMPLEMENTED
		;;
esac
rc=$?
ocf_log debug "${OCF_RESOURCE_INSTANCE} $__OCF_ACTION : $rc"
exit $rc

