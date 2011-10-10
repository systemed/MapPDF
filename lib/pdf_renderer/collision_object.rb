module PDFRenderer
	class CollisionObject

		attr_accessor	:left, :right, :top, :bottom, :item, :sub_id
		
		def initialize(x,y,xradius,yradius,item=nil,sub_id=nil)
			@left  =x-xradius
			@right =x+xradius
			@top   =y+yradius
			@bottom=y-yradius
			@item   =item
			@sub_id =sub_id
		end

		def collides_with(cx,cy,cxradius,cyradius)
			cleft  =cx-cxradius
			cright =cx+cxradius
			ctop   =cy+cyradius
			cbottom=cy-cyradius
			((cleft >@left && cleft <@right) ||
			 (cright>@left && cright<@right) ||
			 (cleft <@left && cright>@right)) &&
			((cbottom>@bottom && cbottom<@top) ||
			 (ctop   >@bottom && ctop   <@top) ||
			 (cbottom<@bottom && ctop   >@top))
		end
	end
end
