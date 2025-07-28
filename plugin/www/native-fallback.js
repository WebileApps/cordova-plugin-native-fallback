module.exports = {
  triggerErrorFallback: function (success, error) {
    cordova.exec(success, error, "NativeFallback", "triggerErrorFallback", []);
  }
};