beforeEach(function () {
  jasmine.addMatchers({
    toBeOff: function () {
      return {
        compare: function (statefulObject) {
          return { pass: statefulObject.state == 'off' }
        }
      };
    },
    toBeOn: function () {
      return {
        compare: function (statefulObject) {
          return { pass: statefulObject.state == 'on' }
        }
      };
    }
  });
});
