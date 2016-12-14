
#
# specifying flor
#
# Thu Dec 15 06:27:45 JST 2016
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'fail' do

    it 'raises an error' do

      flon = %{
        fail 'not enough flour'
      }

      r = @executor.launch(flon)

      expect(r['point']).to eq('failed')
      expect(r['error']['kla']).to eq('RuntimeError')
      expect(r['error']['msg']).to eq('not enough flour')
#pp r
    end
  end

  describe 'error' do

    it 'is an alias to "fail"' do

      flon = %{
        error 'not enough water'
      }

      r = @executor.launch(flon)

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('not enough water')
    end
  end
end

