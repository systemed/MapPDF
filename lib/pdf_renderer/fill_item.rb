module PDFRenderer
	class FillItem < DrawingItem
		
		def draw(pdf, spec)
			dictionary=StyleParser::Dictionary.instance
			return if dictionary.is_member_of(@entity,'multipolygon','inner')
			multipolygons=dictionary.parent_relations_of_type(@entity,'multipolygon','outer')
			
			pdf.fill_color(sprintf("%06X",@style.get(@tags,'fill_color')))
			pdf.transparent(@style.get(@tags,'fill_opacity',1).to_f) do
				StrokeItem.draw_line(pdf, spec, @entity)
				multipolygons.each do |multi|
					dictionary.relation_loaded_members(@entity.db,multi,'inner').each do |obj|
						if obj.type=='way' then StrokeItem.draw_line(pdf, spec, obj) end
					end
				end
				pdf.add_content("f*")	# like pdf.fill, but for even-odd winding
			end
		end
		
	end
end
