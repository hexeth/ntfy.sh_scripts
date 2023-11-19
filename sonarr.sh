#!/bin/bash
set -o allexport
source .env set
set +o allexport

# Set the API key and endpoint URL 
ntfy_auth="Authorization: Bearer $ntfy_token"
ntfy_topic="sonarr"
ntfy_title="$sonarr_series_title"
ntfy_message=" "
if [ "$sonarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
  ntfy_message+="Testing"
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

if [ "$sonarr_eventtype" == "Download" ]; then
# Get the banner image from sonarr
response=$(curl -X GET -H "Content-Type: application/json" -H "X-Api-Key: $sonarr_api_key" "$sonarr_url/$sonarr_series_id")

banner_image=$(echo "$response" | jq -r '.images[0].remoteUrl')   
#construct the 
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

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url