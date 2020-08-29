<?php
namespace Fake;

class Reader {
  function __construct(string $default_read) {
    $this->default_read = $default_read;
    $this->is_next_read_defined = false;
  }

  function set_next_read(string $next_read) {
    $this->is_next_read_defined = true;
    $this->next_read = $next_read;
  }

  function read(): string {
    if ($this->is_next_read_defined) {
      $this->is_next_read_defined = false;
      return $this->next_read;
    } else {
      return $this->default_read;
    }
  }
}

class IntrusionSensor extends Reader { }
class PinReader extends Reader { }

class Speaker {
  function __construct() {
    $this->state = 'off';
  }

  function turn_on() {
    $this->state = 'on';
  }

  function turn_off() {
    $this->state = 'off';
  }

  function is_on(): bool {
    return $this->state == 'on';
  }

  function is_off(): bool {
    return $this->state == 'off';
  }
}
