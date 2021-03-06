
#
# specifying flor
#
# Wed May  4 15:59:30 JST 2016
# Golden Week
#

require 'spec_helper'


describe 'Flor unit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'u'
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe Flor::Scheduler do

    describe '#stop' do

      it 'stops' do

        expect(@unit.running?).to eq(true)
        expect(@unit.stopped?).to eq(false)

        @unit.stop

        expect(@unit.running?).to eq(false)
        expect(@unit.stopped?).to eq(true)
      end
    end

    describe '#launch' do

      it 'stores launch messages' do

        @unit.stop

        flor = %{
          sequence
            define sum a, b
              +
                a
                b
            sum 1 2
        }

        exid = @unit.launch(flor)

        expect(
          exid
        ).to match(
          /\Atest-u-#{Time.now.utc.year}\d{4}\.\d{4}\.[a-z]+\z/
        )

        ms = @unit.storage.db[:flor_messages].all
        m = ms.first

        expect(ms.size).to eq(1)
        expect(m[:exid]).to eq(exid)
        expect(m[:point]).to eq('execute')
        expect(Flor::Storage.from_blob(m[:content])['exid']).to eq(exid)

        expect(@unit.executions.count).to eq(0)
      end

      describe '(tree)' do

        it 'launches' do

          tree =
            Flor::Lang.parse(
              %{
                sequence
                  define sum a, b
                    +
                      a
                      b
                  sum 1 1
              },
              "#{__FILE__}:#{__LINE__}")

          msg = @unit.launch(tree, wait: true)

          expect(msg.class).to eq(Hash)
          expect(msg['point']).to eq('terminated')
          expect(msg['payload']['ret']).to eq(2)

          es = @unit.executions.all
          e = es.first

          expect(es.size).to eq(1)
          expect(e[:exid]).to eq(msg['exid'])

          sleep 0.3

          d = @unit.executions.first.data

          expect(
            d['counters']
          ).to eq({
            'funs' => 1, 'msgs' => 29, 'omsgs' => 0, 'subs' => 1, 'runs' => 1
          })
        end
      end

      describe '(flow)' do

        it 'launches' do

          flor = %{
            sequence
              define sum a, b
                +
                  a
                  b
              sum 1 2
          }

          msg = @unit.launch(flor, wait: true)

          expect(msg.class).to eq(Hash)
          expect(msg['point']).to eq('terminated')
          expect(msg['payload']['ret']).to eq(3)

          es = @unit.executions.all
          e = es.first

          expect(es.size).to eq(1)
          expect(e[:exid]).to eq(msg['exid'])

          sleep 0.3

          d = @unit.executions.first.data

          expect(
            d['counters']
          ).to eq({
            'funs' => 1, 'msgs' => 29, 'omsgs' => 0, 'subs' => 1, 'runs' => 1
          })
        end

        it 'rejects unparseable flows' do

          expect {
            @unit.launch('sequence,,,,')
          }.to raise_error(
            ArgumentError, 'flor parse failure'
          )
        end
      end

      describe '(path)' do

        it 'looks up a flow' do

          msg, _ = @unit.launch('com.acme.flow0', nolaunch: true)

          expect(msg['point']).to eq('execute')
          expect(msg['exid']).to match(/\Acom\.acme-u-2/)

          expect(
            msg['tree']
          ).to eq(
            [ 'sequence', [ [ 'alice', [], 2 ], [ 'bob', [], 3 ] ], 1 ]
          )
        end

        it 'fails if it cannot find the flow' do

          expect {
            @unit.launch('com.acme.flow-999')
          }.to raise_error(
            ArgumentError, 'flow not found in "com.acme.flow-999"'
          )
        end
      end

      describe '(flow, domain: d)' do

        it 'rejects invalid domain names' do

          expect {
            @unit.launch('', domain: 'blah-blah blah')
          }.to raise_error(
            ArgumentError, "invalid domain name \"blah-blah blah\""
          )
        end

        it 'launches in domain d' do

          msg, _ =
            @unit.launch(
              'sequence; bob | charly',
              domain: 'org.acme', nolaunch: true)

          expect(msg['point']).to eq('execute')
          expect(msg['exid']).to match(/\Aorg\.acme-u-2/)

          expect(
            msg['tree']
          ).to eq(
            [ 'sequence', [ [ 'bob', [], 1 ], [ 'charly', [], 1 ] ], 1 ]
          )
        end
      end

      describe '(path, domain: d)' do

        it 'looks up from path but launches in d' do

          msg, _ = @unit.launch('com.acme.flow0', domain: 'x.y', nolaunch: true)

          expect(msg['point']).to eq('execute')
          expect(msg['exid']).to match(/\Ax\.y-u-2/)

          expect(
            msg['tree']
          ).to eq(
            [ 'sequence', [ [ 'alice', [], 2 ], [ 'bob', [], 3 ] ], 1 ]
          )
        end
      end
    end

    describe '#queue' do

      it 'queues cancel messages' do

        flor = %{
          sequence
            sequence
              stall _
        }

        exid = @unit.launch(flor)

        sleep 0.350

        r = @unit.queue(
          { 'point' => 'cancel', 'exid' => exid, 'nid' => '0_0' },
          wait: true)

        expect(r['point']).to eq('terminated')
      end
    end

    describe '#cancel' do

      it 'queues cancel messages' do

        flor = %{
          sequence
            sequence
              stall _
        }

        exid = @unit.launch(flor)

        sleep 0.777

        xd = @unit.executions[exid: exid].data

        expect(xd['nodes'].keys).to eq(%w[ 0 0_0 0_0_0 ])

        r = @unit.cancel(exid: exid, nid: '0_0', wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.1

        expect(
          @unit.executions.where(status: 'active').count
        ).to eq(0)
      end
    end

    describe '#signal' do

      it 'queues signal messages' do

        flo = %{
          on 'blue'
            trace 'blue'

          stall _
        }

        r = @unit.launch(flo, wait: '0_1 receive')
        expect(r['point']).to eq('receive')

        exid = r['exid']

        @unit.signal('blue', exid: exid)

        @unit.wait(exid, '0_0 ceased')

        ts = @unit.traces.all
        t = ts.first

        expect(ts.size).to eq(1)
        expect(t.text).to eq('blue')
      end

      it 'emits an empty payload by default' do

        flor = %{
          trap point: 'signal', name: 's0', payload: 'event'
            def msg; trace "s0:$(msg.payload.ret)"
          stall _
        }

        r = @unit.launch(flor, wait: '0_1 receive')

        expect(r['point']).to eq('receive')

        @unit.signal('s0', exid: r['exid'])

        wait_until { @unit.traces.count > 0 }

        expect(
          @unit.traces.collect(&:text)
        ).to eq(%w[
          s0:
        ])
      end
    end
  end
end

