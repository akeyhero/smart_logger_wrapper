require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper do
  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:logger_stub) { double(:logger) }
  let(:severity_stub) { double(:severity) }

  before do
    allow(logger_stub).to receive(:add)
  end

  it 'has a version number' do
    expect(SmartLoggerWrapper::VERSION).not_to be nil
  end

  describe '#log' do
    it 'is an alias of #add' do
      expect(smart_logger_wrapper.method(:log)).to eq smart_logger_wrapper.method(:add)
    end
  end

  context 'with multiple messages and a block' do
    let(:message1_stub) { double(:message1, inspect: inspected_message1_stub) }
    let(:message2_stub) { double(:message2, inspect: inspected_message2_stub) }
    let(:inspected_message1_stub) { double(:inspected_message1) }
    let(:inspected_message2_stub) { double(:inspected_message2) }
    let(:block_stub) { -> { block_message_stub } }
    let(:block_message_stub) { double(:block_message, inspect: inspected_block_message_stub) }
    let(:inspected_block_message_stub) { double(:inspected_block_message) }

    describe '#add' do
      subject! { smart_logger_wrapper.add(severity_stub, message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(severity_stub, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(severity_stub, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(severity_stub, nil, inspected_block_message_stub).once }
    end

    describe '#debug' do
      subject! { smart_logger_wrapper.debug(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::DEBUG, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::DEBUG, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::DEBUG, nil, inspected_block_message_stub).once }
    end

    describe '#info' do
      subject! { smart_logger_wrapper.info(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::INFO, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::INFO, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::INFO, nil, inspected_block_message_stub).once }
    end

    describe '#warn' do
      subject! { smart_logger_wrapper.warn(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::WARN, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::WARN, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::WARN, nil, inspected_block_message_stub).once }
    end

    describe '#error' do
      subject! { smart_logger_wrapper.error(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::ERROR, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::ERROR, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::ERROR, nil, inspected_block_message_stub).once }
    end

    describe '#fatal' do
      subject! { smart_logger_wrapper.fatal(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::FATAL, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::FATAL, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::FATAL, nil, inspected_block_message_stub).once }
    end

    describe '#unknown' do
      subject! { smart_logger_wrapper.unknown(message1_stub, message2_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(Logger::UNKNOWN, nil, inspected_message1_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::UNKNOWN, nil, inspected_message2_stub).once }
      it { expect(logger_stub).to have_received(:add).with(Logger::UNKNOWN, nil, inspected_block_message_stub).once }
    end
  end

  describe '#add' do
    let(:message_stub) { double(:message, inspect: inspected_message_stub, backtrace: backtrace_stub) }
    let(:inspected_message_stub) { double(:inspected_message) }
    let(:backtrace_stub) { double(:backtrace) }
    let(:cleaned_backtrace_stub) { [double(:cleaned_backtrace_line1), double(:cleaned_backtrace_line2)] }
    let(:is_message_string) { false }
    let(:is_message_exception) { false }

    before do
      allow(String).to receive(:===).with(message_stub).and_return is_message_string
      allow(Exception).to receive(:===).with(message_stub).and_return is_message_exception
      allow(SmartLoggerWrapper::Utils::Backtrace).to receive(:clean_backtrace).with(backtrace_stub).and_return(cleaned_backtrace_stub)
    end

    subject! { smart_logger_wrapper.add(severity_stub, message_stub) }

    context 'with a string message' do
      let(:is_message_string) { true }

      it 'logs the message as it is' do
        expect(logger_stub).to have_received(:add).with(severity_stub, nil, message_stub)
      end
    end

    context 'with an exception' do
      let(:is_message_exception) { true }

      it 'logs the inspected message with its backtrace' do
        expected = ([inspected_message_stub] + cleaned_backtrace_stub).join("\n")
        expect(logger_stub).to have_received(:add).with(severity_stub, nil, expected)
      end
    end

    context 'with neither a string message nor an exception' do
      it 'logs the message after inspected' do
        expect(logger_stub).to have_received(:add).with(severity_stub, nil, inspected_message_stub)
      end
    end
  end
end
