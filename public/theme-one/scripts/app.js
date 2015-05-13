'use strict';

var saymeapp = angular.module('saymeapp', ['datatables','UserValidation']);

saymeapp.factory('notificationsFactory', function () {
    toastr.options = {
        "showDuration": "1000",
        "hideDuration": "1000",
        "timeOut": "2000",
        "positionClass": "toast-bottom-right",
        "extendedTimeOut": "5000",
        "closeButton":true
    };

    return {
        success: function (text) {
            if (text === undefined) {
                text = '';
            }
            toastr.success("Success. " + text);
        },
        error: function (text) {
            if (text === undefined) {
                text = '';
            }
            toastr.error("Error. " + text);
        }
    };
});

//  Force AngularJS to call our JSON Web Service with a 'GET' rather than an 'OPTION'
//  Taken from: http://better-inter.net/enabling-cors-in-angular-js/
saymeapp.config(['$httpProvider', function ($httpProvider) {
    $httpProvider.defaults.useXDomain = true;
    delete $httpProvider.defaults.headers.common['X-Requested-With'];
}]);

saymeapp
    .controller('registerFormCtrl', function registerFormCtrl($scope,$http, $interval,notificationsFactory) {
        // Used to compare current and new data
        $scope.visitorInfo = {};
        $scope.storedInfo = {};

        $scope.email = "";
        $scope.pass1 = "";
        $scope.pass2 = "";


        // Used to make sure the same sample doesn't appear twice in a row
        $scope.lastSampleIndex = 0;


        // Update visitor object with submitted info
        $scope.update = function(formData) {
            $scope.storedInfo = angular.copy(formData);
        };

        // Reset form will last submitted info
        $scope.reset = function() {
            $scope.visitorInfo = angular.copy($scope.storedInfo);
        };

        // Check for difference between last submitted info
        // and info currently in form fields
        $scope.isUnchanged = function(formData) {
            return angular.equals(formData,$scope.storedInfo);
        };


    });


angular.module('UserValidation', []).directive('validUsername', function () {
    return {
        require: 'ngModel',
        link: function (scope, elm, attrs, ctrl) {
            ctrl.$parsers.unshift(function (viewValue) {
                // Any way to read the results of a "required" angular validator here?
                var isBlank = viewValue === ''
                var invalidLen = !isBlank && (viewValue.length < 5 || viewValue.length > 20)
                ctrl.$setValidity('isBlank', !isBlank)
                ctrl.$setValidity('invalidLen', !invalidLen)
                scope.usernameGood = !isBlank && !invalidChars && !invalidLen

            })
        }
    }
}).directive('validPassword', function () {
    return {
        require: 'ngModel',
        link: function (scope, elm, attrs, ctrl) {
            ctrl.$parsers.unshift(function (viewValue) {
                var isBlank = viewValue === ''
                var invalidLen = !isBlank && (viewValue.length < 8 || viewValue.length > 20)
                ctrl.$setValidity('isBlank', !isBlank);
                ctrl.$setValidity('invalidLen', !invalidLen);
                return viewValue;
            })
        }
    }
}).directive('validPasswordC', function () {
    return {
        require: 'ngModel',
        link: function (scope, elm, attrs, ctrl) {
            ctrl.$parsers.unshift(function (viewValue, $scope) {
                var isBlank = viewValue === ''
                var noMatch = viewValue != scope.registerForm.pass1.$viewValue
                ctrl.$setValidity('isBlank', !isBlank);
                ctrl.$setValidity('noMatch', !noMatch);
                return viewValue;
            })
        }
    }
}).directive('uniqueEmail', ['$http', function($http) {
    return {
        restrict: 'A',
        require: 'ngModel',
        link: function(scope, element, attrs, ctrl) {
            //set the initial value as soon as the input comes into focus
            element.on('focus', function() {
                if (!scope.initialValue) {
                    scope.initialValue = ctrl.$viewValue;
                }
            });
            element.on('blur', function() {

                if (1==1) {

                    //var dataUrl = attrs.url + "?email=" + ctrl.$viewValue;
                    var dataUrl = '/mc?m=' + ctrl.$viewValue
                    //you could also inject and use your 'Factory' to make call
                    $http.get(dataUrl).success(function(data) {

                        if(data === 'true')
                            ctrl.$setValidity('isDuplicate', false);
                        else
                            ctrl.$setValidity('isDuplicate', true);
                    }).error(function(data, status) {
                        //handle server error

                    });
                }
            });
        }
    };
}]);

saymeapp.filter('sumByKey', function () {
    return function (data, key) {
        if (typeof (data) === 'undefined' || typeof (key) === 'undefined') {
            return 0;
        }
        var sum = 0;
        for (var i = data.length - 1; i >= 0; i--) {
            sum += parseInt(data[i][key]);
        }
        return sum;
    };
})

saymeapp.filter('customSum', function () {
    return function (listOfProducts, key) {
        //  Count how many items are in this order
        var total = 0;
        angular.forEach(listOfProducts, function (product) {
//            alert(product + "." + key);
            total += eval("product." + key);
        });
        return total;
    }
});

saymeapp.filter('countItemsInOrder', function () {
    return function (listOfProducts) {
        //  Count how many items are in this order
        var total = 0;
        angular.forEach(listOfProducts, function (product) {
            total += product.Quantity;
        });
        return total;
    }
});

saymeapp.filter('orderTotal', function () {
    return function (listOfProducts) {
        //  Calculate the total value of a particular Order
        var total = 0;
        angular.forEach(listOfProducts, function (product) {
            total += product.Quantity * product.UnitPrice;
        });
        return total;
    }
});

saymeapp.controller('MasterDetailCtrl',
    function ($scope, $http,$interval, notificationsFactory) {

        //  We'll load our list of Customers from our JSON Web Service into this variable
        $scope.listOfRequests = [];
        $scope.loading = true;
        $scope.incomingRequestLabel = "Incoming Request";
        $scope.rt = "";
        $scope.selectedRequest = {requesting_image:"http://placehold.it/350x150"};
        $scope.respdata = {
            rt: "",
            raid: ""
        };
        $scope.submitButtonDisabled = false;

        Array.prototype.contains = function(obj) {
            var i = this.length;
            while (i--) {
                if (this[i].id === obj.id) {
                    return true;
                }
            }
            return false;
        }

        $scope.setRequestsAction = function(data){

            if(data instanceof Array){
                if(data.length <= 0) {
                    $scope.listOfRequests = [];
                    $scope.selectedRequest = null;
                }else{
                    if($scope.listOfRequests.length <= 0) {
                        $scope.listOfRequests = data;
                    }else{
                        var checkFlag = 1;
                        for(var i = 0; i<data.length; i++) {
                            if(!$scope.listOfRequests.contains(data[i])){
                                if(checkFlag == 1){
                                    notificationsFactory.success("Request accepted");
                                    checkFlag = 2;
                                }
                                $scope.listOfRequests.push(data[i]);
                            }
                        }
                        for(var i = 0; i<$scope.listOfRequests.length; i++) {
                            if(!data.contains($scope.listOfRequests[i])){
                                $scope.listOfRequests.splice(i,1);
                            }
                        }
                    }
                }

            }else{

                $scope.listOfRequests  = [];
                $scope.selectRequest(null);
            }


            if($scope.selectedRequest == null){
                if($scope.listOfRequests.length>0){
                    $scope.selectRequest($scope.listOfRequests[0])
                }
            }
            if($scope.listOfRequests.length <= 0){
                $scope.selectRequest(null);
            }
        }
        $scope.getRequests = function(){
            if($scope.listOfRequests.length <= 0){
                $scope.loading = true;
            }
            $http.get('/reqs')
                .success(function (data) {
                    $scope.setRequestsAction(data);
                    $scope.loading = false;
                })
                .error(function (data, status, headers, config) {
                    $scope.errorMessage = "Couldn't load the list of requests, error # " + status;
                    $scope.loading = false;
                });
        }

        $scope.selectRequest = function (val) {
            //  If the user clicks on a <div>, we can get the ng-click to call this function, to set a new selected Customer.
            $scope.selectedRequest = null;
            $scope.selectedRequest = val;
            if(val == null || val.requesting_image==""){
                $scope.selectedRequest = {requesting_image:"http://placehold.it/350x150"};
            }
        }

        $scope.submitForm = function() {

            $scope.respdata = {};
            $scope.respdata["rt"] = $scope.rt;
            $scope.respdata["raid"] = $scope.selectedRequest.id;

            $scope.submitButtonDisabled = true;
            $http.post('/resolverAction', JSON.stringify($scope.respdata)).
                success(function(data, status, headers, config) {
                    $scope.setRequestsAction(data);
                    if($scope.listOfRequests.length > 0){
                        $scope.selectRequest($scope.listOfRequests[0]);
                    }
                    $scope.submitButtonDisabled = false;
                }).
                error(function(data, status, headers, config) {
                        $scope.submitButtonDisabled = false;
                    });
        };

       $interval(function(){
            //$scope.request_count="This DIV is refreshed "+c+" time.";
            $scope.getRequests();

        },5000);
        //setInterval($scope.getRequests, 10000);
        // I am active query for active session
        $interval(function(){
            $scope.notifyUserToSystem();
        },2000);

        $scope.getRequests();

        $scope.notifyUserToSystem = function(){
            $http.post('/iamactive',"").
                success(function(data, status, headers, config) {

                }).
                error(function(data, status, headers, config) {

                });
        }

    });

saymeapp
    .controller('ApiStatusCtrl', function ApiStatusCtrl($scope,$http, $interval,notificationsFactory) {


        $scope.server_status = "UP";
        $scope.request_count = c;
        $scope.responded_count = 0;
        $scope.resolve_time = "8 second (per request)";

        $scope.init = function(){
            $scope.getApiInfo();
        }

        var c=0;
        $interval(function(){
            //$scope.request_count="This DIV is refreshed "+c+" time.";
            $scope.getApiInfo();
            //notificationsFactory.success("Update succedded.");
            c++;
        },4000);



        $scope.getApiInfo = function(timeRange){
            if(timeRange == null){
                timeRange = 60 * 60 * 24 * 7;
            }
            var url = "/apinfo/" + timeRange;
            $http.get(url)
                .success(function (data) {
                    $scope.requestCountLastMinute = data['respondedCount']
                })
                .error(function () {
                });
        };




        $scope.init();


    });

saymeapp
    .controller('ApiStatusCtrlAdmin', function ApiStatusCtrl($scope,$http, $interval,notificationsFactory) {


        $scope.server_status = "UP";

        $scope.init = function(){
            $scope.getReqStat();
        }

        $interval(function(){
            $scope.getReqStat();
        },4000);


        $scope.getReqStat = function(timeRange){
            if(timeRange == null){
                timeRange = 60 * 60 * 24 * 7;
            }
            var url = "/reqstats/" + timeRange;
            $http.get(url)
                .success(function (data) {
                    console.log(data)
                    $scope.errorcnt = data["ERROR"]
                    $scope.notrespondedcnt = data["NOTRESPONDED"]
                    $scope.respondedcnt = data["RESPONDED"]
                    $scope.pendingcnt = data["PENDING"]
                })
                .error(function () {
                });
        };



        $scope.init();


    });

saymeapp
.controller("contactFormCtrl", function($scope,$http, $interval,notificationsFactory){
        $scope.namesurname = "";
        $scope.email = "";
        $scope.message = "";
        $scope.bacon = "";
});