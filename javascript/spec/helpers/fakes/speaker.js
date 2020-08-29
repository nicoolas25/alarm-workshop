class Speaker {
  constructor() {
    this.state = 'off'
  }

  turnOn() {
    this.state = 'on'
  }

  turnOff() {
    this.state = 'off'
  }
}

module.exports = Speaker
