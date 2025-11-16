#!/bin/bash

# Launch X only on the primary virtual terminal when no display exists.
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
