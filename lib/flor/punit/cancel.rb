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


class Flor::Pro::Cancel < Flor::Procedure
  #
  # Cancels an execution branch
  #
  # ```
  # concurrence
  #   sequence tag: 'blue'
  #   sequence
  #     cancel ref: 'blue'
  # ```

  name 'cancel', 'kill'
    # ruote had "undo" as well...

  def pre_execute

    @node['atts'] = []
  end

  def receive_last

    targets =
      @node['atts']
        .select { |k, v| k == nil }
        .inject([]) { |a, (k, v)|
          v = Array(v)
          a.concat(v) if v.all? { |e| e.is_a?(String) }
          a
        } +
      att_a('nid') +
      att_a('ref')

    nids, tags = targets.partition { |t| Flor.is_nid?(t) }

    nids += tags_to_nids(tags)

    fla = @node['heap']

    nids.uniq.collect { |nid|
      reply('point' => 'cancel', 'nid' => nid, 'flavour' => fla).first
    } + reply
  end
end

