#!/bin/bash
# Build the public GitHub Pages index.html from the canonical artifact source:
#  - wraps it in a standalone <!doctype> head (viewport, etc.)
#  - applies privacy trims (town-level lodging)
#  - injects an interactive Leaflet route map (public-only; the Artifact CSP
#    blocks external tiles/scripts, so the artifact keeps just a route link)
set -e
SRC="/private/tmp/claude-501/-Users-jps-macmini/bb196623-ec38-4918-9d4a-bef1f24da919/scratchpad/road-trip.html"
DST="$HOME/Projects/txtoma/index.html"
python3 - "$SRC" "$DST" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
html = open(src, encoding='utf-8').read()

idx = html.index('</style>') + len('</style>')
head_part, body_part = html[:idx], html[idx:]

leaflet_head = (
 '<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>\n'
 '<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>\n'
)
head = ('<!doctype html>\n<html lang="en">\n<head>\n'
        '<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        + leaflet_head)
out = head + head_part + '\n</head>\n<body>\n' + body_part + '\n</body>\n</html>\n'

# --- privacy trims (public copy; full detail stays in the private artifact/vault) ---
out = out.replace('Check, VA <span class="city">· 104 Meadow Run Rd SE</span>',
                  'Check, VA <span class="city">· rural Airbnb (Floyd County)</span>')
out = out.replace('query=104+Meadow+Run+Rd+SE+Check+VA', 'query=Check,+VA')
out = out.replace(
 '<b>Overnight · Little Rock Airbnb</b> near Pettaway Park — Level 1 plug; plug in on arrival. Dinner from the food truck next door, <a href="https://moodybrews.co/food-menu" target="_blank" rel="noopener">Moody Brews</a>. <a href="https://www.airbnb.com/rooms/613998127806639766" target="_blank" rel="noopener">Listing ↗</a>',
 '<b>Overnight · Little Rock</b> (Pettaway Park area) — Level 1 plug; plug in on arrival. Dinner from the food truck next door, <a href="https://moodybrews.co/food-menu" target="_blank" rel="noopener">Moody Brews</a>')

# --- interactive map (replace the <!--MAPSLOT--> placeholder) ---
mapdiv = '<div id="rtmap" aria-label="Interactive route map"></div>'
mapscript = r'''
<script>
(function(){
  if (typeof L === 'undefined') return;
  var S = [
    {n:"Austin, TX", t:"stay", lat:30.2672, lng:-97.7431, d:"Start"},
    {n:"Collin Street Bakery — Waco", t:"topup", lat:31.58224, lng:-97.10915, d:"250 kW · 22 stalls", ps:"18941", ts:"wacotxsupercharger"},
    {n:"Sulphur Springs Square", t:"anchor", lat:33.13709, lng:-95.60328, d:"150 kW · 8 stalls — anchor", ps:"90255", ts:"sulphurspringstxsupercharger"},
    {n:"Outlets of Little Rock", t:"topup", lat:34.6614, lng:-92.41031, d:"325 kW V3 · 16 stalls", ps:"118147", ts:"littlerocksupercharger"},
    {n:"Little Rock — overnight (L1)", t:"stay", lat:34.7465, lng:-92.2896, d:"Night 1"},
    {n:"Casey Jones Village — Jackson", t:"anchor", lat:35.66035, lng:-88.85577, d:"250 kW · 24 stalls — anchor", ps:"100394", ts:"jacksontnsupercharger"},
    {n:"Cookeville — Jackson Plaza", t:"topup", lat:36.15585, lng:-85.51521, d:"150 kW · 8 stalls", ps:"133554", ts:"cookevilletnsupercharger"},
    {n:"Knoxville — Brookview", t:"topup", lat:35.93585, lng:-84.00415, d:"250 kW · 8 stalls — insurance", ps:"340586", ts:"KnoxvilleTNSupercharger"},
    {n:"Bristol, VA — Royal Farms", t:"topup", lat:36.60191, lng:-82.19144, d:"250 kW · 8 stalls", ps:"569351", ts:"26876"},
    {n:"Abingdon, VA — Royal Farms", t:"topup", lat:36.71229, lng:-81.9287, d:"250 kW · 8 stalls", ps:"595397", ts:"26874"},
    {n:"Check, VA — overnight (L2)", t:"stay", lat:36.9312, lng:-80.1698, d:"Night 2"},
    {n:"Winchester — Sheetz", t:"topup", lat:39.18814, lng:-78.12579, d:"250 kW · 8 stalls", ps:"344908", ts:"WinchesterVAsupercharger"},
    {n:"Clinton Station Diner", t:"anchor", lat:40.63385, lng:-74.9377, d:"250 kW · 12–15 stalls — anchor", ps:"604854", ts:"20974"},
    {n:"Sturbridge Plaza", t:"topup", lat:42.09855, lng:-72.0726, d:"250 kW · 12 stalls", ps:"510101", ts:"26672"},
    {n:"Needham, MA", t:"stay", lat:42.2809, lng:-71.2378, d:"Home"}
  ];
  var col = {stay:"#1B211D", anchor:"#B8701A", topup:"#0B7A59"};
  var map = L.map('rtmap', {scrollWheelZoom:false});
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    {maxZoom:18, attribution:'© OpenStreetMap contributors'}).addTo(map);
  var line = [];
  S.forEach(function(s){
    line.push([s.lat, s.lng]);
    var links = [];
    if (s.ps) links.push('<a href="https://www.plugshare.com/location/'+s.ps+'" target="_blank" rel="noopener">PlugShare</a>');
    if (s.ts) links.push('<a href="https://www.tesla.com/findus/location/supercharger/'+s.ts+'" target="_blank" rel="noopener">Tesla</a>');
    var html = '<strong>'+s.n+'</strong>' + (s.d ? '<br>'+s.d : '') + (links.length ? '<br>'+links.join(' · ') : '');
    L.circleMarker([s.lat, s.lng], {
      radius: s.t==='anchor' ? 7 : 6,
      color: '#fff', weight: 1.5, fillColor: col[s.t], fillOpacity: 1
    }).addTo(map).bindPopup(html);
  });
  L.polyline(line, {color:'#0B7A59', weight:3, opacity:.65}).addTo(map);
  map.fitBounds(line, {padding:[26,26]});
})();
</script>
'''
out = out.replace('<!--MAPSLOT-->', mapdiv)
out = out.replace('</body>', mapscript + '</body>')

open(dst, 'w', encoding='utf-8').write(out)
print('built', dst, len(out), 'bytes')
assert '104 Meadow Run Rd SE' not in out, 'address trim failed'
assert 'airbnb.com/rooms' not in out, 'airbnb link trim failed'
assert 'id="rtmap"' in out, 'map div not injected'
print('trims + map injection OK')
PY
