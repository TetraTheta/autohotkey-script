/************************************************************************
 * @description Simple AMP Stack (Apache, MySQL, PHP) control panel
 * @author TetraTheta
 * @date 2026/02/05
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
; #Include "..\Lib\darkMode.ahk" ; I won't use Dark Mode for this
#Include "gui_main.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2026. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Simple AMP Stack control panel
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetMainIcon icon\main.ico ; Default icon
;@Ahk2Exe-SetProductName AMPControlPanel

A_IconTip := "AMPControlPanel" ; Tray icon tip
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon\main.ico")
;@Ahk2Exe-IgnoreEnd

; ----
; File & Directory
; ----
ApacheDir := "app/apache"
MySQLDir := "app/mysql"
PHPDir := "app/php"

ApacheAccessLog := "tmp/apache_log/apache_access.log"
ApacheErrorLog := "tmp/apache_log/apache_error.log"
PHPErrorLog := "tmp/php_log/php_error.log"
MySQLErrorLog := "tmp/mysql_log/mysql_error.log"
MySQLSlowLog := "tmp/mysql_log/mysql_slow.log"

ApacheConf := ApacheDir "\conf\httpd.conf"
PHPIni := PHPDir "\php.ini"
MySQLIni := MySQLDir "\my.ini"

a := MainGUI()
a.Show()
a.AddLog("main", "Hello, world!")
