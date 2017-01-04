# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/firehose"
require "logstash/codecs/plain"
require "logstash/codecs/line"
require "logstash/codecs/json_lines"
require "logstash/event"
require "aws-sdk"

describe LogStash::Outputs::Firehose do

  describe "receive message with plain codec" do
    let(:data_str) { "123,someValue,1234567890" }
    let(:sample_event) { LogStash::Event.new("message" => data_str) }
    let(:expected_event) { LogStash::Event.new("message" => data_str) }
    let(:output) { LogStash::Outputs::Firehose.new({"codec" => "plain", "stream" => "my-test-stream"}) }

    before do
      Thread.abort_on_exception = true

      # Setup Firehose client
      output.stream = "aws-test-stream"
      output.access_key_id = "Key ID"
      output.secret_access_key = "Secret key"
      output.register
    end

    subject {
      expect(output).to receive(:handle_event) do |arg|
        arg
      end
      output.receive(sample_event)
    }

    it "returns same string" do
      expect(subject).not_to eq(nil)
      expect(subject.include? expected_event["message"]).to be_truthy
      # expect(subject).to eq(expected_event["message"])
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
