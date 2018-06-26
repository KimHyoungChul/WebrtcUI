# Introduction
This project is for development of SipVideoCall plugin

# Install
## Dependencies
1. Install NodeJS
2. Install NodeJS dependencies
```
npm install
```

# TestApp development
## Web App
* Prepare Test project
    ```
    cd test && npm install
    ```
* Build & Run
    ```
    npm run -- gulp web:devel
    ```

## Android
* Build
    ```
    npm run -- gulp android:build
    ```
* Run
    ```
    npm run -- gulp android:run
    ```

## Android
* Build
    ```
    npm run -- gulp ios:build
    ```
* Run
    ```
    npm run -- gulp ios:run
    ```

# Plugin Release
```
npm run -- gulp plugin:release
```

# Using the plugin

## Parameters for plugin

1) Outgoing Sip Address
    - outgoing sip address

2) Credentials
    - sip address   (ex: sip:42000000056@sip-dev.phemium.com)
    - sip password  (ex: 582cc4588fbd11ad)
    - sip realm     (ex: sip-dev.phemium.com)
    - sip proxy with trnsport (ex: sip-dev.phemium.com:443?transport=tls)
    - turn parameters

 Turn parameters must define 2 turn servers. Ex:
```	[
	  {
		"address": "sip-dev.phemium.com:20000",
		"realm": "phemium.com",
		"username": "phemiumuser1",
		"password": "phemiumuser1"
	  },
	  {
		"address": "sip-dev.phemium.com:40000",
		"realm": "",
		"username": "",
		"password": ""
	  }
	]
```

3) Call Setting
    - only audio (False: VideoCall, True: AudioCall)
    - download bandwidth
    - upload bandwidth
    - framerate
    - transport mode (UDP, TCP, TLS)
    - encryption mode (NONE, SRTP, DTLS)

4) GUI Setting
    - Language
    - Main Colour
    - Secondary Colour
    - Font Size
    - Font Colour
    - Display Name Mode
    - Consultant Name
    - Call Recording Notification visible
    - Chat Mode
    - Zoom Mode
    - Log Mode

5) Extra Setting
    - Video Call Plugin Version
    - Enduser Plugin Version
    - Consultant Id
    - Email Address For Debug

## For Debug Mode
1) VideoCall plugin can receive from Enduser plugin as parameter
2) While Connecting Screen and Video call screen, if you long click in screen, debug mode will be enabled.
3) If registering and call retrys with any errors, debug mode will be enabled.

## Error Code for Return Values

- 0: No Error
- 1: Permission is Denied
- 2: Registration Failed
- 3: Video Establishing Failed
- 4: Callee is Busy
- 5: Callee Declined
- 6: Callee Not Found
- 7: Init Timeout
- 8: Ring Timeout
- 9: Callee is Not Exist (callee is not user of our SIP)
- 10: No Internet
- 11: UnRegisteration failed