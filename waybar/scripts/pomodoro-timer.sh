#!/usr/bin/env bash

# run tomat watch and pipe it directly into jq to process the stream and give Waybar classes
tomat watch | jq --unbuffered -c '
    #------------------------
    # get phase number
    #------------------------
    # if the timer is stopped and no session exists, it defaults to "1"
    (if (.text | test("[0-9]+/[0-9]+")) then
        (.text | capture("(?<num>[0-9]+)/").num)
    else
        "1"
    end) as $phase |

    #------------------------
    # class assignment
    #------------------------
    if (.text | contains("⏹")) then
        .class = "idle" |
        .text = " "
    elif (.text | contains("🍅") and contains("▶")) then
        .class = "work-\($phase)"
    elif (.text | contains("🍅") and contains("⏸")) then
        .class = "work-paused"
    elif (.text | contains("☕") and contains("▶")) then
        .class = "break"
    elif (.text | contains("☕") and contains("⏸")) then
        .class = "break-paused"
    elif (.text | contains("🏖️") and contains("▶")) then
        .class = "long-break"
    elif (.text | contains("🏖️") and contains("⏸")) then
        .class = "long-break-paused"
    else
        .class = "unknown" |
        .text = " "
    end |

    #------------------------
    # conditional formatting
    #------------------------
    if (.class == "idle" or .class == "unknown") then
        .  # do nothing (the period "." just passes the object through as-is)
    else
        .text |= sub("[0-9]+/[0-9]+ "; "")  |  # strip the session (eg: "1/4" --> "")
        .text |= sub("🍅 |☕ |🏖️ "; "")     |  # strip the emoji icons (eg: " ☕ " --> "")
        .text |= sub(":[0-9]{2} "; "")      |  # strip the seconds (eg: "23:45" --> "23")
        .text |= gsub("\\b0+(?=[0-9])"; "") |  # strip leading zeros (e.g., "09" -> "9")
        .text |= gsub("[^0-9]"; "")         |  # nuke spaces and invisible ghost characters
        .text |= sub("▶|⏸|⏹"; "")              # strip the state symbols (eg: " ⏸" --> "")
    end
'
