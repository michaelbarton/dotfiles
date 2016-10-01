log_jira_work(){
	REQUEST='{ "timeSpentSeconds": 1800 }'
	curl \
		--user mbarton:$(/Users/mbarton/.bin/get-pass jgi.jira) \
		--request POST \
		--header "Content-Type: application/json" \
		--data "$REQUEST" \
		https://issues.jgi-psf.org/rest/api/2/issue/$1/worklog/
		> $@
}

while :; do # Loop until valid input is entered or Cancel is pressed.
    name=$(osascript -e 'Tell application "System Events" to display dialog "Enter the project name:" default answer ""' -e 'text returned of result' 2>/dev/null)
    if (( $? )); then exit 1; fi  # Abort, if user pressed Cancel.
    name=$(echo "$name" | sed 's/^ *//' | sed 's/ *$//')  # Trim leading and trailing whitespace.
    if [[ -z "$name" ]]; then
        # The user left the project name blank.
        osascript -e 'Tell application "System Events" to display alert "You must enter a non-blank project name; please try again." as warning' >/dev/null
        # Continue loop to prompt again.
    else
	log_jira_work $name
        break
    fi
done
