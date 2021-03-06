
#
# specifying flor
#
# Tue Mar  1 07:05:16 JST 2016
#

require 'spec_helper'


describe Flor do

  before :each do

    @cars = {
      'alpha' => { 'id' => 'FR1' },
      'bentley' => %w[ blower spur markv ]
    }
    @ranking = %w[ Anh Bob Charly ]
  end

  describe '.deep_get' do

    [
      [ :cars, 'simca', [ true, nil ], __LINE__ ],
      [ :cars, 'alpha', [ true, { 'id' => 'FR1' } ], __LINE__ ],
      [ :cars, 'alpha.id', [ true, 'FR1' ], __LINE__ ],

      [ :cars, 'bentley.1', [ true, 'spur' ], __LINE__ ],
      [ :cars, 'bentley.other', [ false, nil ] ],
      [ :cars, 'bentley.other.nada', [ false, nil ] ],

      [ :ranking, '0', [ true, 'Anh' ], __LINE__ ],
      [ :ranking, '1', [ true, 'Bob' ], __LINE__ ],
      [ :ranking, '-1', [ true, 'Charly' ], __LINE__ ],
      [ :ranking, '-2', [ true, 'Bob' ], __LINE__ ],
      [ :ranking, 'first', [ true, 'Anh' ], __LINE__ ],
      [ :ranking, 'last', [ true, 'Charly' ], __LINE__ ],

    ].each do |o, k, v, l|

      it "gets #{k.inspect} (line #{l})" do

        o = self.instance_eval("@#{o}")

        #if v.is_a?(Class)
        #  expect { Flor.deep_get(o, k) }.to raise_error(v)
        #else
        #  expect(Flor.deep_get(o, k)).to eq(v)
        #end
        expect(Flor.deep_get(o, k)).to eq(v)
      end
    end
  end

  describe '.deep_set' do

    it 'sets at the first level' do

      o = {}
      r = Flor.deep_set(o, 'a', 1)

      expect(o).to eq({ 'a' => 1 })
      expect(r).to eq([ true, 1 ])
    end

    it 'sets at the second level in a hash' do

      o = { 'h' => {} }
      r = Flor.deep_set(o, 'h.i', 1)

      expect(o).to eq({ 'h' => { 'i' => 1 } })
      expect(r).to eq([ true, 1 ])
    end

    it 'sets at the second level in an array ' do

      o = { 'a' => [ 1, 2, 3 ] }
      r = Flor.deep_set(o, 'a.1', 1)

      expect(o).to eq({ 'a' => [ 1, 1, 3 ] })
      expect(r).to eq([ true, 1 ])
    end

    it 'returns false if it cannot set' do

      c = {}
      r = Flor.deep_set(c, 'a.b', 1)
      expect(c).to eq({})
      expect(r).to eq([ false, 1 ])

      c = []
      r = Flor.deep_set(c, 'a', 1)
      expect(c).to eq([])
      expect(r).to eq([ false, 1 ])
    end
  end

  describe '.deep_has_key?' do

#@cars = {
#  'alpha' => { 'id' => 'FR1' },
#  'bentley' => %w[ blower spur markv ]
#}
#@ranking = %w[ Anh Bob Charly ]
    it 'works' do

      expect(Flor.deep_has_key?(@cars, 'nada')).to eq(false)
      expect(Flor.deep_has_key?(@cars, 'alpha.nada')).to eq(false)
      expect(Flor.deep_has_key?(@cars, 'bentley.nada')).to eq(false)
      expect(Flor.deep_has_key?(@cars, 'bentley.3')).to eq(false)
      expect(Flor.deep_has_key?(@cars, 'bentley.-4')).to eq(false)

      expect(Flor.deep_has_key?(@cars, 'alpha')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'alpha.id')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'bentley')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'bentley.0')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'bentley.-1')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'bentley.first')).to eq(true)
      expect(Flor.deep_has_key?(@cars, 'bentley.last')).to eq(true)
    end
  end
end

