#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
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
# Made in Japan.
#++


class Flor::Node
  include Flor::Ash

  def initialize(executor, node, message)

    @executor, @execution =
      case executor
        when nil then [ nil, nil ] # for some tests
        when Hash then [ nil, executor ] # from some other tests
        else [ executor, executor.execution ] # vanilla case
      end

    @node =
      node ? node : @execution['nodes'][message['nid']]

    @message = message
  end

  def exid; @execution['exid']; end
  def nid; @node['nid']; end
  def parent; @node['parent']; end

  def point; @message['point']; end
  def from; @message['from']; end

  def payload
    unash!(@message, 'payload')
  end
  def payload_copy
    unash!(@message, 'payload', true)
  end
  def node_payload_ret
    Flor.dup(unash(@node, 'payload')['ret'])
  end

  def lookup_tree(nid)

    return nil unless nid

    node = @execution['nodes'][nid]

    tree = node && node['tree']
    return tree if tree

    par = node && node['parent']
    cid = Flor.child_id(nid)

    tree = par && lookup_tree(par)
    return subtree(tree, par, nid) if tree

    return nil if node

    tree = lookup_tree(Flor.parent_nid(nid))
    return tree[1][cid] if tree

    #tree = lookup_tree(Flor.parent_nid(nid, true))
    #return tree[1][cid] if tree
      #
      # might become necessary at some point

    nil
  end

  #def lookup_tree(nid)
  #  climb_down_for_tree(nid) ||
  #  climb_up_for_tree(nid) ||
  #end
  #def climb_up_for_tree(nid)
  #  # ...
  #end
  #def climb_down_for_tree(nid)
  #  # ...
  #end
    #
    # that might be the way...

  def lookup(name)

    cat, mod, key = key_split(name)
    key, pth = key.split('.', 2)

    val = cat == 'v' ? lookup_var(@node, mod, key) : lookup_field(mod, key)
    pth ? Flor.deep_get(val, pth)[1] : val
  end

  class Expander < Flor::Dollar

    def initialize(n); @node = n; end

    def lookup(k)

      return @node.nid if k == 'nid'
      return @node.exid if k == 'exid'
      return Flor.tstamp if k == 'tstamp'

      @node.lookup(k)
    end
  end

  def expand(s)

    return s unless s.is_a?(String)

    Expander.new(self).expand(s)
  end

  def deref(o)

    if o.is_a?(String)
      lookup(o)
#    elsif Flor.is_string_val?(o)
#      lookup(o[1]['v'])
    else
      o
    end
  end

  def tree

    lookup_tree(nid)
  end

  def fei

    "#{exid}-#{nid}"
  end

  def on_error_parent

    oe = @node['on_error']
    return self if oe && oe.any?

    pn = parent_node
    return Flor::Node.new(@executor, pn, @message).on_error_parent if pn

    nil
  end

  def to_procedure

    Flor::Procedure.new(@executor, @node, @message)
  end

  protected

  def subtree(tree, pnid, nid)

    pnid = Flor.master_nid(pnid)
    nid = Flor.master_nid(nid)

    return nil unless nid[0, pnid.length] == pnid
      # maybe failing would be better

    nid[pnid.length + 1..-1].split('_').each { |cid| tree = tree[1][cid.to_i] }

    tree
  end

  def parent_node(node=@node)

    @execution['nodes'][node['parent']]
  end

  def parent_node_tree(node=@node)

    lookup_tree(node['parent'])
  end

  #def closure_node(node=@node)
  #  @execution['nodes'][node['cnid']]
  #end

  def lookup_dvar(mod, key)

    return nil if mod == 'd' # FIXME

    return [ '_proc', key, -1 ] \
      if Flor::Procedure[key]

    return [ '_task', key, -1 ] \
      if @executor.unit.tasker.has_tasker?(@executor.exid, key)

    nil
  end

  def lookup_var(node, mod, key)

    return lookup_dvar(mod, key) if node == nil || mod == 'd'

    pnode = parent_node(node)
    #cnode = closure_node(node)

    if mod == 'g'
      vars = node['vars']
      return lookup_var(pnode, mod, key) if pnode
      return vars[key] if vars
      #return lookup_var(cnode, mod, key) if cnode
      fail "node #{node['nid']} has no vars and no parent"
    end

    vars = node['vars']

    return vars[key] if vars && vars.has_key?(key)

    if cnid = node['cnid'] # look into closure
      cvars = (@execution['nodes'][cnid] || {})['vars']
      return cvars[key] if cvars && cvars.has_key?(key)
    end

    lookup_var(pnode, mod, key)
  end

  def lookup_field(mod, key)

    Flor.deep_get(payload, key)[1]
  end

  def key_split(key) # => category, mode, key

    m = key.match(/\A(?:([lgd]?)((?:v|var|variable)|w|f|fld|field)\.)?(.+)\z/)

    #fail ArgumentError.new("couldn't split key #{key.inspect}") unless m
      # spare that

    ca = (m[2] || 'v')[0, 1]
    mo = m[1] || ''
    ke = m[3]

    [ ca, mo, ke ]
  end
end

