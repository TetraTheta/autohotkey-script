# BlueStacksMultiClick

Did you know that you can configure BlueStacks to press the same place multiple times with a single keyboard key press? But there is a major flaw in that. You can't configure it to press the screen in short intervals.

That is why this script, abbreviated BSMC, exists. It sends keystrokes to the BlueStacks window very quickly with a single keystroke.

## Configuration

First of all, you have to configure BlueStacksMultiClick for actual use. It can't automatically detect the window of BlueStacks or its name.

### BlueStacks

* Window Title  
  Instance name of the BlueStacks you want to send multiple click signal to.
* Click Key  
  You have to pre-configure BlueStacks to press the screen once when you press the keyboard key first. Then, for multiple clicks, you must configure BSMC to press which key.
  Refer to [this documentation](https://www.autohotkey.com/docs/v2/KeyList.htm) for the key name of the key.

### General

* Multiple Click Key  
  This is what you have to press if you want to do multiple clicks.  
  Refer to [this documentation](https://www.autohotkey.com/docs/v2/KeyList.htm) for the key name of the key.
* Multiple Click Interval  
  The time between each click, in milliseconds.
* Click Count  
  Count of clicks.

### Changelog

* **v1.0.0**: [2023.01.15] Initial release
