<?php

require __DIR__ . '/alarm.php';
require __DIR__ . '/spec/fakes.php';

describe('Alarm\Controller', function() {
  // Helpers
  function alarm_is_on($controller): bool { return $controller->getState() == 'on'; }
  function alarm_is_off($controller): bool { return $controller->getState() == 'off'; }

  beforeEach(function() {
    $this->sensor_1 = new Fake\IntrusionSensor('OK');
    $this->sensor_2 = new Fake\IntrusionSensor('OK');
    $this->pin_reader = new Fake\PinReader('IDLE');
    $this->speaker = new Fake\Speaker;

    $this->controller = new Alarm\Controller(
      [$this->sensor_1, $this->sensor_2],
      $this->pin_reader,
      $this->speaker
    );
  });

  context('when the alarm is off', function() {
    beforeEach(function() {
      assert(alarm_is_off($this->controller));
    });

    context('when a valid pin is entered', function() {
      beforeEach(function() {
        $this->pin_reader->set_next_read('PIN_VALID');
      });

      it('turns the alarm on', function() {
        $this->controller->read_all();
        assert(alarm_is_on($this->controller));
      });
    });

    context('when a sensor returns a breach', function() {
      beforeEach(function() {
        $this->sensor_2->set_next_read('BREACH');
      });

      it("doesn't turn the speaker on", function() {
        $this->controller->read_all();
        assert($this->speaker->is_off());
      });
    });
  });

  context('when the alarm is on', function() {
    beforeEach(function() {
      // Turn the alarm on
      $this->pin_reader->set_next_read('PIN_VALID');
      $this->controller->read_all();
      assert(alarm_is_on($this->controller));
    });

    context('when a valid pin is entered', function() {
      beforeEach(function() {
        $this->pin_reader->set_next_read('PIN_VALID');
      });

      it('turns the alarm off', function() {
        $this->controller->read_all();
        assert(alarm_is_off($this->controller));
      });

      context('when the speaker was on', function() {
        beforeEach(function() {
          $this->speaker->turn_on();
          assert($this->speaker->is_on());
        });

        it('turns the speaker off', function() {
          $this->controller->read_all();
          assert($this->speaker->is_off());
        });
      });
    });

    context('when a sensor returns a breach', function() {
      beforeEach(function() {
        $this->sensor_2->set_next_read('BREACH');
      });

      it('turns the speaker on', function() {
        $this->controller->read_all();
        assert($this->speaker->is_on());
      });
    });
  });
});
