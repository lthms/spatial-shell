#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import sys
import os
import json

def shell(cmd):
    stream = os.popen(cmd)
    return json.loads(stream.read())

def icon(glyph):
    return f'<span font="Font Awesome 6 Free">{glyph}</span>'

def icon_of_window(window):
    match window['app_id']:
        case 'firefox':
            return icon('')
        case 'kitty':
            return icon('')
        case 'Slack':
            return icon('')
        case 'emacs':
            return icon('')
        case _:
            return icon('')

def icon_of_workspace(workspace):
    if not workspace:
        return icon('◯')
    else:
        return icon_of_window(workspace['focused_window'])

cmd = sys.argv[1]

match cmd:
    case "config":
        reply = shell('spatialmsg -t get_workspace_config')
        layout = reply['layout']
        column_count = reply['column_count']
        layout = icon('') if layout == "maximize" else f'{icon("")} {column_count}'

        print(layout)
    case "workspace":
        workspace_index = int(sys.argv[2])
        reply = shell('spatialmsg -t get_workspaces')
        workspace = next(filter(lambda w: w['index'] == workspace_index, reply['workspaces']), {})
        is_focus = 'focus' if workspace_index == reply['focus'] else 'unfocus'

        print(f'{icon_of_workspace(workspace)}\n{workspace_index}\n{is_focus}')
    case "window":
        window_index = int(sys.argv[2])
        reply = shell('spatialmsg -t get_windows')
        window = (reply['windows'][window_index:window_index + 1] or [{}])[0]
        if window:
            is_focus = 'focus' if reply['focus'] == window_index else 'unfocus'
            name = window['app_id']

            print(f'{icon_of_window(window)}\n{name}\n{is_focus}')
    case _:
        exit(1)
