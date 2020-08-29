describe("Alarm", function() {
  // Fake objects that will help testing
  const IntrusionSensor = require('./helpers/fakes/intrusion_sensor')
  const PinReader = require('./helpers/fakes/pin_reader')
  const Speaker = require('./helpers/fakes/speaker')
  const Alarm = require('../src/alarm')

  var sensor1, sensor2, pinReader, speaker, alarm

  beforeEach(function() {
    sensor1 = new IntrusionSensor('OK')
    sensor2 = new IntrusionSensor('OK')
    pinReader = new PinReader('IDLE')
    speaker = new Speaker()
    alarm = new Alarm({
      intrusionSensors: [sensor1, sensor2],
      pinReader: pinReader,
      speaker: speaker
    });
  })

  describe("when the alarm is off", function() {
    beforeEach(function() {
      expect(alarm).toBeOff()
    })

    describe("when a valid pin is entered", function() {
      beforeEach(function() {
        pinReader.nextReading = 'PIN_VALID'
      })

      it("turns the alarm on", function() {
        alarm.readAll()
        expect(alarm).toBeOn()
      })
    })

    describe("when a sensor returns a breach", function() {
      beforeEach(function() {
        sensor2.nextReading = 'BREACH'
      })

      it("doesn't turn the speaker on", function() {
        alarm.readAll()
        expect(speaker).toBeOff()
      })
    })
  })

  describe("when the alarm is on", function() {
    beforeEach(function() {
      // Turn the alarm on
      pinReader.nextReading = 'PIN_VALID'
      alarm.readAll()
      expect(alarm).toBeOn()
    })

    describe("when a valid pin is entered", function() {
      beforeEach(function() {
        pinReader.nextReading = 'PIN_VALID'
      })

      it("turns the alarm off", function() {
        alarm.readAll()
        expect(alarm).toBeOff()
      })

      describe("when the speaker was on", function() {
        beforeEach(function() {
          speaker.turnOn()
          expect(speaker).toBeOn()
        })

        it("turns the speaker off", function() {
          alarm.readAll()
          expect(speaker).toBeOff()
        })
      })
    })

    describe("when a sensor returns a breach", function() {
      beforeEach(function() {
        sensor2.nextReading = 'BREACH'
      })

      it("turns the speaker on", function() {
        alarm.readAll()
        expect(speaker).toBeOn()
      })
    })
  })
});
