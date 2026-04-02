#!/usr/bin/env bash

# load credentials and target
API_URL="http://localhost:3000/api"

#TOKEN=$(pass show semaphore/opentofu_token)
TOKEN=$SEMAPHOREUI_API_TOKEN
if [ -z "$TOKEN" ]; then
  echo "Error: No token provided in environment."
  exit 1
fi

# dynamically find the Project ID
PROJECT_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/projects" | jq -r '.[] | select(.name == "ansible-provision") | .id')
# check if project exists
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
  echo "Project not found! Exiting."
  exit 0
fi

# find and delete the built-in "Empty" Variable Group (safely selecting the oldest ID)
ENV_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/project/$PROJECT_ID/environment" | jq -r '[.[] | select(.name == "Empty")] | if length > 0 then min_by(.id) | .id else empty end')
if [ -n "$ENV_ID" ] && [ "$ENV_ID" != "null" ]; then
  curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API_URL/project/$PROJECT_ID/environment/$ENV_ID"
fi

# find and delete the built-in "None" Key (safely selecting the oldest ID)
KEY_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/project/$PROJECT_ID/keys" | jq -r '[.[] | select(.name == "None")] | if length > 0 then min_by(.id) | .id else empty end')
if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "null" ]; then
  curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API_URL/project/$PROJECT_ID/keys/$KEY_ID"
fi
