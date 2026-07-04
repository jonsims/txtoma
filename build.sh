#!/bin/bash
# Build the public GitHub Pages index.html from the canonical artifact source:
# wraps it in a standalone <!doctype> head (viewport etc.) and applies privacy trims.
set -e
SRC="/private/tmp/claude-501/-Users-jps-macmini/bb196623-ec38-4918-9d4a-bef1f24da919/scratchpad/road-trip.html"
DST="$HOME/Projects/txtoma/index.html"
python3 - "$SRC" "$DST" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
html = open(src, encoding='utf-8').read()
idx = html.index('</style>') + len('</style>')
head_part, body_part = html[:idx], html[idx:]
head = ('<!doctype html>\n<html lang="en">\n<head>\n'
        '<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n')
out = head + head_part + '\n</head>\n<body>\n' + body_part + '\n</body>\n</html>\n'
# privacy trims for the public copy (full detail stays in the private artifact/vault)
out = out.replace('Check, VA <span class="city">· 104 Meadow Run Rd SE</span>',
                  'Check, VA <span class="city">· rural Airbnb (Floyd County)</span>')
out = out.replace('query=104+Meadow+Run+Rd+SE+Check+VA', 'query=Check,+VA')
out = out.replace(
 '<b>Overnight · Little Rock Airbnb</b> near Pettaway Park — Level 1 plug; plug in on arrival. Dinner from the food truck next door, <a href="https://moodybrews.co/food-menu" target="_blank" rel="noopener">Moody Brews</a>. <a href="https://www.airbnb.com/rooms/613998127806639766" target="_blank" rel="noopener">Listing ↗</a>',
 '<b>Overnight · Little Rock</b> (Pettaway Park area) — Level 1 plug; plug in on arrival. Dinner from the food truck next door, <a href="https://moodybrews.co/food-menu" target="_blank" rel="noopener">Moody Brews</a>')
open(dst,'w',encoding='utf-8').write(out)
print('built', dst, len(out), 'bytes')
# sanity: confirm trims applied
assert '104 Meadow Run Rd SE' not in out, 'address trim failed'
assert 'airbnb.com/rooms' not in out, 'airbnb link trim failed'
print('privacy trims OK')
PY
