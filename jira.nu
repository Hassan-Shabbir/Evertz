let $yml = "~/status.yml"

let $mytodo = (gawk '/TODO|EVRT|CSTM|DONE/' ~/notes/todo.org | parse --regex '\[(?P<ticket>WBD-[0-9]*)\]\]:' | get ticket) # TODO uses gawk, not portable
def jiraSearch [jql: string] {
	http get -H ["Authorization" "Basic " "Content-Type" "application/json"] $"https://evertz.atlassian.net/rest/api/3/search?jql=project=WBD&($jql)"
}

def jira [path: string] {
	http get -H ["Authorization" "Basic " "Content-Type" "application/json"] $"https://evertz.atlassian.net/rest/api/3/issue/($path)"
}

def filterFields [] { $in | select key fields.customfield_14328.value fields.summary fields.status.name fields.assignee.displayName fields.customfield_14330.content?.0.content.2?.text fields.customfield_14330.content?.0.content.4?.text fields.customfield_14301.0.name fields.description.content.0.content.0.text? fields.reporter.displayName fields.reporter.emailAddress? fields.lastViewed fields.customfield_14310.currentStatus.statusDate.iso8601 fields.components.0.name fields.components.1?.name fields.updated fields.created fields.customfield_14326.0.value fields.customfield_14335.completedCycles?.0?.breachTime.iso8601 fields.customfield_14335.completedCycles?.0?.breached fields.customfield_14335.completedCycles?.0?.remainingTime.friendly fields.customfield_14335.ongoingCycle?.breachTime.iso8601 fields.customfield_14335.ongoingCycle?.breached fields.customfield_14335.ongoingCycle?.remainingTime.friendly fields.customfield_14334.completedCycles?.0?.breachTime.iso8601 fields.customfield_14334.completedCycles?.0?.breached fields.customfield_14334.completedCycles?.0?.remainingTime.friendly fields.customfield_14334.ongoingCycle?.breachTime.iso8601 fields.customfield_14334.ongoingCycle?.breached fields.customfield_14334.ongoingCycle?.remainingTime.friendly fields.customfield_14336.completedCycles?.0?.breachTime.iso8601 fields.customfield_14336.completedCycles?.0?.breached fields.customfield_14336.completedCycles?.0?.remainingTime.friendly fields.customfield_14336.ongoingCycle?.breachTime.iso8601 fields.customfield_14336.ongoingCycle?.breached fields.customfield_14336.ongoingCycle?.remainingTime.friendly fields.customfield_14337.completedCycles?.0?.breachTime.iso8601 fields.customfield_14337.completedCycles?.0?.breached fields.customfield_14337.completedCycles?.0?.remainingTime.friendly fields.customfield_14337.ongoingCycle?.breachTime.iso8601 fields.customfield_14337.ongoingCycle?.breached fields.customfield_14337.ongoingCycle?.remainingTime.friendly }

	# ticket
	# severity
	# summary
	# status
	# assignee
	# progress_summary_1
	# progress_summary_2
	# organization
	# body
	# reporter
	# reporter_email
	# last_viewed
	# last_state_changed
	# components_1
	# components_2
	# updated
	# created
	# location
	# past_response_breach_time
	# past_response_breached
	# past_response_remaining_time
	# current_response_breach_time
	# current_response_breached
	# current_response_remaining_time
	# past_restore_breach_time
	# past_restore_breached
	# past_restore_remaining_time
	# current_restore_breach_time
	# current_restore_breached
	# current_restore_remaining_time
	# past_resolve_hardware_breach_time
	# past_resolve_hardware_breached
	# past_resolve_hardware_remaining_time
	# current_resolve_hardware_breach_time
	# current_resolve_hardware_breached
	# current_resolve_hardware_remaining_time
	# past_resolve_software_breach_time
	# past_resolve_software_breached
	# past_resolve_software_remaining_time
	# current_resolve_software_breach_time
	# current_resolve_software_breached
	# current_resolve_software_remaining_time


def filterCommentFields [] { $in | select comments.0?.author.displayName comments.0?.updated comments.0?.body.content.0?.content.0.text? comments.0?.body.content.1?.content.0.text? comments.1?.author.displayName comments.1?.updated comments.1?.body.content.0?.content.0.text? comments.1?.body.content.1?.content.0.text? comments.2?.author.displayName comments.2?.updated comments.2?.body.content.0?.content.0.text? comments.2?.body.content.1?.content.0.text? }

	# comment_1_author
	# comment_1_time
	# comment_1_1
	# comment_1_2
	# comment_2_author
	# comment_1_time
	# comment_2_1
	# comment_2_2
	# comment_3_author
	# comment_1_time
	# comment_3_1
	# comment_3_2

def renameColumnNames [] { $in | rename ticket severity summary status assignee progress_summary_1 progress_summary_2 organization body reporter reporter_email last_viewed last_state_changed components_1 components_2 updated created location past_response_breach_time past_response_breached past_response_remaining_time current_response_breach_time current_response_breached current_response_remaining_time past_restore_breach_time past_restore_breached past_restore_remaining_time current_restore_breach_time current_restore_breached current_restore_remaining_time past_resolve_hardware_breach_time past_resolve_hardware_breached past_resolve_hardware_remaining_time current_resolve_hardware_breach_time current_resolve_hardware_breached current_resolve_hardware_remaining_time past_resolve_software_breach_time past_resolve_software_breached past_resolve_software_remaining_time current_resolve_software_breach_time current_resolve_software_breached current_resolve_software_remaining_time comment_1_author comment_1_time comment_1_1 comment_1_2 comment_2_author comment_1_time comment_2_1 comment_2_2 comment_3_author comment_1_time comment_3_1 comment_3_2 toc toc_sync }

def moveColumns [] { $in | move comment_1_author comment_1_time comment_1_1 comment_1_2 comment_2_author comment_1_time comment_2_1 comment_2_2 comment_3_author comment_1_time comment_3_1 comment_3_2 --after organization }

def updateSeverity [] { $in | update severity {|r| $r.severity | parse --regex "(?P<severity_simple>L.) -" | get severity_simple.0 } }
def addStatusCode  [] { $in | insert status_code {|r| $r.status | parse --regex "(?P<status_code>(Customer|Done|Dev|progress))" | get status_code.0 } } # TODO remove this?


rm -rf status.yml

for ticket in $mytodo { 
	[( 
		(jira $"($ticket)" | filterFields) 
		| merge (jira $"($ticket)/comment?orderBy=-created" | filterCommentFields) 
		| merge (jira $"($ticket)/properties/k15t.backbone.syncinfo" | select value.remoteIssueKey.0 value.issueSyncStatus.0) 
		| renameColumnNames 
		| moveColumns 
		| updateSeverity 
		| addStatusCode
	)] # WARNING!!! No empty line allowed after the list
	| to yaml 
	| save --append status.yml 
}

#open status.yml | sort-by severity | explore 


############################################################################################################################################################
############################################################################################################################################################
############################################################################################################################################################


use std assert
# JIRA Command Line Interface:
# Grabs data from JIRA using its API, and saves it to status.yml.
# Then lets you quickly and effortlessly query that data.
#
# NOTE: downloading all tickets from JIRA can take some time.
#
# WARNING: severities required currently to return any results.
#
# Examples: 
#   > j # query all WBD tickets, yes it's that easy!
#   > j -12 # query all L1 and L2 tickets
#   > j -a [p j w] # get all tickets assigned to Harbir, Jon and Will
def j [
	--refresh (-r) # force a refresh on the tickets; WARNING: may take a while # TODO force download if file doesn't exist
	--ticket (-t): string # the ticket to filter for	
	-1 # filter for L1 severity, can be combined, default all
	-2 # filter for L2 severity, can be combined, default all
	-3 # filter for L3 severity, can be combined, default all
	-4 # filter for L4 severity, can be combined, default all
	--search: string # text that the summary or body contains
	--status (-s): list<string> # list of the following characters: [c]ustomer, [d]one, [m]ediator, [p]rogress # TODO fill for all statuses
	--assignee (-a): list<string> # list of the following characters: [e]dgar, [p]awar, [s]habbir, [j]on, [m]ike, [r]yan, [w]ill
	--missing-progress (-p) # filter for missing progress summaries # TODO gets stuck
	--organization (-o): list<string> # list of the following characters: # TODO ask Baarda
	--mediator (-m) # filter for mediator components
	--updated (-u): duration # supported units: 1min, 1hr, 1day, 1wk # TODO
	--created (-c): duration # supported units: 1min, 1hr, 1day, 1wk # TODO
	--backbone (-b) # filters for unsynced backbone tickets
	--interactive (-i)
] {
	#def refreshTickets [] {if ( (((date now) - (ls status.nu | get modified.0)) > 24hr) or $refresh ) { echo TODO } else { echo TODO } }
	def ticketFilter [] { # TODO make input list of literal ticket values
		assert ($ticket != null)
		if $ticket == null {
			$in
		} else {
			$in | where ticket =~ $ticket
		}
	}
	def severityFilter [] { 
		#let $severities = ( if ( (if $1 { ['L1'] } else { [''] }) ++ (if $2 { ['L2'] } else { [''] }) ++ (if $3 { ['L3'] } else { [''] }) ++ (if $4 { ['L4'] } else { [''] })) == [''] { ['L1' 'L2' 'L3' 'L4'] } )
		#| where severity in $severities
				
		#let $severities = ( (['']) ++ (if $1 { ['L1'] }) ++ (if $2 { ['L2'] }) ++ (if $3 { ['L3'] }) ++ (if $4 { ['L4'] }) ) #TODO
		
		#mut $severities = ['']
		#if $1 { $severities ++= ['L1'] }
		#if $2 { $severities ++= ['L2'] }
		#if $3 { $severities ++= ['L3'] }
		#if $4 { $severities ++= ['L4'] }
		#if $severities == [''] {
			#$in
		#} else {
			#$in | where severity in $severities
		#}
		
		let $severities = ( (if $1 { ['L1'] } else { [''] }) ++ (if $2 { ['L2'] }) ++ (if $3 { ['L3'] }) ++ (if $4 { ['L4'] }) ) #TODO
		$in 
		| where severity in $severities
		
	}
	def searchFilter [] {
		if $search == null {
			$in
		} else {
			#$in | where summary =~ $"(?i)($search)" or body =~ $"(?i)($search)"
			$in | where summary =~ $search or body =~ $search
		}
	}
	def statusFilter [] {
		if $status == null {
			$in
		} else {
			mut $statuses = []
			for $elem in $status { # TODO fill out all status
				if $elem == "c" {
					$statuses ++= ['Waiting on Customer']
				}
				if $elem == "d" {
					$statuses ++= ['Done']
				}
				if $elem == "m" {
					$statuses ++= ['Waiting on Mediator Dev']
				}
				if $elem == "p" {
					$statuses ++= ['Work in progress']
				}
			}
			$in | where status in $statuses
		}
	}
	def assigneeFilter [] {
		if $assignee == null {
			$in
		} else {
			mut $assignees = []
			for $elem in $assignee { # TODO fill out all assignee
				if $elem == "e" {
					$assignees ++= ['Edgar Oo']
				}
				if $elem == "p" {
					$assignees ++= ['Harbir Pawar']
				}
				if $elem == "s" {
					$assignees ++= ['Hassan Shabbir']
				}
				if $elem == "j" {
					$assignees ++= ['Jon Nino']
				}
				if $elem == "m" {
					$assignees ++= ['Mike Black']
				}
				if $elem == "r" {
					$assignees ++= ['Ryan Cooke']
				}
				if $elem == "w" {
					$assignees ++= ['Will Chernichen']
				}
			}
			$in | where assignee in $assignees
		}
	}
	def missingProgressFilter [] { # TODO WARNING!!!!! this seems like it gets stuck in this option?
		if $missing_progress == null {
			$in
		} else {
			$in
		}
	}
	def mediatorFilter [] { # TODO WARNING!!!!!! this seems like it gets stuck in this option?
		if $mediator == null {
			$in
		} else {
			$in | where components_1 in ['Mediator' 'Overture'] or components_2 in ['Mediator' 'Overture']
		}
	}
	def backboneFilter [] { # TODO WARNING!!!!!! this seems like it gets stuck in this option?
		if ($backbone == false) { 
			$in 
		} else {
			$in | where toc_sync != 'UP_TO_DATE' 
		}
	}
	def interactiveCommand [] {
		#assert ($interactive == false)
		if ($interactive == false) {
			$in
		} else {
			$in | explore
		}
	}
	# TODO refreshTickets
	# TODO sort results: `sort-by severity assignee`
	#open status.yml | ticketFilter | severityFilter | searchFilter | statusFilter | assigneeFilter | backboneFilter | mediatorFilter | backboneFilter
	open status.yml | ticketFilter | severityFilter | interactiveCommand
}

########################################################################################################################

def j [ 
	--tickets (-t): list<string> # the tickets to filter for	
] {
	def ticketFilter [] { # TODO make input list of literal ticket values
		if ($tickets == null) {
			$in
		} else {
			$in | where ticket in $tickets
		}
	}
	open status.yml | ticketFilter
}


def j [ -1 -2 -3 -4 ] { # WARNING!!! REQUIRES AT LEAST ONE ARG!
	def severityFilter [] { 
		let $severities = ( (if $1 { ['L1'] } else { [''] }) ++ (if $2 { ['L2'] }) ++ (if $3 { ['L3'] }) ++ (if $4 { ['L4'] }) ) #TODO
		$in 
		| where severity in $severities
	}
	open status.yml | severityFilter
}


def j [
	--summary: string # the text to filter for in the summary
] {
	def searchFilter [] {
		if ($search == null) {
			$in
		} else {
			$in | where summary =~ $search
		}
	}
	open status.yml | searchFilter
}


def j [
	--status (-s): list<string> # list of the following characters: [c]ustomer, [d]one, [m]ediator, [p]rogress # TODO fill for all statuses
] {
	def statusFilter [] {
		if $status == null {
			$in
		} else {
			mut $statuses = []
			for $elem in $status { # TODO fill out all status
				if $elem == "c" {
					$statuses ++= ['Waiting on Customer']
				}
				if $elem == "d" {
					$statuses ++= ['Done']
				}
				if $elem == "m" {
					$statuses ++= ['Waiting on Mediator Dev']
				}
				if $elem == "p" {
					$statuses ++= ['Work in progress']
				}
			}
			$in | where status in $statuses
		}
	}
	open status.yml | statusFilter
}


def j [
	--assignee (-a): list<string> # list of the following characters: [e]dgar, [p]awar, [s]habbir, [j]on, [m]ike, [r]yan, [w]ill
] {
	def assigneeFilter [] {
		if $assignee == null {
			$in
		} else {
			mut $assignees = []
			for $elem in $assignee { # TODO fill out all assignee
				if $elem == "e" {
					$assignees ++= ['Edgar Oo']
				}
				if $elem == "p" {
					$assignees ++= ['Harbir Pawar']
				}
				if $elem == "s" {
					$assignees ++= ['Hassan Shabbir']
				}
				if $elem == "j" {
					$assignees ++= ['Jon Nino']
				}
				if $elem == "m" {
					$assignees ++= ['Mike Black']
				}
				if $elem == "r" {
					$assignees ++= ['Ryan Cooke']
				}
				if $elem == "w" {
					$assignees ++= ['Will Chernichen']
				}
			}
			$in | where assignee in $assignees
		}
	}
	open status.yml | assigneeFilter
}


def j [
	--missing-progress (-p) # filter for missing progress summaries # TODO gets stuck
] {
	def missingProgressFilter [] { # TODO WARNING!!!!! this seems like it gets stuck in this option?
		if ($missing_progress == null) {
			$in
		} else {
			$in | where progress_summary_1 == null and progress_summary_2 == null
		}
	}
	open status.yml | missingProgressFilter
}


def j [
	--organization (-o): list<string> # list of the following characters: # TODO ask Baarda
] {
	def organizationFilter [] {
		i
	}
	open status.yml | ticketFilter | severityFilter | interactiveCommand
}
	def assigneeFilter [] {
		if $assignee == null {
			$in
		} else {
			mut $assignees = []
			for $elem in $assignee { # TODO fill out all assignee
				if $elem == "e" {
					$assignees ++= ['Edgar Oo']
				}
				if $elem == "p" {
					$assignees ++= ['Harbir Pawar']
				}
				if $elem == "s" {
					$assignees ++= ['Hassan Shabbir']
				}
				if $elem == "j" {
					$assignees ++= ['Jon Nino']
				}
				if $elem == "m" {
					$assignees ++= ['Mike Black']
				}
				if $elem == "r" {
					$assignees ++= ['Ryan Cooke']
				}
				if $elem == "w" {
					$assignees ++= ['Will Chernichen']
				}
			}
			$in | where assignee in $assignees
		}
	}
	open status.yml | assigneeFilter
}

