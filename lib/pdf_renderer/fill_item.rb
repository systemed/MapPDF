module PDFRenderer
	class FillItem < DrawingItem
		
		def draw(pdf, spec)
			dictionary=StyleParser::Dictionary.instance
			return if dictionary.is_member_of(@entity,'multipolygon','inner')
			multipolygons=dictionary.parent_relations_of_type(@entity,'multipolygon','outer')
			
			pdf.fill_color(sprintf("%06X",@style.get(@tags,'fill_color')))
			pdf.transparent(@style.get(@tags,'fill_opacity',1).to_f) do
				StrokeItem.draw_line(pdf, spec, @entity)
				draw_inners(pdf, spec)
				pdf.add_content("f*")	# like pdf.fill, but for even-odd winding
			end
		end
		
	end
end
