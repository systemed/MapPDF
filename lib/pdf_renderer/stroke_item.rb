module PDFRenderer
	class StrokeItem < DrawingItem
		
		def draw(pdf, spec)
			dictionary=StyleParser::Dictionary.instance
			return if dictionary.is_member_of(@entity,'multipolygon','inner')
			multipolygons=dictionary.parent_relations_of_type(@entity,'multipolygon','outer')

			pdf.line_width=@style.get(@tags,'width').to_f
			pdf.stroke_color(sprintf("%06X",@style.get(@tags,'color')))
			pdf.cap_style=case @style.get(@tags,'linecap')
				when 'none'		then :butt
				when 'square'	then :projecting_square
				when 'round'	then :round
				else			:butt
			end
			pdf.join_style=case @style.get(@tags,'linejoin')
				when 'miter'	then :miter
				when 'bevel'	then :bevel
				when 'round'	then :round
				else			:round
			end
			if @style.defined('dashes') then
				dashes=@style.get(@tags,'dashes').split(',').collect! {|n| n.to_f}
				if dashes.length==1 then pdf.dash(dashes[0]) else pdf.dash(dashes[0], :space=>dashes[1]) end
				# ** https://github.com/sandal/prawn/issues/276
				# we probably need to implement our own routine as a fallback so that we can do arrow decoration
			end
			
			
			pdf.transparent(@style.get(@tags,'opacity',1).to_f) do
				StrokeItem.draw_line(pdf, spec, @entity)
				# ** the multipolygon loop is shared code with fill_item - we could probably abstract it into drawing_item
				multipolygons.each do |multi|
					dictionary.relation_loaded_members(@entity.db,multi,'inner').each do |obj|
						if obj.type=='way' then StrokeItem.draw_line(pdf, spec, obj) end
					end
				end
				pdf.stroke
			end
			if @style.defined('dashes') then pdf.undash end
		end
		
		def self.draw_line(pdf, spec, way)	# static method
			node = way.node_objects[0];
 			pdf.move_to(spec.x(node.lon), spec.y(node.lat))
			for i in 1..(way.nodes.length-1)
				node=way.node_objects[i]
 				pdf.line_to(spec.x(node.lon), spec.y(node.lat))
			end
		end
				
	end
end
