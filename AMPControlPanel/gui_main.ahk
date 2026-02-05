#Requires AutoHotkey v2.0

; Embed images
;@Ahk2Exe-AddResource *10 resource\apache.png
;@Ahk2Exe-AddResource *10 resource\mariadb.png
;@Ahk2Exe-AddResource *10 resource\mysql.png
;@Ahk2Exe-AddResource *10 resource\php.png

Join(sep, params*) {
  for idx, param in params
    str .= param . sep
  return SubStr(str, 1, -StrLen(sep))
}

class MainGUI extends Gui {
  btnAStart := ""
  btnALocalWeb := ""
  btnAConfig := ""
  btnALogs := ""
  btnMStart := ""
  btnMConsole := ""
  btnMConfig := ""
  btnMLogs := ""
  cbPersistent := ""
  lbAPIDs := ""
  lbAPorts := ""
  lbAVersion := ""
  lbMPIDs := ""
  lbMPorts := ""
  lbMVersion := ""
  menuAConfig := ""
  menuALogs := ""
  menuMConfig := ""
  menuMLLogs := ""
  menuLog := ""
  tbLog := ""

  __New() {
    super.__New(, "AMP Control Panel")
    this.SetFont("s9", "Segoe UI")

    ; --- GroupBox - Status ---
    gbStatusX := 12, gbStatusY := 13
    this.AddGroupBox("x" gbStatusX " y" gbStatusY " w659 h144", "Status")

    ; Headers (Bold)
    this.SetFont("bold")
    this.AddText("x" (gbStatusX + 44) " y" (gbStatusY + 32) " w70 h15 Center", "Module")
    this.AddText("x" (gbStatusX + 120) " y" (gbStatusY + 32) " w100 h15 Center", "PIDs")
    this.AddText("x" (gbStatusX + 226) " y" (gbStatusY + 32) " w100 h15 Center", "Ports")
    this.AddText("x" (gbStatusX + 332) " y" (gbStatusY + 32) " w318 h15 Center", "Actions")
    this.SetFont("norm")

    ; Apache Row
    this.AddPicture("x" (gbStatusX + 6) " y" (gbStatusY + 64) " w32 h32", this.GetResPath("apache"))
    this.AddText("x" (gbStatusX + 44) " y" (gbStatusY + 72) " w70 h15 Center", "Apache") ; Module
    this.lbAPIDs := this.AddText("x" (gbStatusX + 120) " y" (gbStatusY + 72) " w100 h15 Center", "00000, 00000") ; PIDs
    this.lbAPorts := this.AddText("x" (gbStatusX + 226) " y" (gbStatusY + 72) " w100 h15 Center", "00000, 00000") ; Ports
    this.btnAStart := this.AddButton("x" (gbStatusX + 335) " y" (gbStatusY + 65) " w75 h29", "Start")
    this.btnALocalWeb := this.AddButton("x" (gbStatusX + 416) " y" (gbStatusY + 65) " w75 h29", "Local Web")
    this.btnAConfig := this.AddButton("x" (gbStatusX + 497) " y" (gbStatusY + 65) " w75 h29", "Config")
    this.btnALogs := this.AddButton("x" (gbStatusX + 578) " y" (gbStatusY + 65) " w75 h29", "Logs")

    ; MySQL Row
    this.AddPicture("x" (gbStatusX + 6) " y" (gbStatusY + 104) " w32 h32", this.GetResPath("mysql"))
    this.AddText("x" (gbStatusX + 44) " y" (gbStatusY + 112) " w70 h15 Center", "MySQL") ; Module
    this.lbMPIDs := this.AddText("x" (gbStatusX + 120) " y" (gbStatusY + 112) " w100 h15 Center", "00000") ; PIDs
    this.lbMPorts := this.AddText("x" (gbStatusX + 226) " y" (gbStatusY + 112) " w100 h15 Center", "00000, 00000") ; Ports
    this.btnMStart := this.AddButton("x" (gbStatusX + 335) " y" (gbStatusY + 105) " w75 h29", "Start")
    this.btnMConsole := this.AddButton("x" (gbStatusX + 416) " y" (gbStatusY + 105) " w75 h29", "Console")
    this.btnMConfig := this.AddButton("x" (gbStatusX + 497) " y" (gbStatusY + 105) " w75 h29", "Config")
    this.btnMLogs := this.AddButton("x" (gbStatusX + 578) " y" (gbStatusY + 105) " w75 h29", "Logs")

    ; --- Log Box ---
    this.SetFont("s9", "Consolas")
    this.tbLog := this.Add("Edit", "x12 y164 w659 h282 +Multi +ReadOnly +HScroll +VScroll -Wrap")
    this.SetFont("s9", "Segoe UI")

    ; --- GroupBox - Tools ---
    _gbToolsX := 677, _gbToolsY := 13
    this.AddGroupBox("x" _gbToolsX " y" _gbToolsY " w131 h144", "Tools")
    this.AddButton("x" (_gbToolsX + 6) " y" (_gbToolsY + 24) " w119 h29", "webroot")
    this.AddButton("x" (_gbToolsX + 6) " y" (_gbToolsY + 61) " w119 h29", "Shell")
    this.AddButton("x" (_gbToolsX + 6) " y" (_gbToolsY + 98) " w119 h29", "Netstat")

    ; --- GroupBox - Information ---
    gbInfoX := 677, gbInfoY := 165
    this.AddGroupBox("x" gbInfoX " y" gbInfoY " w131 h281", "Information")
    lbApache := this.AddText("x" (gbInfoX + 6) " y" (gbInfoY + 21) " w115 h15", "Apache: 00.00.00")
    lbMySQL := this.AddText("x" (gbInfoX + 6) " y" (gbInfoY + 44) " w115 h15", "MariaDB: 00.00.00")

    ; --- Footer Controls ---
    this.cbPersistent := this.AddCheckBox("x12 y453 w182 h19 Checked", "Minimize to Tray when closed")
    this.AddText("x708 y454 w100 h15 Right", "AMP v1.0.0")

    ; --- Initiate Menus ---
    this.CreateMenus()

    this.btnAConfig.OnEvent("Click", (*) => this.ShowMenu(this.menuAConfig, this.btnAConfig))
    this.btnALogs.OnEvent("Click", (*) => this.ShowMenu(this.menuALogs, this.btnALogs))
    this.btnMConfig.OnEvent("Click", (*) => this.ShowMenu(this.menuMConfig, this.btnMConfig))
    this.btnMLogs.OnEvent("Click", (*) => this.ShowMenu(this.menuMLLogs, this.btnMLogs))
    this.tbLog.OnEvent("ContextMenu", (ctrl, *) => this.menuLog.Show())
    ; --- Persistent ---
    Persistent(true)
    this.cbPersistent.OnEvent("Click", (ctrl, *) => Persistent(ctrl.Value))
    this.OnEvent("Close", this.HandleClose)
  }

  CreateMenus() {
    ; Apache Config
    this.menuAConfig := Menu()
    this.menuAConfig.Add("Apache (httpd.conf)", (*) => "")
    this.menuAConfig.Add("PHP (php.ini)", (*) => "")
    this.menuAConfig.Add()
    this.menuAConfig.Add("<Browse> Apache", (*) => "")
    this.menuAConfig.Add("<Browse> PHP", (*) => "")

    ; Apache Logs
    this.menuALogs := Menu()
    this.menuALogs.Add("Apache (apache_access.log)", (*) => "")
    this.menuALogs.Add("Apache (apache_error.log)", (*) => "")
    this.menuALogs.Add("PHP (php_error.log)", (*) => "")
    this.menuALogs.Add()
    this.menuALogs.Add("<Browse> Apache Logs", (*) => "")
    this.menuALogs.Add("<Browse> PHP Logs", (*) => "")

    ; MySQL Config
    this.menuMConfig := Menu()
    this.menuMConfig.Add("MySQL (my.ini)", (*) => "")
    this.menuMConfig.Add()
    this.menuMConfig.Add("<Browse> MySQL", (*) => "")

    ; MySQL Logs
    this.menuMLLogs := Menu()
    this.menuMLLogs.Add("MySQL (mysql_error.log)", (*) => "")
    this.menuMLLogs.Add("MySQL (mysql_slow.log)", (*) => "")
    this.menuMLLogs.Add()
    this.menuMLLogs.Add("<Browse> MySQL Logs", (*) => "")
    this.menuMLLogs.Add("<Browse> MySQL data", (*) => "")

    ; Log
    this.menuLog := Menu()
    this.menuLog.Add("Select All", (*) => SendMessage(0x00B1, 0, -1, this.tbLog.Hwnd))
    this.menuLog.Add("Copy", (*) => ControlSend("^c", this.tbLog))
    this.menuLog.Add()
    this.menuLog.Add("Clear Log", (*) => this.tbLog.Value := "")
  }

  AddLog(category, text) {
    this.tbLog.Value .= "`n" FormatTime(, "HH:mm:ss") " [" category "] " text
  }

  GetResPath(name) => A_IsCompiled ? "HRES:*10:" name : "resource/" name ".png"

  HandleClose(*) {
    if this.cbPersistent.Value {
      this.Hide()
      return true
    }
  }

  UpdateMenuItem(menuObj, itemText, filePath) {
    if FileExist(filePath)
      menuObj.Enable(itemText)
    else
      menuObj.Disable(itemText)
  }

  SetApachePIDs(pids*) => this.lbAPIDs.Text := Join(", ", pids)

  SetApachePorts(ports*) => this.lbAPorts.Text := Join(", ", ports)

  SetApacheVersion(version) => this.lbAVersion.Text := "Apache: " version

  SetMySQLPIDs(pids*) => this.lbMPIDs.Text := Join(", ", pids)

  SetMySQLPorts(ports*) => this.lbMPorts.Text := Join(", ", ports)

  SetMySQLVersion(version) => this.lbMVersion.Text := "MySQL: " version

  Show(opt := "w820 h478") => super.Show(opt)

  /**
   * @param {Menu} menuObj
   * @param {Gui.Control} btnObj
   */
  ShowMenu(menuObj, btnObj) {
    if menuObj = this.menuAConfig {
      this.UpdateMenuItem(menuObj, "Apache (httpd.conf)", ApacheConf)
      this.UpdateMenuItem(menuObj, "PHP (php.ini)", PHPIni)
    }
    else if menuObj = this.menuALogs {
      this.UpdateMenuItem(menuObj, "Apache (apache_access.log)", ApacheAccessLog)
      this.UpdateMenuItem(menuObj, "Apache (apache_error.log)", ApacheErrorLog)
      this.UpdateMenuItem(menuObj, "PHP (php_error.log)", PHPErrorLog)
    }
    else if (menuObj = this.menuMConfig) {
      this.UpdateMenuItem(menuObj, "MySQL (my.ini)", MySQLIni)
    }
    else if (menuObj = this.menuMLLogs) {
      this.UpdateMenuItem(menuObj, "MySQL (mysql_error.log)", MySQLErrorLog)
      this.UpdateMenuItem(menuObj, "MySQL (mysql_slow.log)", MySQLSlowLog)
    }

    btnObj.GetPos(&x, &y, &w, &h)
    menuObj.Show(x, y + h)
  }
}
