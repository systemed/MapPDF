module PDFRenderer
	class MapSpec

		attr_accessor	:minlon, :minlat, :maxlon, :maxlat
		attr_accessor	:minscale, :maxscale, :scale
		attr_accessor	:minlayer, :maxlayer
		attr_accessor	:boxwidth, :boxheight, :boxoriginx, :boxoriginy, :boxscale
		
		A3 = { 'width' => 842, 'height' => 1190 }
		A4 = { 'width' => 595, 'height' => 842  }
		
		def initialize
			@minlayer=-5
			@maxlayer= 5
			@minscale=12
			@maxscale=20
			@scale   =14
			@properties={}
			@offsetways={}
		end

		def init_projection
			@baselon  =@minlon
			@baselatp =MapSpec.lat2latp(@minlat)
			maxlatp   =MapSpec.lat2latp(@maxlat)
			@boxscale =[(@maxlon-@minlon)/@boxwidth, (maxlatp-@baselatp)/@boxheight].max
			@boxwidth =(@maxlon-@minlon)/@boxscale
			@boxheight=(maxlatp-@baselatp)/@boxscale

			@quadtree=QuadTree.new(QuadVector.new(@boxoriginx, @boxoriginy+@boxheight), 
			                       QuadVector.new(@boxoriginx+@boxwidth, @boxoriginy))
		end

		def set_pagesize(size,options={})
			margin=options[:margin] ? options[:margin] : 0
			@boxheight =size['height']-margin*2
			@boxwidth  =size['width' ]-margin*2
			@boxoriginx=margin
			@boxoriginy=margin
			if (options[:landscape]) then @boxheight,@boxwidth=@boxwidth,@boxheight end
		end
		
		def draw(pdf,ruleset,db)
			# create DisplayList with all ways and nodes inside
			list = DisplayList.new(ruleset,self)
			list.compile_canvas
			db.ways.values.each do |way|
				if inside(way) then list.compile_way(way) end
			end
			dictionary = StyleParser::Dictionary.instance
			db.nodes.values.each do |node|
				if inside(node) and !dictionary.has_parent_ways(node) then list.compile_poi(node) end
			end

			# draw within clipping box
			pdf.add_content("q #{@boxoriginx} #{@boxoriginy} #{@boxwidth} #{@boxheight} re W* n")
			pdf.canvas do list.draw(pdf) end
			pdf.add_content("Q")
		end
		
		def x(lon)
			x=lon.to_f-@baselon
			x/=@boxscale
			x+@boxoriginx
		end
		
		def y(lat)
			y_from_latp(MapSpec.lat2latp(lat.to_f))
		end
		
		def y_from_latp(latp)
			y=latp-@baselatp
			y/=@boxscale
			y+@boxoriginy
		end

		def inside(entity)
			if entity.instance_of?(OSM::Node) then
				# Node - is it within the bbox?
				return (entity.lat.to_f>=@minlat and entity.lat.to_f<=@maxlat and 
				        entity.lon.to_f>=@minlon and entity.lon.to_f<=@maxlon)
			elsif entity.instance_of?(OSM::Way) then
				# Way - do any of the segments cross the bbox?
				nodes = entity.node_objects
				for i in 1..(nodes.length-1)
					x1=[nodes[i-1].lon.to_f, nodes[i].lon.to_f].min
					x2=[nodes[i-1].lon.to_f, nodes[i].lon.to_f].max
					y1=[nodes[i-1].lat.to_f, nodes[i].lat.to_f].min
					y2=[nodes[i-1].lat.to_f, nodes[i].lat.to_f].max
					if (((x1>@minlon and x1<@maxlon) or
						 (x2>@minlon and x2<@maxlon) or
						 (x1<@minlon and x2>@maxlon)) and
						((y1>@minlat and y1<@maxlat) or
						 (y2>@minlat and y2<@maxlat) or
						 (y1<@minlon and y2>@maxlon))) then
						return true
					end
				end
				false
			end
		end
		
		def properties(way)
			unless @properties[way.id] then
				cx=0; cy=0
				pathlength=0; patharea=0; heading=[]
				lx = way.node_objects[-1].lon.to_f
				ly = MapSpec.lat2latp(way.node_objects[-1].lat.to_f)

				for i in 0..(way.nodes.length-1)
					node = way.node_objects[i]
					latp = MapSpec.lat2latp(node.lat.to_f)
					lon  = node.lon.to_f

					# length and area
					if i>0 then pathlength+=Math.sqrt((lon-lx)**2+(latp-ly)**2) end
					sc  = (lx*latp-lon*ly)/@boxscale
					cx += (lx+lon)*sc
					cy += (ly+latp)*sc
					patharea += sc
					# heading
					if (i>0) then heading[i-1]=Math.atan2((lon-lx),(latp-ly)) end

					lx=lon; ly=latp
				end
				heading[way.nodes.length-1]=heading[way.nodes.length-2]

				patharea/=2
				@properties[way.id]={}
				@properties[way.id]['heading']=heading
				@properties[way.id]['length' ]=pathlength/@boxscale
				@properties[way.id]['area'   ]=patharea
				if patharea!=0 && way.is_closed? then
					@properties[way.id]['centroid_x']=x(cx/patharea/6)
					@properties[way.id]['centroid_y']=y_from_latp(cy/patharea/6)
				elsif pathlength>0
					@properties[way.id]['centroid_x'], @properties[way.id]['centroid_y'], dummy = point_at(way,0.5,pathlength)
				end
				
			end
			@properties[way.id]
		end

		def point_at(way,t,pathlength=nil,offset=0)
			if !pathlength then pathlength=properties(way)['length'] end
			totallen = t*pathlength
			curlen = 0
			points = coord_list(way,offset)
			for i in 1..(points.length-1)
				dx=points[i][0]-points[i-1][0]
				dy=points[i][1]-points[i-1][1]
				seglen=Math.sqrt(dx*dx+dy*dy)
				if (totallen>curlen+seglen) then
					curlen+=seglen
				else
					return [points[i-1][0]+(totallen-curlen)/seglen*dx,
							points[i-1][1]+(totallen-curlen)/seglen*dy,
							Math.atan2(dy,dx)]
				end
			end
		end

        def self.lat2latp(lat)	# static method
            180/Math::PI * Math.log(Math.tan(Math::PI/4+lat*(Math::PI/180)/2));
        end

		def self.latp2lat(a)	# static method
		    180/Math::PI * (2 * Math.atan(Math.exp(a*Math::PI/180)) - Math::PI/2);
		end
		
		def add_to_collide_map(x,y,xradius,yradius,item,sub_id=nil)
			begin
				@quadtree.add(QuadTreePayload.new(QuadVector.new(x,y), CollisionObject.new(x,y,xradius,yradius,item,sub_id)))
			rescue
			end
		end
		
		def space_at(x,y,xradius,yradius,scanmargin=10)
			begin
				@quadtree.payloads_in_region(QuadVector.new(x-xradius-scanmargin,y+yradius+scanmargin), 
				                             QuadVector.new(x+xradius+scanmargin,y-yradius-scanmargin)).each do |payload|
					if payload.data.collides_with(x,y,xradius,yradius) then return false end
				end
				return true
			rescue
				return false
			end
		end
		
		private
		
		def coord_list(way,offset)
			points=[]
			nodes = way.node_objects
			for i in 0..(nodes.length-1)
				points << [x(nodes[i].lon.to_f), y(nodes[i].lat.to_f)]
			end
			if offset==0 then return points end
			
			unless @offsetways[way.id] then @offsetways[way.id]={} end
			if @offsetways[way.id][offset] then return @offsetways[way.id][offset] end
			parallel=[]
			offsetx=[]
			offsety=[]
			for i in 0..(nodes.length-1)
				j=(i+1) % nodes.length
				a=points[i][1] - points[j][1]
				b=points[j][0] - points[i][0]
				h=Math.sqrt(a*a+b*b)
				if h!=0 then a=a/h; b=b/h
					    else a=0; b=0 end
				offsetx[i]=a
				offsety[i]=b
			end
			parallel << [ points[0][0] + offset*offsetx[0],
			              points[0][1] + offset*offsety[0] ]
			for i in 0..(nodes.length-1)
				j=(i+1) % nodes.length
				k=i-1; if k==-1 then k=nodes.length-2 end
				a=det(offsetx[i]-offsetx[k],
					  offsety[i]-offsety[k],
					  points[j][0] - points[i][0],
					  points[j][1] - points[i][1])
				b=det(points[i][0] - points[k][0],
					  points[i][1] - points[k][1],
					  points[j][0] - points[i][0],
					  points[j][1] - points[i][1])
				if (b!=0) then df=a/b else df=0 end
			
				parallel << [ points[i][0] + offset*(offsetx[k]+df*(points[i][0] - points[k][0])),
				              points[i][1] + offset*(offsety[k]+df*(points[i][1] - points[k][1])) ]
			end
			@offsetways[way.id][offset]=parallel
		end
		
		def det(a,b,c,d)
			a*d-b*c
		end
	end
end
