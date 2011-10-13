$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '.', '../mapcss_ruby/lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '.', 'lib'))

	require "OSM"
	require "OSM/StreamParser"
	require "OSM/Database"
	require "style_parser"
	require "prawn"
	require "pdf_renderer"

	# -----	Read stylesheet

	ruleset=StyleParser::RuleSet.new(12,20)
	ruleset.parse_from_file('opencyclemap.css')

	# -----	Read OSM data
	# 		(typing 'export OSMLIB_XML_PARSER=Expat' beforehand may speed things up)

	puts "Reading file"
	db = OSM::Database.new
	parser = OSM::StreamParser.new(:filename => 'charlbury.osm', :db => db)
	parser.parse

	puts "Creating dictionary"
	dictionary = StyleParser::Dictionary.instance
	dictionary.populate(db)

	# -----	Create a MapSpec
	
	spec=PDFRenderer::MapSpec.new
	spec.set_pagesize(PDFRenderer::MapSpec::A4, 10)
	spec.minlon=-1.50; spec.minlat=51.86
	spec.maxlon=-1.47; spec.maxlat=51.89
	spec.minscale=12; spec.maxscale=18; spec.scale=15
	spec.minlayer=-5; spec.maxlayer=5
	spec.init_projection
	
	# -----	Output the map
	
	puts "Drawing map"
	start=Time.now
	Prawn::Document.generate('map.pdf', :page_size=>'A4') do |pdf| 
		spec.draw(pdf,ruleset,db)
	end
	puts "map.pdf generated in #{Time.now-start} seconds"
