# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/firehose"
require "logstash/codecs/plain"
require "logstash/codecs/line"
require "logstash/codecs/json_lines"
require "logstash/event"
require "aws-sdk"

describe LogStash::Outputs::Firehose do

  before do
    Thread.abort_on_exception = true
  end

  describe 'Receiving messages' do
    let(:data_str) { "123,someValue,1234567890" }
    let(:sample_event) { LogStash::Event.new("message" => data_str) }

    let(:config) {
      {
        'stream'            => 'aws-test-stream',
        'access_key_id'     => 'Key ID',
        'secret_access_key' => 'Secret key'
      }
    }

    it 'puts firehose records' do
      output = LogStash::Outputs::Firehose.new(config)

      expect_any_instance_of(Aws::Firehose::Client).to receive(:put_record) do |instance, arg|
        expect(arg.dig(:record, :data)).to include(data_str)
      end

      output.register
      output.receive(sample_event)
    end
  end

  describe 'Configuration' do
    let(:config) {
      {
        'stream' => 'my-stream',
        'region' => 'us-west-2'
      }
    }

    let(:bad_config) {
      {
        'stream' => 'good+%&]][chars'
      }
    }

    it 'should register' do
      output = LogStash::Plugin.lookup('output', 'firehose').new(config)
      expect {output.register}.to_not raise_error
    end

    it 'should reject bad stream names' do
      output = LogStash::Plugin.lookup('output', 'firehose').new(bad_config)
      expect {output.register}.to raise_error(LogStash::ConfigurationError)
    end
  end

end
