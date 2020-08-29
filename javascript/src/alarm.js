var StateMachine = require('javascript-state-machine')

class Alarm {
  constructor({ intrusionSensors, pinReader, speaker }) {
    this.intrusionSensors = intrusionSensors
    this.pinReader = pinReader
    this.speaker = speaker
    this.fsm = new StateMachine({
      init: 'off',
      transitions: [
        { name: 'pinValidEntered',   from: 'off',     to: 'on'      },
        { name: 'pinValidEntered',   from: 'on',      to: 'off'     },
        { name: 'pinValidEntered',   from: 'beeping', to: 'off'     },
        { name: 'perimeterBreached', from: 'on',      to: 'beeping' },
      ],
      methods: {
        onEnterBeeping: () => { this.speaker.turnOn() },
        onEnterOff: () => { this.speaker.turnOff() },
        onInvalidTransition: () => { }
      }
    })
  }

  readAll() {
    this.latestPinReaderReading = this.pinReader.read()
    this.latestIntrusionSensorReadings = this.intrusionSensors.map(is => is.read())

    if (this.latestPinReaderReading === 'PIN_VALID')
      this.fsm.pinValidEntered()

    if (this.latestIntrusionSensorReadings.find(r => r === 'BREACH'))
      this.fsm.perimeterBreached()
  }

  get state() {
    return this.fsm.state
  }
}

module.exports = Alarm
