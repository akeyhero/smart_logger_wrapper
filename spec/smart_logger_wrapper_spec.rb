require 'spec_helper'
require 'logger'

RSpec.describe SmartLoggerWrapper do
  ORIGINAL_LOGGER_METHODS = %i(debug info warn error fatal unknown)
  DELEGETING_METHODS = %i(<< reopen close log add level debug? level= progname datetime_format= datetime_format formatter sev_threshold sev_threshold= info? warn? error? fatal? progname= formatter=)

  let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub) }
  let(:severity_stub) { double(:severity) }

  let(:logger_stub) { double(:logger) }
  let(:another_logger_stub) { double(:another_logger) }
  let(:arg_stub) { double(:arg) }
  let(:another_arg_stub) { double(:another_arg) }
  let(:message_stub) { double(:message) }
  let(:another_message_stub) { double(:another_message) }

  let(:block_stub) { -> { block_result_stub } }
  let(:block_result_stub) { double(:block_result) }
  let(:block_message_stub) { double(:block_message) }

  before do
    allow(logger_stub).to receive(:add)
    allow(another_logger_stub).to receive(:add)
    allow(smart_logger_wrapper).to receive(:to_message).with(arg_stub).and_return(message_stub)
    allow(smart_logger_wrapper).to receive(:to_message).with(another_arg_stub).and_return(another_message_stub)
    allow(smart_logger_wrapper).to receive(:to_message).with(block_result_stub).and_return(block_message_stub)
  end

  it 'has a version number' do
    expect(SmartLoggerWrapper::VERSION).not_to be nil
  end

  shared_examples_for 'Call with multiple messages and a block' do |method_name, severity|
    describe "##{method_name}" do
      subject! { smart_logger_wrapper.public_send(method_name, arg_stub, another_arg_stub, &block_stub) }

      it { expect(logger_stub).to have_received(:add).with(severity, nil, message_stub).once }
      it { expect(logger_stub).to have_received(:add).with(severity, nil, another_message_stub).once }
      it { expect(logger_stub).to have_received(:add).with(severity, nil, block_message_stub).once }
    end
  end

  it_behaves_like 'Call with multiple messages and a block', :debug,   Logger::DEBUG
  it_behaves_like 'Call with multiple messages and a block', :info,    Logger::INFO
  it_behaves_like 'Call with multiple messages and a block', :warn,    Logger::WARN
  it_behaves_like 'Call with multiple messages and a block', :error,   Logger::ERROR
  it_behaves_like 'Call with multiple messages and a block', :fatal,   Logger::FATAL
  it_behaves_like 'Call with multiple messages and a block', :unknown, Logger::UNKNOWN

  shared_examples_for 'Initialization with multiple loggers' do |method_name, severity|
    let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub, another_logger_stub) }

    describe "##{method_name}" do
      subject! { smart_logger_wrapper.public_send(method_name, arg_stub) }

      it { expect(logger_stub).to have_received(:add).with(severity, nil, message_stub).once }
      it { expect(another_logger_stub).to have_received(:add).with(severity, nil, message_stub).once }
    end
  end

  it_behaves_like 'Initialization with multiple loggers', :debug,   Logger::DEBUG
  it_behaves_like 'Initialization with multiple loggers', :info,    Logger::INFO
  it_behaves_like 'Initialization with multiple loggers', :warn,    Logger::WARN
  it_behaves_like 'Initialization with multiple loggers', :error,   Logger::ERROR
  it_behaves_like 'Initialization with multiple loggers', :fatal,   Logger::FATAL
  it_behaves_like 'Initialization with multiple loggers', :unknown, Logger::UNKNOWN

  shared_examples_for 'Delegation to the wrapped loggers' do |method_name|
    let(:smart_logger_wrapper) { SmartLoggerWrapper.new(logger_stub, another_logger_stub) }

    describe "##{method_name}" do
      let(:return_value_stub) { double(:return_value) }
      let(:another_return_value_stub) { double(:another_return_value) }

      before do
        allow(logger_stub).to receive(method_name).and_return return_value_stub
        allow(another_logger_stub).to receive(method_name).and_return another_return_value_stub
      end

      subject! { smart_logger_wrapper.public_send(method_name, arg_stub, another_arg_stub, &block_stub) }

      it { is_expected.to be return_value_stub }
      it { expect(logger_stub).to have_received(method_name).with(arg_stub, another_arg_stub, &block_stub).once }
      it { expect(another_logger_stub).to have_received(method_name).with(arg_stub, another_arg_stub, &block_stub).once }
    end
  end

  DELEGETING_METHODS.each do |method_name|
    it_behaves_like 'Delegation to the wrapped loggers', method_name
  end

  describe 'private #to_message' do
    let(:dummy_exception) { Class.new(Exception).new }
    let(:dummy_string) { ('a'..'z').to_a.sample(10).join }
    let(:dummy_instance) { Class.new.new }
    let(:inspected_arg_stub) { double(:inspected_arg) }
    let(:backtrace_stub) { double(:backtrace) }
    let(:cleaned_backtrace_stub) { [double(:cleaned_backtrace_line1), double(:cleaned_backtrace_line2)] }

    before do
      allow(smart_logger_wrapper).to receive(:to_message).and_call_original
      allow(dummy_exception).to receive(:backtrace).and_return backtrace_stub
      allow(dummy_exception).to receive(:inspect).and_return inspected_arg_stub
      allow(dummy_instance).to receive(:inspect).and_return inspected_arg_stub
      allow(SmartLoggerWrapper::Utils::Backtrace).to receive(:clean_backtrace).with(backtrace_stub).and_return cleaned_backtrace_stub
    end

    context 'with a string message' do
      subject { smart_logger_wrapper.send(:to_message, dummy_string) }

      it { is_expected.to be dummy_string }
    end

    context 'with an exception' do
      subject { smart_logger_wrapper.send(:to_message, dummy_exception) }

      it { is_expected.to eq ([inspected_arg_stub] + cleaned_backtrace_stub).join("\n") }
    end

    context 'with neither a string message nor an exception' do
      subject { smart_logger_wrapper.send(:to_message, dummy_instance) }

      it { is_expected.to be inspected_arg_stub }
    end
  end

  describe 'private #method_missing' do
    before do
      SmartLoggerWrapper::Options.define_appender :dummy_option, Class.new
    end

    context 'without argument' do
      subject { smart_logger_wrapper.dummy_option }

      it { expect(subject.options).to include :dummy_option }
      it { expect(subject.options[:dummy_option]).to be nil }

      it 'should be cached' do
        is_expected.to be smart_logger_wrapper.dummy_option
      end
    end

    context 'without argument' do
      let(:dummy_arg) { double(:dummy_arg) }

      subject { smart_logger_wrapper.dummy_option(dummy_arg) }

      it { expect(subject.options).to include :dummy_option }
      it { expect(subject.options[:dummy_option]).to be dummy_arg }

      it 'should be cached' do
        is_expected.to be smart_logger_wrapper.dummy_option(dummy_arg)
      end
    end
  end
end
