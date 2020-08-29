class Readable {
  constructor(defaultReading) {
    this.defaultReading = defaultReading
    this.nextReadingIsSet = false
  }

  set nextReading(value) {
    this.nextReadingIsSet = true
    this.nextReadingValue = value
  }

  read() {
    if (this.nextReadingIsSet) {
      this.nextReadingIsSet = false
      return this.nextReadingValue
    } else {
      return this.defaultReading
    }
  }
}

module.exports = Readable
