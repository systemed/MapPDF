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

# A class for representing a simple 2D or 3D vector.  Primarily for use with the QudTree class.  Very simple and minimilistic.
# irb(main):002:0> v = QuadVector.new(1, 2)
# => #<QuadVector:0xb7c8dacc @x=1.0, @y=2.0>
# irb(main):003:0> v + QuadVector.new(10, 11)
# => #<QuadVector:0xb7c86d30 @x=11.0, @y=13.0>
# irb(main):004:0> (v + QuadVector.new(10, 11)).length
# => 17.0293863659264
# irb(main):005:0> v * -2
# => #<QuadVector:0xb7c73834 @x=-2.0, @y=-4.0>
class QuadVector
  # Initialize a QuadVector with either another QuadVector, an Array, or 2-3 numbers.
  def initialize(x = nil, y = nil, z = nil)
    if x && x.class == QuadVector
      @x = x.x
      @y = x.y
      @z = x.z
    elsif x && x.class == Array
      @x = x[0]
      @y = x[1]
      @z = x[2]
    else
      @x = x.to_f if x
      @y = y.to_f if y
      @z = z.to_f if z
    end
  end
  
  # The X component of this vector.
  def x
    @x
  end
  
  # The Y component of this vector.
  def y
    @y
  end
  
  # The Z component of this vector.
  def z
    @z
  end
  
  # Set the X component of this vector.
  def x=(new_x)
    @x = new_x.to_f if new_x
  end

  # Set the Y component of this vector.
  def y=(new_y)
    @y = new_y.to_f if new_y
  end

  # Set the Z component of this vector.
  def z=(new_z)
    @z = new_z.to_f if new_z
  end
  
  # The length of this vector in 2D or 3D space.
  def length
    if z
      Math.sqrt(x * x + y * y + z * z)
    elsif x && y
      Math.sqrt(x * x + y * y)
    else
      nil
    end
  end
  
  # The Euclidean distnce between this and another Vector `other`.
  def dist_to(other)
    (other - self).length
  end
  
  # This vector minus another Vector `other`.
  def -(other)
    self + other * -1
  end
  
  # Divide this vector by a `scalar`.
  def /(scalar)
    if z
      QuadVector.new(x / scalar, y / scalar, z / scalar)
    elsif x && y
      QuadVector.new(x / scalar, y / scalar)
    else
      QuadVector.new
    end
  end
  
  # Multiply this vector by a `scalar`.
  def *(scalar)
    if z
      QuadVector.new(x * scalar, y * scalar, z * scalar)
    elsif x && y
      QuadVector.new(x * scalar, y * scalar)
    else
      QuadVector.new
    end
  end
  
  # Add another Vector `other` to this vector.
  def +(other)
    if z && other.z
      QuadVector.new(x + other.x, y + other.y, z + other.z)
    elsif x && y && other.x && other.y
      QuadVector.new(x + other.x, y + other.y)
    else
      QuadVector.new
    end
  end
  
  # Test if this vector is equal to another Vector `other`.
  def ==(other)
    result = (other.x == x && other.y == y && other.z == z)
#    puts "(#{other.x} == #{x} && #{other.y} == #{y} && #{other.z} == #{z}) = #{result.inspect}"
    result
  end
  
  # Display this vector as a String, either in <x, y> or <x, y, z> notation.
  def to_s
    if z
      "<#{x ? x : 'nil'}, #{y ? y : 'nil'}, #{z}>"
    else
      "<#{x ? x : 'nil'}, #{y ? y : 'nil'}>"
    end
  end
end
