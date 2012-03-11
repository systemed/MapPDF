# SOFTWARE INFO
#
# This file is part of the quadtree.rb Ruby quadtree library, distributed 
# subject to the 'MIT License' below.  This software is available for 
# download at http://iterationlabs.com/free_software/quadtree.
#
# If you make modifications to this software and would be willing to 
# contribute them back to the community, please send them to us for 
# possible inclusion in future releases!
#
# LICENSE
#  
# Copyright (c) 2008, Iteration Labs, LLC, http://iterationlabs.com
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 

require File.dirname(__FILE__) + '/quadvector'

# A payload for a QuadTree.  Hs accessors for vector, data, and node.
class QuadTreePayload
  attr_accessor :vector, :data, :node

  # Initialize a QuadTreePayload with a Vector, some data (any class).
  def initialize(v, d, n = nil)
    self.node = n
    self.vector = v
    self.data = d
  end
end
 
# A quadtree node that can contain QuadTreePayloads and other QuadTree nodes.  A quadtree is a tree that subdivides space into recursively defined quadrents that (in this implementation) can contain no more than one spacially-unique payload.  Quadtrees are good for answering questions about neighborhoods of points in a space.
#
# Making a quadtree is simple, just initialize a new QuadTree with two vectors, its top left and bottom right points, then add QuadTreePayloads to it and it will store them in an efficiently constructed quadtree structure.  You may then ask for all payloads in a region, all payloads near a point, etc.
# 
# Example usage with longitudes and latitudes:
# 
# qt = QuadTree.new(QuadVector.new(-180, 90), QuadVector.new(180, -90))
# qt.add(QuadTreePayload.new(QuadVector.new(lng1, lat1), entity1))
# qt.add(QuadTreePayload.new(QuadVector.new(lng2, lat2), entity2))
# qt.add(QuadTreePayload.new(QuadVector.new(lng3, lat3), entity3))
# qt.add(QuadTreePayload.new(QuadVector.new(lng4, lat4), entity4))
#
class QuadTree
  # You may ask a QuadTree for its `payload`, `tl` point, `br` point, and `depth`.
  attr_accessor :payload, :tl, :br, :depth
  
  # Initialize a new QuadTree with two vectors: its top-left corner and its bottom-right corner.  Optionally, you can also provide a reference to this node's parent node.
  def initialize(tl, br, parent_node = nil)
    @parent = parent_node
    @tl = tl
    @br = br
    @size = 0
    @summed_contained_vectors = QuadVector.new(0,0)
    @depth = 0
  end
  
  # Add a QuadTreePayload to this QuadTree.  If this node is empty, it will be stored in this node.  If not, both the new payload and the old one will be recursively added to the appropriate one of the four children of this node.  There is a special case: if this node already has a payload and the new payload has an identical position to the existing payload, then the new payload will be stored here in ddition to the existing payload.
  #  jitter_proc - a Proc object that, if provided, is used to jitter payloads with identical vectors (accepts and returns a QuadTreePayload).
  def add(geo_data, depth = 1, jitter_proc = nil)
    geo_data.node = self
    if size > 0
      if @payload && (@payload.first.vector == geo_data.vector)
        # The vectors match.
        if jitter_proc
          @payload << jitter_proc.call(geo_data)
        else
          @payload << geo_data
        end
      else
        # The vectors don't match.
        if payload
          @payload.each { |p| add_into_subtree(p, depth + 1, jitter_proc) }
          @payload = nil
        end
        add_into_subtree(geo_data, depth + 1, jitter_proc)
      end
    else
      @payload = [geo_data]
      @depth = depth
    end
    @summed_contained_vectors += geo_data.vector
    @size += 1
  end

  # This method returns the payloads contained under this node in the quadtree.  It takes an options hash with the following optional keys:
  #  :max_count - the maximum number of payloads to return, provided via a breadth-first search.
  #  :details_proc - a Proc object to which every internal node at the maximum deoth achieved by the search is passed -- this is useful for providing summary statistics about subtrees that were not explored by this traversal due to a :max_count limitation.
  #  :requirement_proc - a Proc object that, if provided, must return true when evaluating a payload in order for that payload to be returned.
  # Returns a Hash with keys :payloads, an array of all of the payloads below this node, and :details, the mapped result of applying :details_proc (if provided) to every internal node at the mximum depth achieved by the search.
  def get_contained(options = {})
    payloads = []
    internal_nodes = []
    last_depth = -1
    breadth_first_each do |node, depth|
      break if options[:max_count] && payloads.length >= options[:max_count] && (!options[:details_proc] || depth != last_depth)

      if node.payload
        internal_nodes.delete_if {|i| i.parent_of?(node)} if options[:details_proc]
        node.payload.each do |entry|
          if !options[:requirement_proc] || options[:requirement_proc].call(entry)
            payloads << entry
          end
        end
      elsif options[:details_proc] && (node.tlq? || node.trq? || node.blq? || node.brq?)
        internal_nodes.delete_if {|i| i.parent_of?(node)}
        internal_nodes << node
      end
      last_depth = depth
    end
    { :payloads => payloads, :details => (options[:details_proc] ? internal_nodes.map {|i| options[:details_proc].call(i)} : nil) }
  end

  # Calls get_contained and only returns the :payloads key.  Accepts the same options as get_contained except for the :details_proc option.
  def get_contained_payloads(options = {})
    get_contained(options)[:payloads]
  end
  
  # Returns the centroid of the payloads contained in this quadtree.
  def center_of_mass
    @summed_contained_vectors / @size
  end
  
  # Performs a breath-first traversal of this quadtree, yielding [node, depth] for each node.
  def breadth_first_each
    queue = [self]
    while queue.length > 0
      node = queue.shift
      queue << node.tlq if node.tlq?
      queue << node.trq if node.trq?
      queue << node.blq if node.blq?
      queue << node.brq if node.brq?
      yield node, node.depth
    end
  end
  
  # Yields each payload in this quadtree via a breadth-first traversal.
  def each_payload
    breadth_first_each do |node, depth|
      next unless node.payload
      node.payload.each do |payload|
        yield payload
      end
    end
  end
  
  # True if this node is a direct parent of `node`.
  def parent_of?(node)
    node && node == tlq(false) || node == trq(false) || node == blq(false) || node == brq(false)
  end
  
  # True if this node is a direct child of `node`.
  def child_of?(node)
    node.parent_of?(self)
  end
  
  # Yields all pseudo-leaves formed when the graph is cut off at a certain depth, plus any leaves encountered before that depth.
  def leaves_each(leaf_depth)
    stack = [self]
    while stack.length > 0
      node = stack.pop
      start_size = stack.length
      stack << node.tlq if node.tlq? && node.tlq.depth < leaf_depth + depth
      stack << node.trq if node.trq? && node.trq.depth < leaf_depth + depth
      stack << node.blq if node.blq? && node.blq.depth < leaf_depth + depth
      stack << node.brq if node.brq? && node.brq.depth < leaf_depth + depth
      if node.depth == leaf_depth + depth - 1 || (!node.tlq? && !node.trq? && !node.blq? && !node.brq?)
        yield node
      end
    end
  end
  
  # Returns the size of this node: the number of contained payloads.
  def size
    @size
  end
  
  # Returns this node's parent node or nil if this node is a root node.
  def parent
    @parent
  end
  
  # Returns approxametly `approx_number` payloads near `location`.
  def approx_near(location, approx_number)
    if approx_number >= size
      return get_contained_payloads
    else
      get_containing_quad(location).approx_near(location, approx_number)
    end
  end
  
  # Returns up to `max_number` payloads inside of the region specified by `region_tl` and `region_br`.
  def payloads_in_region(region_tl, region_br, max_number = nil)
    quad1 = get_containing_quad(region_tl)
    quad2 = get_containing_quad(region_br)
    if quad1 == quad2 && payload.nil?
      quad1.payloads_in_region(region_tl, region_br, max_number)
    else
      region_containment_proc = lambda do |i|
        region_tl.x <= i.vector.x && region_br.x >= i.vector.x && region_tl.y >= i.vector.y && region_br.y <= i.vector.y
      end
      get_contained_payloads(:max_count => max_number, :requirement_proc => region_containment_proc)
    end
  end
  
  # Returns an array of [centroid (Vector), count] pairs summarizing the set of centroids at a certain tree depth.  That is, it provides centroids and counts of all of the subtrees still available at depth `depth`, plus any that terminated above that depth.
  def center_of_masses_in_region(region_tl, region_br, depth)
    quad1 = get_containing_quad(region_tl)
    quad2 = get_containing_quad(region_br)
    if quad1 == quad2 && payload.nil?
      quad1.center_of_masses_in_region(region_tl, region_br, depth)
    else
      centers_of_mass = []
      leaves_each(depth) do |node|
        centers_of_mass << [node.center_of_mass, node.size]
      end
      centers_of_mass
    end    
  end
  
  # Returns a hash with keys :payloads and :details.  The :payloads are payloads found, while details are for nodes that didn't get to be explored because the requisite number of payloads were already found.  
  def payloads_and_centers_in_region(region_tl, region_br, approx_num_to_return)
    quad1 = get_containing_quad(region_tl)
    quad2 = get_containing_quad(region_br)
    if quad1 == quad2 && payload.nil?
      quad1.payloads_and_centers_in_region(region_tl, region_br, approx_num_to_return)
    else
      region_containment_proc = lambda do |i|
        region_tl.x <= i.vector.x && region_br.x >= i.vector.x && region_tl.y >= i.vector.y && region_br.y <= i.vector.y
      end
      details_proc = lambda do |i|
        [i.center_of_mass, i.size]
      end
      get_contained(:max_count => approx_num_to_return, :requirement_proc => region_containment_proc, :details_proc => details_proc)
    end
  end
    
  # The top-left quadrent of this quadtree.  If `build` is true, this will make the quadrent quadtree if it doesn't alredy exist.
  def tlq(build = true)
    @tlq ||= QuadTree.new(QuadVector.new(tl), QuadVector.new(tl.x + (br.x - tl.x) / 2.0, br.y + (tl.y - br.y) / 2.0), self) if build
    @tlq
  end
  
  # The top-right quadrent of this quadtree.  If `build` is true, this will make the quadrent quadtree if it doesn't alredy exist.
  def trq(build = true)
    @trq ||= QuadTree.new(QuadVector.new(tl.x + (br.x - tl.x) / 2.0, tl.y), QuadVector.new(br.x, br.y + (tl.y - br.y) / 2.0), self) if build
    @trq
  end
  
  # The bottom-left quadrent of this quadtree.  If `build` is true, this will make the quadrent quadtree if it doesn't alredy exist.
  def blq(build = true)
    @blq ||= QuadTree.new(QuadVector.new(tl.x, br.y + (tl.y - br.y) / 2.0), QuadVector.new(tl.x + (br.x - tl.x) / 2.0, br.y), self) if build
    @blq
  end
  
  # The bottom-right quadrent of this quadtree.  If `build` is true, this will make the quadrent quadtree if it doesn't alredy exist.
  def brq(build = true)
    @brq ||= QuadTree.new(QuadVector.new(tl.x + (br.x - tl.x) / 2.0, br.y + (tl.y - br.y) / 2.0), QuadVector.new(br), self) if build
    @brq
  end
  
  # Returns true if this quadtree has a top-left quadrent already defined.
  def tlq?
    @tlq && (@tlq.payload || (@tlq.tlq? || @tlq.trq? || @tlq.blq? || @tlq.brq?))
  end

  # Returns true if this quadtree has a top-right quadrent already defined.
  def trq?
    @trq && (@trq.payload || (@trq.tlq? || @trq.trq? || @trq.blq? || @trq.brq?))
  end

  # Returns true if this quadtree has a bottom-left quadrent already defined.
  def blq?
    @blq && (@blq.payload || (@blq.tlq? || @blq.trq? || @blq.blq? || @blq.brq?))
  end

  # Returns true if this quadtree has a bottom-right quadrent already defined.
  def brq?
    @brq && (@brq.payload || (@brq.tlq? || @brq.trq? || @brq.blq? || @brq.brq?))
  end
    
  # Returns true if Vector `v` falls inside of this quadtree.
  def inside?(v)
    # Greedy, so the order of comparison of quads will matter.
    tl.x <= v.x && br.x >= v.x && tl.y >= v.y && br.y <= v.y
  end
  
  # Clips Vector `v` to the bounds of this quadtree.
  def clip_vector(v)
    v = v.dup
    v.x = tl.x if v.x < tl.x
    v.y = tl.y if v.y > tl.y
    v.x = br.x if v.x > br.x
    v.y = br.y if v.y < br.y
    v
  end
  
  # Scans back up a quadtree from this node until a node is found that contains the region defined by `in_tl` and `in_br`, at which point the subtree size is returned from that point.
  # (Only scans back up the tree, won't scan down.)
  def family_size_at_width(in_tl, in_br)
    if (inside?(in_tl) && inside?(in_br)) || parent.nil?
      size
    else
      parent.family_size_at_width(in_tl, in_br)
    end
  end
  
  def to_s
    "[Quadtree #{object_id}, size: #{size}, depth: #{depth}]"
  end
  
  def inspect
    to_s
  end
    
private

  def add_into_subtree(geo_data, depth = 1, jitter_proc = nil)
    get_containing_quad(geo_data.vector).add(geo_data, depth, jitter_proc)
  end
  
  def get_containing_quad(vector)
    if tlq.inside?(vector)
      tlq
    elsif trq.inside?(vector)
      trq
    elsif blq.inside?(vector)
      blq
    elsif brq.inside?(vector)
      brq
    else
      raise "This shouldn't happen!  #{vector} isn't in any of my quads! (#{self.to_s})"
    end
  end
end
