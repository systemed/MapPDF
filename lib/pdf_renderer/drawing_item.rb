module PDFRenderer
	class DrawingItem

		def initialize(style, entity, tags=nil)
			@entity=entity
			@style=style
			@tags=tags ? tags : (entity ? entity.tags : {} )
		end
		
		def get_sublayer
			@style.sublayer
		end
		
		def draw_inners(pdf,spec)
			dictionary=StyleParser::Dictionary.instance
			multipolygons=dictionary.parent_relations_of_type(@entity,'multipolygon','outer')
			multipolygons.each do |multi|
				dictionary.relation_loaded_members(@entity.db,multi,'inner').each do |obj|
					if obj.type=='way' then StrokeItem.draw_line(pdf, spec, obj) end
				end
			end
		end
		
	end
end
