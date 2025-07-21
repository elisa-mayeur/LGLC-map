LGLC Interactive Map
====================

This folder contains everything needed to view the interactive map of LGLC events.

---

FILES INCLUDED:
---------------
- lglc-map-grouped.html   : The interactive map (grouped by place, all events per place in a popup)
- lglc-map.css            : Stylesheet for the map and popups
- lglc-test1.geojson      : The GeoJSON data file (all events and locations)
- leaflet/ (folder)       : Leaflet library (leaflet.js, leaflet.css)

---

HOW TO OPEN THE MAP:
--------------------
1. Open a terminal in this folder (LGLC-map).
2. Start a local server with:
   python3 -m http.server 8000
3. Open your browser and go to:
   http://localhost:8000/lglc-map-grouped.html

(Opening the HTML file directly may not work in Chrome/Edge due to browser security restrictions. The local server is recommended.)

---

HOW TO USE THE MAP:
-------------------
- Zoom and pan to explore the map.
- Click on a point to see all events at that location (scroll in the popup if there are many events).
- All data is static and local; no internet connection is required except for the map background (OpenStreetMap tiles).

---

If you have any questions, contact Elisa Mayeur. 