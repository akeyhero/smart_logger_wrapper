require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper::Options::AppendBacktrace do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:logger_stub) { double(:logger) }
  let(:random_log_method) { SmartLoggerWrapper::SEVERITY_MAPPING.keys.sample }
  let(:severity) { SmartLoggerWrapper::SEVERITY_MAPPING[random_log_method] }

  let(:message) { ('a'..'z').to_a.sample(10).join }
  let(:filename) { File.basename(__FILE__) }
  let(:backtrace) { [backtrace_line1, backtrace_line2] }
  let(:backtrace_line1) { ('a'..'z').to_a.sample(10).join }
  let(:backtrace_line2) { ('a'..'z').to_a.sample(10).join }

  before do
    allow(logger_stub).to receive(:add)
  end

  def get_caller_line
    caller.first.split(':')[1].to_i
  end

  context 'with no argument' do
    before do
      allow_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).and_return backtrace
    end

    subject! { smart_logger_wrapper.append_backtrace.public_send(random_log_method, message) }

    it 'logs with the backtrace' do
      expect(logger_stub).to have_received(:add).with(severity, nil, ['BACKTRACE:', *backtrace].join("\n"))
    end

    it 'logs with the original message' do
      expect(logger_stub).to have_received(:add).with(severity, nil, include(message))
    end
  end

  context 'with a number argument' do
    context 'with a fake backtrace' do
      let(:random_number) { rand(1..10000) }
      let(:backtrace) { [backtrace_line1] }

      before do
        allow_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).and_return backtrace
      end

      subject { smart_logger_wrapper.append_backtrace(random_number).public_send(random_log_method, message) }

      it 'calls get_backtrace with the argument of #append_backtrace' do
        expect_any_instance_of(SmartLoggerWrapper::Utils::Backtrace).to receive(:get_backtrace).with(anything, random_number).once
        subject
      end

      it 'logs with the original message' do
        subject
        expect(logger_stub).to have_received(:add).with(severity, nil, include(message))
      end
    end

    # inspect the real file name and the line number due to the sensitive offset management.in this option
    context 'for the real source file' do
      let(:linenumber) { get_caller_line + 1 } # XXX: Do not add any line between this and the following subject statement
      subject! { smart_logger_wrapper.append_backtrace(1).public_send(random_log_method, message) }

      it "logs with the caller's file name" do
        expect(logger_stub).to have_received(:add).with(severity, nil, include("#{filename}:#{linenumber}"))
      end
    end
  end

  context 'with falsy argument' do
    subject! { smart_logger_wrapper.append_backtrace(false).public_send(random_log_method, message) }

    it 'logs just the original message' do
      expect(logger_stub).to have_received(:add).with(severity, nil, message)
    end
  end
end
