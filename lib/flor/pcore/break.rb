#--
# Copyright (c) 2015-2017, John Mettraux, jmettraux+flor@gmail.com
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


class Flor::Pro::Break < Flor::Procedure
  #
  # Breaks or continues a "while" or "until".
  #
  # ```
  # until false
  #   # do something
  #   continue if f.x == 0
  #   break if f.x == 1
  #   # do something more
  # ```

  name 'break', 'continue'

  def pre_execute

    @node['atts'] = []
  end

  def receive_last

    ref = att('ref')
    nid = tags_to_nids(ref).first || @node['heat'][1]['nid']
#p [ :break, @node['heap'], nid ]

    payload['ret'] = att(nil) if has_att?(nil)

    ms = []

    if nid

      ms += reply('point' => 'cancel', 'nid' => nid, 'flavour' => @node['heap'])
    end

    unless is_ancestor_node?(nid)

      pl = ms.any? ? payload.copy_current : payload.current
      pl['ret'] = node_payload_ret

      ms += reply('payload' => pl)
    end

    ms
  end
end

