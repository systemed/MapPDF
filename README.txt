MapPDF - Ruby map PDF renderer
==============================

This is an experimental PDF renderer from MapCSS stylesheets.

== Dependencies ==

* Jochen Topf's OSMlib (http://osmlib.rubyforge.org/)
* Prawn (http://prawn.majesticseacreature.com/)
* Ruby MapCSS parser (https://github.com/systemed/mapcss_ruby)
* RQuad (https://github.com/iterationlabs/rquad)

NOTE: current Prawn will not work perfectly. You need a slight patch to lib/prawn/images.rb - 
see comments in lib/pdf_renderer/point_item.rb. You'll still get a map without this patch, 
but the icons will be offset.

== How to use ==

See pdf_test.rb. In short:

1. (OSMlib)      Read your OSM data into a database
2. (mapcss_ruby) Create a 'parent objects' dictionary
3. (mapcss_ruby) Read the MapCSS file into a RuleSet
4. (mappdf_ruby) Create a MapSpec with the bounding box and map area parameters
5. (Prawn)       Create a PDF
6. (mappdf_ruby) Tell the MapSpec to draw onto it

== To do ==

* Better text offset

== Not currently supported ==

* Dash decoration (arrows etc.)
* Underline

== Licence and author ==

WTFPL. You can do whatever the fuck you want with this code. Code by Richard Fairhurst, autumn 2011.

OpenStreetMap data by OpenStreetMap contributors (CC-BY-SA).
