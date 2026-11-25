@echo off
REM Starts the app using the bundled Maven Wrapper (no Maven install needed).
REM Prerequisite: XAMPP Control Panel -> start MySQL.
set ADMIN_PASSWORD=Admin@12345
call mvnw.cmd spring-boot:run -Dmaven.test.skip=true
pause
