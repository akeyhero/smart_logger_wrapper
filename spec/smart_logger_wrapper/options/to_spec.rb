require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper::Options::To do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger1_stub, logger2_stub) }
  let(:logger1_stub) { double(:logger1) }
  let(:logger2_stub) { double(:logger2) }
  let(:random_log_method) { SmartLoggerWrapper::SEVERITY_MAPPING.keys.sample }
  let(:severity) { SmartLoggerWrapper::SEVERITY_MAPPING[random_log_method] }

  let(:handler_stub) { double(:handler) }
  let(:formatter1_stub) { double(:formatter1) }
  let(:formatter2_stub) { double(:formatter1) }
  let(:message1) { ('a'..'z').to_a.sample(10).join }
  let(:message2) { ('a'..'z').to_a.sample(10).join }
  let(:formatted_message1) { ('a'..'z').to_a.sample(10).join }
  let(:formatted_message2) { ('a'..'z').to_a.sample(10).join }

  before do
    SmartLoggerWrapper::SEVERITY_MAPPING.keys.each do |method_name|
      allow(logger1_stub).to receive(method_name)
      allow(logger2_stub).to receive(method_name)
    end
    allow(logger1_stub).to receive(:format_message).with(severity, kind_of(Time), nil, message1).and_return formatted_message1
    allow(logger1_stub).to receive(:format_message).with(severity, kind_of(Time), nil, message2).and_return formatted_message2
    allow(logger2_stub).to receive(:format_message)
    allow(handler_stub).to receive(:puts)
  end

  context 'with a handler' do
    subject! { smart_logger_wrapper.to(handler_stub).public_send(random_log_method, message1, message2) }

    it 'calls #puts of the argument' do
      expect(handler_stub).to have_received(:puts).with([formatted_message1, formatted_message2].join("\n")).once
    end

    it { expect(logger2_stub).not_to have_received(:format_message) }
  end

  context 'with no handler' do
    subject! { smart_logger_wrapper.to.public_send(random_log_method, message1) }

    it 'logs an exception' do
      expect(logger1_stub).to have_received(:error).with(include('No handler given')).once
      expect(logger2_stub).to have_received(:error).with(include('No handler given')).once
    end

    it 'logs the original messages' do
      expect(logger1_stub).to have_received(random_log_method).with(message1).once
      expect(logger2_stub).to have_received(random_log_method).with(message1).once
    end
  end
end
