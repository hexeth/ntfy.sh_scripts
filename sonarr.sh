#!/bin/bash

######### USAGE #############################
# Create a .env file and set variables for  #
# ntfy_token                                #
# ntfy_url                                  #
# sonarr_api                                #
# sonarr_url                                #
# Add script to your sonarr custom scripts  #
# Checking only "Import" for event type     #
#############################################

# Read .env variables
set -o allexport
source $0/.env set
set +o allexport

ntfy_auth="Authorization: Bearer $ntfy_token"
ntfy_topic="sonarr"
ntfy_title="$sonarr_series_title"
ntfy_message=" "

# Check if the event type is "Test".
if [ "$sonarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
# Check if the event type is "Download".
elif [ "$sonarr_eventtype" == "Download" ]; then
  ntfy_tag=tv
  ntfy_title+=" - S"
  ntfy_title+="$sonarr_episodefile_seasonnumber"
  ntfy_title+=":E"
  ntfy_title+="$sonarr_episodefile_episodenumbers"
  ntfy_message+="- "
  ntfy_message+="$sonarr_episodefile_episodetitles"
  ntfy_message+=" ["
  ntfy_message+="$sonarr_episodefile_quality"
  ntfy_message+="]"
fi

# Check if the event type is "Download".
if [ "$sonarr_eventtype" == "Download" ]; then
  # Get the banner image from Sonarr.
  response=$(curl -X GET -H "Content-Type: application/json" -H "X-Api-Key: $sonarr_api_key" "$sonarr_url/$sonarr_series_id")
  banner_image=$(echo "$response" | jq -r '.images[0].remoteUrl')

  # Construct the JSON payload for the Download notification.
  ntfy_post_data()
  {
    cat <<EOF
{
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "attach": "$banner_image",  
  "title": "Sonarr: $sonarr_eventtype",
  "message": "$ntfy_title$ntfy_message",
  "actions": [
    {
      "action": "view",
      "label": "TVDB",
      "url": "https://www.thetvdb.com/?id=$sonarr_series_tvdbid&tab=series",
      "clear": true
    }
  ]
}
EOF
  }
else
  # Construct the JSON payload for the Test notification.
  ntfy_post_data()
  {
    cat <<EOF
{
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Sonarr: $sonarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
  }
fi

# Send a POST request to to ntf.sh with the JSON payload.
curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url
