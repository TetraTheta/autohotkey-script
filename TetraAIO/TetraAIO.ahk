/**
 * TetraAIO v1.1.0 : All of my stuff are included!
 */

/**
 * Default Configs
 */
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance, Force
#Persistent
#MaxThreadsPerHotkey, 4

; Define Tray Icon
Menu, Tray, Icon, %A_ScriptDir%\..\assets\normal.ico, 1
Menu, Tray, Tip, TetraAIO v1.1.0


/**
 * Default Variables
 */
hotkeyAudio := true ; Hotkey status of Audio hotkey [Enabled]
hotkeyFoobar2000 := true ; Hotkey status of Foobar2000 hotkey (along with Audio hotkey) [Enabled]
hotkeyMouse := true ; Hotkey status of Mouse hotkey [Enabled]
; AudioHotkey specific
foobar2000Path :=
Devices := {}


/**
 * Build ContextMenu
 */
Menu, Tray, NoStandard ; Remove all default context menu items
Menu, Tray, Add, TetraAIO [Enabled], labelBlank ; By default, TetraAIO will be enabled so the name has 'Enabled'
Menu, Tray, Default, TetraAIO [Enabled] ; Make this item default so that no other items are selected by default
Menu, Tray, Disable, TetraAIO [Enabled] ; Also, this item don't need to do anything because it is just for information
Menu, Tray, Add ; Add separator
; Start of submenu Audio (AudioHotkey)
Menu, submenuAudio, Add, README, labelREADMEAudio
Menu, submenuAudio, Icon, README, shell32.dll, 78
Menu, submenuAudio, Default, README
Menu, submenuAudio, Add ; Add separator (submenuAudio)
Menu, submenuAudio, Add, Play with &Speaker, labelPlayWithSpeaker
Menu, submenuAudio, Icon, Play with &Speaker, ddores.dll, 5
Menu, submenuAudio, Add, Play with &Headset, labelPlayWithHeadset
Menu, submenuAudio, Icon, Play with &Headset, ddores.dll, 7
Menu, submenuAudio, Add ; Add separator (submenuAudio)
Menu, submenuAudio, Add, Reset all volume (Admin Required), labelResetVolume
Menu, submenuAudio, Add ; Add separator (submenuAudio)
Menu, submenuAudio, Add, AudioHotkey [Enabled], labelToggleAudioHotkey
Menu, submenuAudio, Check, AudioHotkey [Enabled]
Menu, submenuAudio, Add, foobar2000 Volume Change [Enabled], labelToggleFoobar2000Hotkey
Menu, submenuAudio, Check, foobar2000 Volume Change [Enabled]
Menu, Tray, Add, &AudioHotkey, :submenuAudio
Menu, Tray, Icon, &AudioHotkey, ddores.dll, 2
; End of submenu Audio
Menu, Tray, Add ; Add separator
; Start of submenu Mouse (MouseHotkey)
Menu, submenuMouse, Add, README, labelREADMEMouse
Menu, submenuMouse, Icon, README, shell32.dll, 78
Menu, submenuMouse, Default, README
Menu, submenuMouse, Add ; Add separator (submenuMouse)
Menu, submenuMouse, Add, G102IC, labelUseG102IC
Menu, submenuMouse, Icon, G102IC, mstscax.dll, 6 ; Wired Icon (I guess)
Menu, submenuMouse, Add, M590, labelUseM590
Menu, submenuMouse, Icon, M590, netshell.dll, 103 ; Bluetooth Icon
Menu, submenuMouse, Add ; Add separator (submenuMouse)
Menu, submenuMouse, Add, MouseHotkey [Enabled], labelToggleMouseHotkey
Menu, submenuMouse, Check, MouseHotkey [Enabled]
Menu, Tray, Add, &MouseHotkey, :submenuMouse
Menu, Tray, Icon, &MouseHotkey, ddores.dll, 29
; End of submenu Mouse
Menu, Tray, Add ; Add separator
; Start of submenu Dev
Menu, submenuDev, Add, Open Inspector, labelDevInspector
Menu, submenuDev, Icon, Open Inspector, shell32.dll, 3
Menu, submenuDev, Add, Reload TetraAIO, labelDevReload
Menu, submenuDev, Icon, Reload TetraAIO, shell32.dll, 239
Menu, submenuDev, Add, Suspend TetraAIO, labelDevSuspend
Menu, submenuDev, Icon, Suspend TetraAIO, ieframe.dll, 39
Menu, Tray, Add, Dev Tools, :submenuDev
Menu, Tray, Icon, Dev Tools, shell32.dll, 160
; End of submenu Dev
Menu, Tray, Add ; Add separator
Menu, Tray, Add, &Exit, labelQuitProgram

; If TetraAIO is run as Administrator, no need to mention 'Admin Required'
If (A_IsAdmin) {
    Menu, submenuAudio, Rename, Reset all volume (Admin Required), Reset all volume
}


/**
 * Define Hotkeys
 */
!^F1::functionSetAudioDevice("Speaker")
!^F2::functionSetAudioDevice("Headset")
!^F5::functionSetMouse("G102IC")
!^F6::functionSetMouse("M590")


; QUICK NOTE: Why separated label and function?
; Hotkeys only accept function, ContextMenu only accepts label.

/**
* Define Labels : Things that exposed
*/

; Common

labelBlank: ; This does nothing.
Return

labelQuitProgram:
ExitApp

; AudioHotkey

labelREADMEAudio:
functionREADME("Audio")
Return

labelPlayWithSpeaker:
functionSetAudioDevice("Speaker")
Return

labelPlayWithHeadset:
functionSetAudioDevice("Headset")
Return

labelResetVolume:
If (A_IsAdmin) {
    RunWait, sc stop Audiosrv,,hide
    RunWait, sc stop AudioEndpointBuilder,,hide
    RegDelete, HKCU\Software\Microsoft\Internet Explorer\LowRegistry\Audio\PolicyConfig\PropertyStore
    RunWait, sc start Audiosrv,,hide
} Else {
    MsgBox, 4, Administrator privilege is required!,TetraAIO process doesn't have Administrator privilege.`nDo you want to restart TetraAIO with Administrator privilege?`nPlease re-do 'Reset all volume' after TetraAIO is restarted.
    IfMsgBox, Yes
    {
        Run *Runas "%A_ScriptFullPath%"
    }
}
Return

labelToggleAudioHotkey:
If (hotkeyAudio = true) { ; AudioHotkey is enabled
    hotkeyAudio := false
    Menu, submenuAudio, Uncheck, AudioHotkey [Enabled]
    Menu, submenuAudio, Rename, AudioHotkey [Enabled], AudioHotkey [Disabled]
    Hotkey, !^F1, Off
    Hotkey, !^F2, Off
    Return
}
If (hotkeyAudio = false) { ; AudioHotkey is disabled
    hotkeyAudio := true
    Menu, submenuAudio, Check, AudioHotkey [Disabled]
    Menu, submenuAudio, Rename, AudioHotkey [Disabled], AudioHotkey [Enabled]
    Hotkey, !^F1, On
    Hotkey, !^F2, On
    Return
}
Return

labelToggleFoobar2000Hotkey:
If (hotkeyFoobar2000 = true) { ; foobar2000 volume change is enabled
    hotkeyFoobar2000 := false
    Menu, submenuAudio, Uncheck, foobar2000 Volume Change [Enabled]
    Menu, submenuAudio, Rename, foobar2000 Volume Change [Enabled], foobar2000 Volume Change [Disabled]
    Return
}
If (hotkeyFoobar2000 = false) { ; foobar2000 volume change is disabled
    hotkeyFoobar2000 := true
    Menu, submenuAudio, Check, foobar2000 Volume Change [Disabled]
    Menu, submenuAudio, Rename, foobar2000 Volume Change [Disabled], foobar2000 Volume Change [Enabled]
    Return
}
Return

; MouseHotkey

labelREADMEMouse:
functionREADME("Mouse")
Return

labelUseG102IC:
functionSetMouse("G102IC")
Return

labelUseM590:
functionSetMouse("M590")
Return

labelToggleMouseHotkey:
If (hotkeyMouse = true) { ; MouseHotkey is enabled
    hotkeyMouse := false
    Menu, submenuMouse, Uncheck, MouseHotkey [Enabled]
    Menu, submenuMouse, Rename, MouseHotkey [Enabled], MouseHotkey [Disabled]
    Return
}
If (hotkeyMouse = false) { ; MouseHotkey is disabled
    hotkeyMouse := true
    Menu, submenuMouse, Check, MouseHotkey [Disabled]
    Menu, submenuMouse, Rename, MouseHotkey [Disabled], MouseHotkey [Enabled]
    Return
}
Return

; submenu Dev

labelDevInspector:
ListVars
Return

labelDevReload:
functionChangeStatus("Reload")
Return

labelDevSuspend:
functionChangeStatus("Suspend")
Return


/**
 * Function : Things that are hidden, not seen by others
 */

; Common

functionREADME(README) {
    Switch README
    {
        Case "Audio":
            MsgBox, 64, How to use AudioHotkey, These functions are provided with hotkey function.`nCtrl + Alt + F1 : Play with Speaker`nCtrl + Alt + F2 : Play with Headset`n`nAlso, if you checked 'foobar2000 Volume Change', these hotkey will change foobar2000's volume too.
            Return
        Case "Mouse":
            MsgBox, 64, How to use MouseHotkey, These functions are provided with hotkey function.`nCtrl + Alt + F5 : Use Logitech G102IC`nCtrl + Alt + F6 : Use Logitech M590
            Return
        Default:
            MsgBox, 64, ERROR, ERROR! No arguments are given!
    }
}

; AudioHotkey

functionSetAudioDevice(audioDevice) {
    global Devices
    global hotkeyFoobar2000
    functionAudioHotkey()
    Switch audioDevice
    {
        Case "Speaker":
            SetDefaultEndpoint(GetDeviceID(Devices, "스피커"))
            SetDefaultEndpoint(GetDeviceID(Devices, "Speaker"))
            If (hotkeyFoobar2000 = true) {
                functionFoobar2000SetVolume(17)
            }
            Return
        Case "Headset":
            SetDefaultEndpoint(GetDeviceID(Devices, "헤드셋 이어폰"))
            SetDefaultEndpoint(GetDeviceID(Devices, "Headset Earphone"))
            If (hotkeyFoobar2000 = true) {
                functionFoobar2000SetVolume(35)
            }
            Return
        Default:
            Return
    }
}

functionFoobar2000SetVolume(newVolume) {
    global foobar2000Path
    Process, Exist, foobar2000.exe
    If ErrorLevel {
        foobar2000Path := functionGetFullPathEXE(ErrorLevel)
        If (newVolume < 0) {
            MsgBox, 16, ERROR, Volume value must above 0!
            Return
        } Else If (newVolume >= 0 and newVolume < 3) {
            Run, %foobar2000Path% /command:"Set to -0 dB"
            functionFoobar2000DownCommand(newVolume, 0)
            Return
        } Else If (newVolume >= 3 and newVolume < 6) {
            Run, %foobar2000Path% /command:"Set to -3 dB"
            functionFoobar2000DownCommand(newVolume, 3)
            Return
        } Else If (newVolume >= 6 and newVolume < 18) {
            Run, %foobar2000Path% /command:"Set to -6 dB"
            functionFoobar2000DownCommand(newVolume, 6)
            Return
        } Else If (newVolume >= 18 and newVolume < 21) {
            Run, %foobar2000Path% /command:"Set to -18 dB"
            functionFoobar2000DownCommand(newVolume, 18)
            Return
        } Else If (newVolume >= 21 and newVolume < 100) {
            Run, %foobar2000Path% /command:"Set to -21 dB"
            functionFoobar2000DownCommand(newVolume, 21)
            Return
        } Else If (newVolume >= 100) {
            Run, %foobar2000Path% /command:"Mute"
            Return
        }
    }
    Return
}

functionFoobar2000DownCommand(newVolume, diff) {
    global foobar2000Path
    tempVolume := newVolume - diff
    While (tempVolume > 0) {
        Run, %foobar2000Path% /command:"Down"
        tempVolume--
    }
}

functionGetFullPathEXE(pid) {
	For process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessId="pid)
		Return process.ExecutablePath
}

; MouseHotkey

functionSetMouse(mouseDevice) {
    Switch mouseDevice
    {
        Case "G102IC":
            DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "Ptr", 9, "UInt", 0)
            Return
        Case "M590":
            DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "Ptr", 7, "UInt", 0)
            Return
        Default:
            MsgBox, ERROR
            Return
    }
    Return
}

; Dev

functionChangeStatus(newStatus) {
    Switch newStatus
    {
        Case "Reload":
            MsgBox, 292, Are you sure?, This will restart TetraAIO!`nAre you sure about it?
            IfMsgBox Yes
                Reload
            Else
                Return
            Return
        Case "Suspend":
            If (A_IsSuspended = true) { ; Script is suspended
                Suspend, Off
                MsgBox, Enabling TetraAIO
                Menu, submenuDev, Rename, Enable TetraAIO, Suspend TetraAIO
                Menu, submenuDev, Icon, Suspend TetraAIO, ieframe.dll, 39
                Menu, Tray, Rename, TetraAIO [Suspended], TetraAIO [Enabled]
                Menu, Tray, Icon, %A_ScriptDir%\..\assets\normal.ico, 1
                Return
            }
            If (A_IsSuspended = false) { ; Script is not suspended
                Suspend, On
                MsgBox, Suspending TetraAIO
                Menu, submenuDev, Rename, Suspend TetraAIO, Enable TetraAIO
                Menu, submenuDev, Icon, Enable TetraAIO, ieframe.dll, 40
                Menu, Tray, Rename, TetraAIO [Enabled], TetraAIO [Suspended]
                Menu, Tray, Icon, %A_ScriptDir%\..\assets\suspend.ico, 1
                Return
            }
            Return
        Default:
            Return
    }
}


; #######################
; # Change Audio Device #
; #######################
; https://www.autohotkey.com/boards/viewtopic.php?t=49980
functionAudioHotkey() {
    global Devices
    IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

    ; IMMDeviceEnumerator::EnumAudioEndpoints
    ; eRender = 0, eCapture, eAll
    ; 0x1 = DEVICE_STATE_ACTIVE
    DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
    ObjRelease(IMMDeviceEnumerator)

    ; IMMDeviceCollection::GetCount
    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", DeviceCount, "UInt")

    Loop % (DeviceCount)
    {
        ; IMMDeviceCollection::Item
        DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")

        ; IMMDevice::GetId
        DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
        DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)

        ; IMMDevice::OpenPropertyStore
        ; 0x0 = STGM_READ
        DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
        ObjRelease(IMMDevice)

        ; IPropertyStore::GetValue
        VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
        VarSetCapacity(PROPERTYKEY, 20)
        DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
        NumPut(14, &PROPERTYKEY + 16, "UInt")
        DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
        DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16") ; LPWSTR PROPVARIANT.pwszVal
        DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8)) ; LPWSTR PROPVARIANT.pwszVal
        ObjRelease(IPropertyStore)
        
        ObjRawSet(Devices, DeviceName, DeviceID)
    }
    ObjRelease(IMMDeviceCollection)
    Return
}

SetDefaultEndpoint(DeviceID) {
    IPolicyConfig := ComObjCreate("{870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
    ObjRelease(IPolicyConfig)
}

GetDeviceID(Devices, Name) {
    For DeviceName, DeviceID in Devices
        If (InStr(DeviceName, Name))
            Return DeviceID
}
