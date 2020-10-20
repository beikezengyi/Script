@ECHO off
cls
:start
ECHO.
ECHO 1. Change Connection1 Static IP "for izumishinnkawa building"
ECHO 2. Change Connection2 Static IP "for i.learing building"
ECHO 3. Change Connection3 Static IP 
ECHO 4. Obtain an IP address automatically
ECHO 5. Exit
set choice=
set /p choice=Type the number to print text.
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto con1
if '%choice%'=='2' goto con2
if '%choice%'=='3' goto con3
if '%choice%'=='4' goto autosearch
if '%choice%'=='5' goto end
ECHO "%choice%" is not valid, try again
ECHO.
goto start
:con1
ECHO izumishinnkawa building
netsh interface ip set address locallan static 172.16.40.240 255.255.0.0 172.16.255.254 1
netsh interface ipv4 set dnsservers locallan static 192.168.1.6
netsh interface ipv4 add dns locallan 172.29.0.101 index=2
goto end

:con2
ECHO i.learing building
netsh interface ip set address locallan static 172.17.0.18 255.255.0.0 172.17.254.254 1
netsh interface ipv4 set dns locallan static 192.168.1.5
netsh interface ipv4 add dns locallan 192.168.1.6 index=2
goto end

:con3
ECHO Connecting Connection 3
netsh interface ip set address locallan static 192.168.0.10 255.255.255.0 192.168.0.1 1
goto end

:autosearch
ECHO obtaining auto IP
ipconfig /renew "Local Area Connection"
goto end

:bye
ECHO BYE
goto end

:end
pause