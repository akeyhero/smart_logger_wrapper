require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper::Options::To do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:logger_stub) { double(:logger) }
  let(:random_log_method) { SmartLoggerWrapper::SEVERITY_MAPPING.keys.sample }
  let(:severity) { SmartLoggerWrapper::SEVERITY_MAPPING[random_log_method] }

  let(:handler_stub) { double(:handler) }
  let(:message1) { ('a'..'z').to_a.sample(10).join }
  let(:message2) { ('a'..'z').to_a.sample(10).join }

  before do
    allow(logger_stub).to receive(:add)
    allow(logger_stub).to receive(:error)
    allow(handler_stub).to receive(:puts)
  end

  context 'with a handler' do
    subject! { smart_logger_wrapper.to(handler_stub).public_send(random_log_method, message1, message2) }

    it 'calls #puts of the argument' do
      expect(handler_stub).to have_received(:puts).with([message1, message2].join("\n")).once
    end
  end

  context 'with no handler' do
    subject! { smart_logger_wrapper.to.public_send(random_log_method, message1) }

    it 'logs an exception' do
      expect(logger_stub).to have_received(:error).with(include('No handler given')).once
    end

    it 'logs the original messages' do
      expect(logger_stub).to have_received(:add).with(severity, nil, message1).once
    end
  end
end
