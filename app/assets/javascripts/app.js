/*jshint asi: true*/

var app = angular.module("F2J", ["ng-rails-csrf"])

app.controller("AppController", ["$scope", "api", function($scope, api) {
  $scope.ready = true

  $scope.compile = function() {
    if (!$scope.ready) {
      return
    } else if ($.trim($scope.source)) {
      $scope.ready = false

      api.compile($scope.source, function(data) {
        $scope.status  = data.status
        $scope.message = data.message
        $scope.output  = data.output

        $scope.ready = true
      })
    } else {
      $scope.output = ""
    }
  }

  $scope.run = function() {
    $scope.running = true
    api.run($scope.output, function(data) {
      $scope.result = data.result
      $scope.finished = true
      $scope.running  = false
    })
  }
}])

app.factory("api", ["$http", function($http) {
  var api = {}
  api.compile = function(source, callback) {
    $http
      .post(Routes.compile_path(), {source: source})
      .success(function(data) { callback(data) })
  }
  api.run = function(source, callback) {
    $http
      .post(Routes.run_path(), {source: source})
      .success(function(data) { callback(data) })
  }
  return api
}])
