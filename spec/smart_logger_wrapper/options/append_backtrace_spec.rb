require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper::Options::AppendBacktrace do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:logger_stub) { double(:logger) }
  let(:severity_stub) { double(:severity) }

  let(:message) { ('a'..'z').to_a.sample(10).join }
  let(:filename) { File.basename(__FILE__) }
  let(:backtrace) { [backtrace_line1, backtrace_line2] }
  let(:backtrace_line1) { ('a'..'z').to_a.sample(10).join }
  let(:backtrace_line2) { ('a'..'z').to_a.sample(10).join }


  before do
    allow(logger_stub).to receive(:log)
  end

  def get_caller_line
    caller.first.split(':')[1].to_i
  end

  context 'with no argument' do
    before do
      allow_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).and_return backtrace
    end

    subject! { smart_logger_wrapper.append_backtrace.log(severity_stub, message) }

    it 'logs with the backtrace' do
      expect(logger_stub).to have_received(:log).with(severity_stub, nil, ['BACKTRACE:', *backtrace].join("\n"))
    end

    it 'logs with the original message' do
      expect(logger_stub).to have_received(:log).with(severity_stub, nil, include(message))
    end
  end

  context 'with a number argument' do
    context 'with a fake backtrace' do
      let(:argument_stub) { double(:argument) }
      let(:backtrace) { [backtrace_line1] }

      before do
        allow(argument_stub).to receive(:is_a?).with(Numeric).and_return true
        allow_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).and_return backtrace
      end

      subject { smart_logger_wrapper.append_backtrace(argument_stub).log(severity_stub, message) }

      it 'calls get_backtrace with the argument of #append_backtrace' do
        expect_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).with(anything, argument_stub).once
        subject
      end

      it 'logs with the original message' do
        subject
        expect(logger_stub).to have_received(:log).with(severity_stub, nil, include(message))
      end
    end

    # inspect the real file name and the line number due to the sensitive offset management.in this option
    context 'for the real source file' do
      let(:linenumber) { get_caller_line + 1 } # XXX: Do not add any line between this and the following subject statement
      subject! { smart_logger_wrapper.append_backtrace(1).log(severity_stub, message) }

      it "logs with the caller's file name" do
        expect(logger_stub).to have_received(:log).with(severity_stub, nil, include("#{filename}:#{linenumber}"))
      end
    end
  end

  context 'with falsy argument' do
    subject! { smart_logger_wrapper.append_backtrace(false).log(severity_stub, message) }

    it 'logs just the original message' do
      expect(logger_stub).to have_received(:log).with(severity_stub, nil, message)
    end
  end
end
