<?php
namespace Alarm;

require __DIR__ . '/vendor/autoload.php';

class Controller {
  function __construct($intrusion_sensors, $pin_reader, $speaker) {
    $this->intrusion_sensors = $intrusion_sensors;
    $this->pin_reader = $pin_reader;
    $this->speaker = $speaker;
    $this->setState('off');
    $this->state_machine = new \SM\StateMachine\StateMachine(
      $this,
      array(
        'graph' => 'alarm_state',
        'states' => array('on', 'off', 'alerting'),
        'transitions' => array(
          'turn_on' => array(
            'from' => array('off'),
            'to' => 'on'
          ),
          'turn_off' => array(
            'from' => array('on', 'alerting'),
            'to' => 'off',
          ),
          'breach' => array(
            'from' => array('on'),
            'to' => 'alerting',
          )
        ),
        'callbacks' => array(
          'after' => array(
            'to-alerting' => array(
              'to' => 'alerting',
              'do' => function() { $this->speaker->turn_on(); }
            ),
            'to-off' => array(
              'to' => 'off',
              'do' => function() { $this->speaker->turn_off(); }
            )
          )
        )
      )
    );
  }

  function read_all() {
    $this->latest_pin_reader_reading = $this->pin_reader->read();
    $this->latest_intrusion_sensor_readings = array_map(
      function ($intrusion_sensor) { return $intrusion_sensor->read(); },
      $this->intrusion_sensors,
    );

    if ($this->latest_pin_reader_reading == 'PIN_VALID') {
      $this->state_machine->apply('turn_on', true) or $this->state_machine->apply('turn_off', true);
    } else if ($this->is_breached()) {
      $this->state_machine->apply('breach', true);
    }
  }

  function getState(): string {
    return $this->state;
  }

  function setState(string $state) {
    $this->state = $state;
  }

  private function is_breached(): bool {
    $breaches = array_filter(
      $this->latest_intrusion_sensor_readings,
      function ($intrusion_sensor_reading) { return $intrusion_sensor_reading == 'BREACH'; }
    );
    return count($breaches) > 0;
  }
}
