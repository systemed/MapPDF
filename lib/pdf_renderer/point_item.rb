module PDFRenderer
	class PointItem < DrawingItem

		# Note: the code currently requires the following to be added to lib/prawn/images.rb after x,y = map_to_absolute(options[:at]) :
		#
		# case options[:position]
		# when :center
		# 	x-=w/2
		# when :right
		# 	x-=w
		# end
		# case options[:vposition]
		# when :center
		# 	y+=h/2
		# when :bottom
		# 	y+=h
		# end

		attr_accessor :x, :y, :rendered_width, :rendered_height

		def initialize(style, shapestyle, entity, tags=nil)
			@entity=entity
			@style=style
			@tags=tags ? tags : entity.tags
			@shapestyle=shapestyle
		end
		
		def draw(pdf, spec)
			shape=@style.get(@tags,'icon_image')
			@x=spec.x(@entity.lon)
			@y=spec.y(@entity.lat)
			if shape=='square' || shape=='circle' then
				width =@style.get(@tags,'icon_width',8).to_f
				height=width

				filled=false; stroked=false
				if @shapestyle.defined('color') then 
					pdf.fill_color sprintf("%06X",@shapestyle.get(@tags,'color'))
					filled=true
				end
				if @shapestyle.defined('casing_color') then 
					pdf.stroke_color sprintf("%06X",@shapestyle.get(@tags,'color'))
					stroked=true
				end

				if shape=='square' then pdf.rectangle [@x-width/2,@y-width/2], width, width
				                   else pdf.circle    [@x-width/2,@y-width/2], width end
				if filled and stroked then pdf.fill_and_stroke
				         elsif filled then pdf.fill
				                      else pdf.stroke end

			else
				options = { :position=>:center, :vposition=>:center, :at=>[@x,@y] }
				if @style.defined('icon_width' ) then options[:width ]=@style.get(@tags,'icon_width' ).to_f end
				if @style.defined('icon_height') then options[:height]=@style.get(@tags,'icon_height').to_f end
				info=pdf.image shape,options
				# ** FIXME: add image rotation
				# ** FIXME: add opacity
				width =info.scaled_width
				height=info.scaled_height
			end

			@rendered_width=width
			@rendered_height=height
			spec.add_to_collide_map(@x,@y,@rendered_width/2,@rendered_height/2,self)
		end
		
	end
end
