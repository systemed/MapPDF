module PDFRenderer
	class TextItem < DrawingItem
		
		def initialize(style, entity, associateditem=nil, tags=nil, pathlength=nil)
			@entity=entity
			@style=style
			@associateditem=associateditem		# the PointItem for this entity, for label placement etc.
			@tags=tags ? tags : entity.tags
			@pathlength=pathlength
		end
		
		def draw(pdf, spec)
			return unless @style.defined('text')
			text=@tags[@style.get(@tags,'text')]
			return unless text
			if @style.get(@tags,'font_caps') then text.upcase! end

  			typeface  = @style.get(@tags,'font_family', 'Helvetica')
			typesize  = @style.get(@tags,'font_size', 10).to_f
			typestyle = :normal
			if @style.get(@tags,'font_bold') && @style.get(@tags,'font_italic') then
				typestyle = :bold_italic
			elsif @style.get(@tags,'font_bold') then
				typestyle = :bold
			elsif @style.get(@tags,'font_italic') then
				typestyle = :italic
			end
			
			pdf.font typeface, :style => typestyle
			pdf.font_size typesize
			font=pdf.font
			charheight=font.ascender
			textwidth = pdf.width_of(text)
			colour = sprintf("%06X",@style.get(@tags,'text_color',0).to_f)

			if @entity.instance_of?(OSM::Way) then
				pathlength = spec.properties(@entity)['length']
				centroid_x = spec.properties(@entity)['centroid_x']
				centroid_y = spec.properties(@entity)['centroid_y']
			end

			# Position text at node

			if @entity.instance_of?(OSM::Node)
				x=@associateditem.x-textwidth/2
				y=@associateditem.y-@associateditem.rendered_width/2-charheight
				place_label(pdf, spec, text, x, y, colour)

			# Position text at centre of way
			
			elsif @entity.instance_of?(OSM::Way) && @style.get(@tags,'text_center') && centroid_x
				x=centroid_x-textwidth/2
				y=centroid_y-charheight/2
				place_label(pdf, spec, text, x, y, colour)

			# Position text along way

			elsif @entity.instance_of?(OSM::Way)
				return if pathlength<textwidth
				textoffset  = @style.get(@tags,'text_offset',0).to_f
				t1 = (pathlength/2 - textwidth/2) / pathlength; p1=spec.point_at(@entity, t1, nil, textoffset)
				t2 = (pathlength/2 + textwidth/2) / pathlength; p2=spec.point_at(@entity, t2, nil, textoffset)

				# make sure text doesn't run right->left or upside down
				reverse = (p1[0] < p2[0] && p1[2] < Math::PI/2 && p1[2] > -Math::PI/2)
				angleoffset = reverse ? 0 : Math::PI	# so we can do a 180º if we're running backwards
				offsetsign  = reverse ? 1 : -1			# -1 if we're starting at t2
				tstart      = reverse ? t1 : t2			# which end to start at

				positions=calculate_text_path_positions(pdf,spec,text,tstart,offsetsign,pathlength,angleoffset,charheight,textoffset)
				return if positions_collide(spec,positions)

				if @style.defined('text_halo_color') then
					pdf.text_rendering_mode(:stroke) do
						pdf.stroke_color(sprintf("%06X",@style.get(@tags,'text_halo_color',0).to_f))
						pdf.line_width=@style.get(@tags,'text_halo_width',1).to_f
						text_on_path(pdf,text,positions)
					end
				end

				pdf.fill_color(colour)
				text_on_path(pdf,text,positions)
				positions_reserve(spec,positions)
			end
		end
		
		private
			
		def place_label(pdf,spec,text,x,y,colour)
			positions=[]
			cx=x
			charheight=pdf.font.ascender
			for i in 0..(text.length-1)
				charwidth = pdf.width_of(text.slice(i,1))
				positions << [cx+charwidth/2, y+charheight/2, charwidth/2, charheight/2, 0]
				cx+=charwidth
			end
			return if positions_collide(spec,positions)

			if @style.defined('text_halo_color') then
				pdf.text_rendering_mode(:stroke) do
					pdf.stroke_color(sprintf("%06X",@style.get(@tags,'text_halo_color',0).to_f))
					pdf.line_width=@style.get(@tags,'text_halo_width',1).to_f
					pdf.draw_text text, :at=>[x,y]
				end
			end
			pdf.fill_color(colour)
			pdf.draw_text text, :at=>[x,y]
			positions_reserve(spec,positions)
		end

		def calculate_text_path_positions(pdf,spec,text,tstart,offsetsign,pathlength,angleoffset,charheight,textoffset)
			positions = []
			charpos = 0
			for i in 0..(text.length-1)
				charwidth =pdf.width_of(text.slice(i,1))
				x, y, pa  =spec.point_at(@entity, tstart+offsetsign*(charpos+charwidth/2)/pathlength, nil, textoffset)
				radians   =pa+angleoffset
				degrees   =radians*(180/Math::PI)
				positions << [x,y,charwidth,charheight,degrees]
				charpos+=charwidth
			end
			positions
		end
		
		def positions_collide(spec,positions)
			positions.each do |pos|
				return true unless spec.space_at(pos[0],pos[1],pos[2]/2,pos[3]/2)
			end
			false
		end
		
		def positions_reserve(spec,positions)
			positions.each do |pos|
				spec.add_to_collide_map(pos[0],pos[1],pos[2]/2,pos[3]/2,self)
			end
		end
		
		def text_on_path(pdf,text,positions)
			# write each character one-by-one
			charpos = 0
			for i in 0..(text.length-1)
				x,y,charwidth,charheight,degrees = positions[i]
				pdf.save_graphics_state
				pdf.rotate degrees, :origin=>[x,y] do
					pdf.draw_text text.slice(i,1), :at =>[x-charwidth/2,y-charheight/2]
				end
				pdf.restore_graphics_state
				charpos+=charwidth
			end
		end
		
	end
end
