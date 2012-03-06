module PDFRenderer
	class CasingItem < DrawingItem
		
		def draw(pdf, spec)
			pdf.line_width=@style.get(@tags,'width').to_f + @style.get(@tags,'casing_width').to_f
			pdf.stroke_color(sprintf("%06X",@style.get(@tags,'casing_color')))
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
			if @style.defined('casing_dashes') then
				dashes=@style.get(@tags,'casing_dashes').split(',').collect! {|n| n.to_f}
				if dashes.length==1 then pdf.dash(dashes[0]) else pdf.dash(dashes[0], :space=>dashes[1]) end
			end

			opacity=@style.get(@tags,'casing_opacity', @style.get(@tags,'opacity',1).to_f ).to_f
			pdf.transparent(opacity) do
				StrokeItem.draw_line(pdf, spec, @entity)
				pdf.stroke
			end
			if @style.defined('casing_dashes') then pdf.undash end
		end
		
	end
end
