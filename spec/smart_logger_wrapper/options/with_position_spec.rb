require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper::Options::WithPosition do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:logger_stub) { double(:logger) }
  let(:severity_stub) { double(:severity) }

  let(:message) { ('a'..'z').to_a.sample(10).join }
  let(:filename) { File.basename(__FILE__) }

  before do
    allow(logger_stub).to receive(:add)
  end

  def get_caller_line
    caller.first.split(":")[1].to_i
  end

  # inspect the real file name and the line number due to the sensitive offset management.in this option
  context 'with no argument' do
    let(:linenumber) { get_caller_line + 1 } # XXX: Do not add any line between this and the following subject statement
    subject! { smart_logger_wrapper.with_position.log(severity_stub, message) }

    it "logs with the caller's file name" do
      expect(logger_stub).to have_received(:add).with(severity_stub, nil, include("#{filename}:#{linenumber}"))
    end

    it 'logs with the original message' do
      expect(logger_stub).to have_received(:add).with(severity_stub, nil, include(message))
    end
  end

  context 'with falsy argument' do
    subject! { smart_logger_wrapper.append_backtrace(false).log(severity_stub, message) }

    it 'logs just the original message' do
      expect(logger_stub).to have_received(:add).with(severity_stub, nil, message)
    end
  end
end
