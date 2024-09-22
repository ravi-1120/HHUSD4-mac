function setWindowAfterLogin(e) {
    console.log("redirecting"),
    //window.location.href = "?screenToRender=editProfile"
    window.top.location.href = "https://msdlogin--hhusd4.sandbox.my.site.com/healtheq/dih-login"
}
function setWindowAfterRegistration(e) {
    console.log("redirecting"),
    window.top.location.href = "https://msdlogin--hhusd4.sandbox.my.site.com/healtheq/dih-login"
    //window.location.href = "?screenToRender=editProfile"
}
function setWindowAfterRegistrationNoLogin(e) {
    console.log("redirecting"),
    window.location.href = "?screenToRender=emailVerificationNotification"
}
function setNavigationForLoggedOutUser(e) {
    window.location.href = "index.html"
}
window.DigitalIdentityHub.addModule({
    name: "Web",
    init: function() {
        janrain.settings.tokenUrl = "https:" === document.location.protocol ? "https://<HIP Url>" : "http://<HIP Url>",
        janrain.settings.capture.federateXdReceiver = "https://<HIP Url>/xd_receiver.html",
        janrain.settings.capture.federateLogoutUri = "https://<HIP Url>/logout.html",
        janrain.settings.capture.federateLogoutCallback = function() {}
        ,
        janrain.settings.capture.redirectUri = "https://msdlogin--hhusd4.sandbox.my.site.com/healtheq/dih-login",
        window.DigitalIdentityHub.settings.enableFrontEndDeeplinking = !1,
        window.DigitalIdentityHub.settings.htmlTokens.loginPath = "index.html",
        window.DigitalIdentityHub.settings.htmlTokens.healtheqHomePath = "https://msdlogin--hhusd4.sandbox.my.site.com/healtheq/dih-login",
        window.DigitalIdentityHub.settings.htmlTokens.editProfilePath = "index.html?screenToRender=editProfile"
    },
    ready: function() {
        janrain.events.onCaptureLoginSuccess.addHandler(setWindowAfterLogin),
        janrain.events.onCaptureRegistrationSuccess.addHandler(setWindowAfterRegistration),
        janrain.events.onCaptureRegistrationSuccessNoLogin.addHandler(setWindowAfterRegistrationNoLogin),
        janrain.events.onCaptureSessionEnded.addHandler(setNavigationForLoggedOutUser),
        janrain.events.onCaptureExpiredToken.addHandler(setNavigationForLoggedOutUser),
        janrain.events.onCaptureAccessDenied.addHandler(setNavigationForLoggedOutUser),
        janrain.events.onCaptureRenderComplete.addHandler((function(e) {
            if ("traditionalRegistration" == e.screen) {
                var t = new google.maps.places.Autocomplete(document.getElementById("capture_traditionalRegistration_address"));
                t.setComponentRestrictions({
                    country: ["us"]
                }),
                t.addListener("place_changed", (function(e) {
                    var n = t.getPlace();
                    function a(e) {
                        var t = n.address_components.find((function(t) {
                            return t.types.some((function(t) {
                                return t == e
                            }
                            ))
                        }
                        ));
                        return t ? t.short_name : ""
                    }
                    document.getElementById("capture_traditionalRegistration_address").value = "".concat(a("street_number"), " ").concat(a("route"), " "),
                    document.getElementById("capture_traditionalRegistration_address").focus(),
                    document.getElementById("capture_traditionalRegistration_address").blur(),
                    document.getElementById("capture_traditionalRegistration_addressCity").value = a("locality"),
                    document.getElementById("capture_traditionalRegistration_addressCity").focus(),
                    document.getElementById("capture_traditionalRegistration_addressCity").blur(),
                    document.getElementById("capture_traditionalRegistration_address_state").value = a("administrative_area_level_1"),
                    document.getElementById("capture_traditionalRegistration_address_state").focus(),
                    document.getElementById("capture_traditionalRegistration_address_state").blur(),
                    document.getElementById("capture_traditionalRegistration_addressPostalCode").value = a("postal_code"),
                    document.getElementById("capture_traditionalRegistration_addressPostalCode").focus(),
                    document.getElementById("capture_traditionalRegistration_addressPostalCode").blur()
                }
                ))
            }
        }
        )),
        janrain.events.onCaptureRenderComplete.addHandler((function(e) {
            if ("editProfile" == e.screen) {
                var t = new google.maps.places.Autocomplete(document.getElementById("capture_editProfile_address"));
                t.setComponentRestrictions({
                    country: ["us"]
                }),
                t.addListener("place_changed", (function(e) {
                    var n = t.getPlace();
                    function a(e) {
                        var t = n.address_components.find((function(t) {
                            return t.types.some((function(t) {
                                return t == e
                            }
                            ))
                        }
                        ));
                        return t ? t.short_name : ""
                    }
                    document.getElementById("capture_editProfile_address").value = "".concat(a("street_number"), " ").concat(a("route"), " "),
                    document.getElementById("capture_editProfile_address").dispatchEvent(new Event("change")),
                    document.getElementById("capture_editProfile_address").focus(),
                    document.getElementById("capture_editProfile_address").blur(),
                    document.getElementById("capture_editProfile_addressCity").value = a("locality"),
                    document.getElementById("capture_editProfile_addressCity").dispatchEvent(new Event("change")),
                    document.getElementById("capture_editProfile_addressCity").focus(),
                    document.getElementById("capture_editProfile_addressCity").blur(),
                    document.getElementById("capture_editProfile_address_state").value = a("administrative_area_level_1"),
                    document.getElementById("capture_editProfile_address_state").dispatchEvent(new Event("change")),
                    document.getElementById("capture_editProfile_address_state").focus(),
                    document.getElementById("capture_editProfile_address_state").blur(),
                    document.getElementById("capture_editProfile_addressPostalCode").value = a("postal_code"),
                    document.getElementById("capture_editProfile_addressPostalCode").dispatchEvent(new Event("change")),
                    document.getElementById("capture_editProfile_addressPostalCode").focus(),
                    document.getElementById("capture_editProfile_addressPostalCode").blur()
                }
                ))
            }
        }
        ))
    }
}),
window.DigitalIdentityHub.start();
