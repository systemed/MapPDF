module PDFRenderer
	class CasingItem < DrawingItem
		
		def draw(pdf, spec)
			pdf.line_width=@style.get(@tags,'width').to_f + @style.get(@tags,'casing_width').to_f
			defaultcap = @style.get(@tags,'linecap')
			defaultjoin= @style.get(@tags,'linejoin')
			pdf.cap_style=case @style.get(@tags,'casing_linecap')
				when 'none'		then :butt
				when 'square'	then :projecting_square
				when 'round'	then :round
				else			(defaultcap ? defaultcap : :butt)
			end
			pdf.join_style=case @style.get(@tags,'casing_linejoin')
				when 'miter'	then :miter
				when 'bevel'	then :bevel
				when 'round'	then :round
				else			(defaultjoin ? defaultjoin : :round)
			end
			pdf.stroke_color(sprintf("%06X",@style.get(@tags,'casing_color')))
			# do dash with pdf.stroke_dash or implement separately
			# etc.
			StrokeItem.draw_line(pdf, spec, @entity)
			pdf.stroke
		end
		
	end
end
