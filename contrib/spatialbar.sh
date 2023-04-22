#!/bin/bash

function usage {
  echo "Usage:"
  echo "    ${0} workspace INDEX"
  echo "    ${0} window INDEX"
  echo ""
  echo "Returns the block contents for the INDEXth workspace, or the INDEXth window of the current workspace. This is intended to be used for Waybar widgets."
}

function icon_of {
  local name=${1}
  local res=""

  case "${name}" in
    '"firefox"')
      res=""
      ;;
    '"kitty"')
      res=""
      ;;
    '"Slack"')
      res=""
      ;;
    '"emacs"')
      res=""
      ;;
    *)
      res=""
      ;;
  esac

  echo -n ${res}
}

command="${1}"

case "${command}" in
  "workspace")
    workspace="${2}"
    reply="$(spatialmsg -t get_workspaces --json)"
    focused_workspace=$(echo ${reply} | jq '.focus')
    is_focus='unfocus'
    icon='◯'
    focused_window="$(echo -n "${reply}" | jq ".workspaces | map(select(.index == ${workspace})) | .[0].focused_window.app_id")"

    if [ "${focused_window}" != "null" ]; then
      icon="$(icon_of "${focused_window}")"
    fi

    if [ "${focused_workspace}" = "${workspace}" ]; then
      is_focus='focus'
    fi

    echo "${icon}"
    echo "${workspace}"
    echo "${is_focus}"
    ;;
  "window")
    window="${2}"
    reply="$(spatialmsg -t get_windows --json)"
    focused_window=$(echo ${reply} | jq '.focus')
    is_focus='unfocus'
    name="$(echo -n "${reply}" | jq ".windows[${window}].app_id")"

    if [ "${name}" != "null" ]; then
      icon="$(icon_of  ${name})"

      if [ "${focused_window}" == ${window} ]; then
        is_focus="focus"
      fi

      echo "${icon}"
      echo "${name}"
      echo "${is_focus}"
    else
      exit 2
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
