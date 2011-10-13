module PDFRenderer
	class DisplayList

		attr_accessor	:rules, :spec
		
		def initialize(rules,spec)
			@rules=rules
			@spec=spec
			@list=[]
		end
		
		def compile_way(way)
			# ** calculate midpoint and length
			pathlength=0

			# Get tags
			states = {}
			if (way.is_closed?) then states[':area']='yes' end
			tags = TagsBinding.new(way,states)

			# Get stylelist
			stylelist=@rules.get_styles(way, tags, @spec.scale)
			layer = parse_layer(stylelist, tags)
			
			# ** Do multipolygon stuff
			
			# Add entry for each subpart
			stylelist.subparts.each do |subpart|
				if stylelist.shapestyles[subpart] then
					s=stylelist.shapestyles[subpart]
					filled=(s.defined('fill_color') || s.defined('fill_image'))	# ** multipolygon stuff

					if s.defined('width')		 then add_item(layer, StrokeItem.new(s, way, tags)) end
					if filled					 then add_item(layer, FillItem.new(s, way, tags)) end
					if s.defined('casing_width') then add_item(layer, CasingItem.new(s, way, tags)) end
				end
				if stylelist.textstyles[subpart] then
					add_item(layer, TextItem.new(stylelist.textstyles[subpart], way, nil, tags, pathlength))
				end
			end
		end
		
		def compile_poi(node)
			dictionary=StyleParser::Dictionary.instance

			# Get tags
			states = {}
			if !dictionary.has_parent_ways(node) then states[':poi']='yes'
			elsif dictionary.num_parent_ways(node)>1 then states[':junction']='yes' end
			tags = TagsBinding.new(node,states)
			# ** do hasInterestingTags
			
			# Find style
			stylelist=@rules.get_styles(node, tags, @spec.scale)
			layer = parse_layer(stylelist,tags)

			# Add entry for each subpart
			stylelist.subparts.each do |subpart|
				pointitem = nil
				if stylelist.pointstyles[subpart] then
					pointitem=PointItem.new(stylelist.pointstyles[subpart], 
					                        stylelist.shapestyles[subpart], node, tags)
					add_item(layer, pointitem)
				end
				if stylelist.textstyles[subpart] then
					add_item(layer, TextItem.new(stylelist.textstyles[subpart], node, pointitem, tags))
				end
			end
		end
		
		def compile_canvas
			stylelist=@rules.get_styles(nil, {}, spec.scale)
			stylelist.subparts.each do |subpart|
				if stylelist.shapestyles[subpart] then
					add_item(@spec.minlayer, CanvasItem.new(stylelist.shapestyles[subpart], nil))
				end
			end
		end
		
		def add_item(layer,item)
			sublayer=item.get_sublayer
			l=layer-@spec.minlayer
			
			if !@list[l] then @list[l]=[] end
			if !@list[l][sublayer] then @list[l][sublayer]=[] end
			@list[l][sublayer]<<item
		end
		
		def draw(pdf)
			for layer in 0..(@list.length-1)
				if @list[layer] then
					draw_items_of_class(pdf,@list[layer],CanvasItem)
					draw_items_of_class(pdf,@list[layer],FillItem)
					draw_items_of_class(pdf,@list[layer],CasingItem)
					draw_items_of_class(pdf,@list[layer],StrokeItem)
					draw_items_of_class(pdf,@list[layer],PointItem)
					draw_items_of_class(pdf,@list[layer],TextItem)
				end
			end
		end
		
		def draw_items_of_class(pdf, items, itemclass)
			items.each do |sublayer_items|
				if sublayer_items then
					sublayer_items.each do |item|
						if item.instance_of?(itemclass) then item.draw(pdf,@spec) end
					end
				end
			end
		end

		# -----	Get layer (may come from override in declarations, or from layer tag)
			
		def parse_layer(stylelist,tags)
			layer=stylelist.layer_override
			if layer.nil? and tags.has_key?('layer') then layer=[[tags['layer'].to_i,@spec.minlayer].max,@spec.maxlayer].min end
			layer.nil? ? 0 : layer
		end

	end
end
