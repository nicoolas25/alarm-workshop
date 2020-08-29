require 'bundler/inline'

gemfile do
  source "https://rubygems.org"
  gem "rspec"
  gem "state_machines"
end

module Alarm
  class IntrusionSensor
    BREACH = :breach
    OK = :ok

    def read
      raise NotImplementedError
    end
  end

  class PinReader
    IDLE = :idle
    PIN_INVALID = :pin_invalid
    PIN_VALID = :pin_valid

    def read
      raise NotImplementedError
    end
  end

  class Speaker
    def turn_on
      raise NotImplementedError
    end

    def turn_off
      raise NotImplementedError
    end
  end

  class Controller
    MAX_INVALID_PIN = 3

    state_machine :alarm_state, initial: :off do
      state :off do
        transition to: :on,       on: :pin_valid,   if: :all_intrusion_sensors_ok?
        transition to: :alerting, on: :pin_invalid, if: :max_invalid_pin_about_to_be_reached?
        transition to: :off,      on: :pin_invalid
      end

      state :on do
        transition to: :alerting, on: [:breach, :pin_invalid]
        transition to: :off,      on: :pin_valid
      end

      state :alerting do
        transition to: :off, on: :pin_valid
      end

      after_transition to: :alerting do |controller, _|
        controller.speaker.turn_on
      end

      after_transition to: :off do |controller, _|
        controller.speaker.turn_off
      end

      after_transition on: :pin_invalid do |controller, _|
        controller.invalid_pin_count += 1
      end

      after_transition on: :pin_valid do |controller, _|
        controller.invalid_pin_count = 0
      end
    end

    attr_accessor :speaker, :invalid_pin_count

    def initialize(intrusion_sensors:, pin_reader:, speaker:)
      @intrusion_sensors = intrusion_sensors
      @pin_reader = pin_reader
      @speaker = speaker
      @invalid_pin_count = 0
      super()
    end

    def read_all
      pin_reader_state = @pin_reader.read
      @intrusion_sensor_latest_states = @intrusion_sensors.map(&:read)

      if pin_reader_state == PinReader::PIN_VALID
        pin_valid
      elsif pin_reader_state == PinReader::PIN_INVALID
        pin_invalid
      elsif @intrusion_sensor_latest_states.any? { |s| s == IntrusionSensor::BREACH }
        breach
      end
    end

    def max_invalid_pin_about_to_be_reached?
      (@invalid_pin_count + 1) >= MAX_INVALID_PIN
    end

    def all_intrusion_sensors_ok?
      @intrusion_sensor_latest_states.all? { |s| s == IntrusionSensor::OK }
    end
  end
end

require "rspec/autorun"

RSpec.describe Alarm::Controller do
  let(:controller) do
    described_class.new(
      intrusion_sensors: [sensor_1, sensor_2],
      pin_reader: pin_reader,
      speaker: speaker,
    )
  end

  let(:sensor_1) { FakeIntrusionSensor.new(Alarm::IntrusionSensor::OK) }
  let(:sensor_2) { FakeIntrusionSensor.new(Alarm::IntrusionSensor::OK) }
  let(:pin_reader) { FakePinReader.new(Alarm::PinReader::IDLE) }
  let(:speaker) { FakeSpeaker.new.tap(&:turn_off) }

  context "when the alarm is off" do
    before do
      expect(controller.off?).to be true
    end

    context "when a valid pin is entered" do
      before { pin_reader.next_read = Alarm::PinReader::PIN_VALID }

      it "turns the alarm on" do
        expect { controller.read_all }.to change(controller, :on?).to(true)
      end

      context "when a sensor returns a breach" do
        before { sensor_2.next_read = Alarm::IntrusionSensor::BREACH }

        it "doesn't start the alarm" do
          expect { controller.read_all }.not_to change(controller, :on?).from(false)
        end
      end
    end

    context "when a sensor returns a breach" do
      before { sensor_2.next_read = Alarm::IntrusionSensor::BREACH }

      it "doesn't turn the speaker on" do
        expect { controller.read_all }.not_to change(speaker, :on?).from(false)
      end
    end

    context "when an invalid pin is entered 3 times in a row" do
      it "turns the speaker on" do
        # Two invalid pin in a row doesn't trigger the alarm
        pin_reader.next_read = Alarm::PinReader::PIN_INVALID
        controller.read_all
        pin_reader.next_read = Alarm::PinReader::PIN_INVALID
        controller.read_all
        expect(controller).to be_off

        # Turn the alarm on with a valid pin
        pin_reader.next_read = Alarm::PinReader::PIN_VALID
        controller.read_all
        expect(controller).to be_on

        # Turn it back off with a valid pin
        pin_reader.next_read = Alarm::PinReader::PIN_VALID
        controller.read_all
        expect(controller).to be_off

        # We start counting back from zero
        pin_reader.next_read = Alarm::PinReader::PIN_INVALID
        controller.read_all
        expect(controller).to be_off

        pin_reader.next_read = Alarm::PinReader::PIN_INVALID
        controller.read_all
        expect(controller).to be_off

        # An idle read doesn't reset the invalid pin counter
        pin_reader.next_read = Alarm::PinReader::IDLE
        controller.read_all
        expect(controller).to be_off

        # Third pin triggers the alarm and speaker
        pin_reader.next_read = Alarm::PinReader::PIN_INVALID
        controller.read_all
        expect(controller).to be_alerting
        expect(speaker).to be_on
      end
    end
  end

  context "when the alarm is on" do
    before do
      # Turn the alarm on
      pin_reader.next_read = Alarm::PinReader::PIN_VALID
      controller.read_all

      expect(controller).to be_on
    end

    context "when a valid pin is entered" do
      before { pin_reader.next_read = Alarm::PinReader::PIN_VALID }

      it "turns the alarm off" do
        expect { controller.read_all }.to change(controller, :off?).to(true)
      end

      context "when the speaker was on" do
        let(:speaker) { super().tap(&:turn_on) }

        it "turns the speaker off" do
          expect { controller.read_all }.to change(speaker, :off?).to(true)
        end
      end
    end

    context "when an invalid pin is entered" do
      before { pin_reader.next_read = Alarm::PinReader::PIN_INVALID }

      it "turns the speaker on" do
        expect { controller.read_all }.to change(speaker, :on?).to(true)
      end
    end

    context "when a sensor returns a breach" do
      before { sensor_2.next_read = Alarm::IntrusionSensor::BREACH }

      it "turns the speaker on" do
        expect { controller.read_all }.to change(speaker, :on?).to(true)
      end
    end
  end

  class FakeIntrusionSensor
    attr_writer :next_read

    def initialize(default_read)
      @default_read = default_read
    end

    def read
      if defined?(@next_read)
        remove_instance_variable :@next_read
      else
        @default_read
      end
    end
  end

  FakePinReader = Class.new(FakeIntrusionSensor)

  class FakeSpeaker
    def turn_on
      @state = :on
    end

    def turn_off
      @state = :off
    end

    def on?
      @state == :on
    end

    def off?
      @state == :off
    end
  end
end
