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
	end
end
