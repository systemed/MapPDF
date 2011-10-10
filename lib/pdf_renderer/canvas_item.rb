module PDFRenderer
	class CanvasItem < DrawingItem
		
		def draw(pdf, spec)
			pdf.fill_color(sprintf("%06X",@style.get(@tags,'fill_color')))
			pdf.transparent(@style.get(@tags,'fill_opacity',1).to_f) do
				pdf.rectangle [spec.boxoriginx, spec.boxoriginy],spec.boxwidth,-spec.boxheight
				pdf.fill
			end
		end
	end
end
