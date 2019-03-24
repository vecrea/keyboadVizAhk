#NoEnv
#SingleInstance Force
#Warn ClassOverwrite
SendMode Input
SetBatchLines -1
SetTitleMatchMode 2

;; original found here : https://www.autohotkey.com/boards/viewtopic.php?f=76&t=61880&hilit=premiere
;; comments, some additions and removals : krea.city : https://www.youtube.com/channel/UCzDZYbPaUkQd2zUN_ZdJbYg

;; ------------ Here after come the shortcuts -------------------------------------------------------------------------------------------------------------------------------------
TooltipHotkeys := [new PremiereTooltip("V", "Selection tool", "The default tool, used to select clips in the timeline.")
				 , new PremiereTooltip("M", "Track Select tool", "Select all clips on a track from a given point, or select multiple tracks.")
				 , new PremiereTooltip("B", "Ripple Edit tool", "Adjust an edit point and move other clips in the timeline to compensate.")
				 , new PremiereTooltip("N", "Rolling Edit tool", "Adjust an edit point between two clips without affecting the rest of the timeline.")
				 , new PremiereTooltip("R", "Rate Stretch tool", "Change the duration of a clip while simultaneously changing the speed to compensate.")
				 , new PremiereTooltip("X", "Add Edit (custom)", "Add edit at playhead.")
				 , new PremiereTooltip("C", "Razor tool", "Cut a clip (or multiple clips) into two clips.")
				 , new PremiereTooltip("Y", "Slip tool", "Move a clip's in and out points by the same amount simultaneously, so the rest of the timeline is not affected.")
				 , new PremiereTooltip("U", "Slide tool", "Move a clip back and forth in the timeline, while simultaneously adjusting adjacent clips to compensate.")
				 , new PremiereTooltip("P", "Pen tool", "Create control (anchor) points.")
				 , new PremiereTooltip("H", "Hand tool", "Drag the timeline view left and right.")
				 , new PremiereTooltip("Z", "Zoom tool", "Click in the timeline to magnify the view, or drag and select a rectangular area to zoom into.")
				 , new PremiereTooltip("^C", "Copy", "Copy.")
				 , new PremiereTooltip("^V", "Paste", "Paste.")
				 , new PremiereTooltip("J", "Rewind", "Rewind footage at normal speed.")
				 , new PremiereTooltip("K", "Stop", "Stop the footage.")
				 , new PremiereTooltip("L", "Play", "Play footage at normal speed.")]  ;; <---- watch out, don't forget the ] here at the end of the last line
;; ------------ End of the shortcuts -----------------------------------------------------------------------------------------------------------------------------------------------

class PremiereTooltip
{
	static GUI_WIDTH := 400    ;; width of the box
		 , GUI_HEIGHT := 100    ;; height of the box
		 , PADDING := 5         ;; it will be called margin afterwards in the code, but really it's padding (inside margin if you want)
 		 , MARGIN := 50    ;; margin (only used in the ShowDescription)
		 , TEXT_WIDTH := PremiereTooltip.GUI_WIDTH - 2 * PremiereTooltip.PADDING
		 , EXE := "ahk_exe Adobe Premiere Pro.exe"
		 , COLOR_SCHEME := {"BACKGROUND": "1D1D1D"    ;; background color, will be set a little bit transparent later on
						  , "SEPARATOR": "313131"	;; color of the line between title and description
						  , "TITLE": "2D8CEB"
						  , "DESCRIPTION": "A7A7A7"}
		, DELAY := 1500		;; how many milliseconds the tooltip is displayed
		
		
;; constructor for the keybind : hotkey, function, description
	__New(keybind, name, description) {
		;; added to display "CTRL+" in place of "^" in, f.i. "^c" which stands for "CTRL+C"
		IfInString, keybind, ^ 
			{
				keybindTXT:= StrReplace(keybind, "^", "CTRL+")
			}	
			else keybindTXT := keybind
			
		Gui New, +AlwaysOnTop -Caption +ToolWindow +Hwndhwnd
		Gui Color, % this.COLOR_SCHEME.BACKGROUND
		Gui Margin, % this.PADDING, % this.PADDING ;; this Margin thing should be called Padding as it this the margin inside the gui...
		
		;; Name of the function called by shortcut, second argument in the Tooltip
		Gui Font, S20 ;; size of the Title. You have to style the text in the first place, before populating with the title value
		Gui Add, Text, % "c" this.COLOR_SCHEME.TITLE, % name ;; color of the title + The second argument of the Tooltip
		
		;; display the used shortcut in parenthesis, underlined
		Gui Add, Text, % "x+m yp c" this.COLOR_SCHEME.TITLE, % "("
		Gui Font, Underline
		Gui Add, Text, % "x+2 yp c" this.COLOR_SCHEME.TITLE, % keybindTXT
		Gui Font, Norm
		Gui Add, Text, % "x+2 yp c" this.COLOR_SCHEME.TITLE, % ")"
		
		;; Separator and description of what the shortcut does
		Gui Font, S12
		Gui Add, Progress, % Format("xm h2 w{1:} Background{2:} c{2:}", this.TEXT_WIDTH, this.COLOR_SCHEME.SEPARATOR), 100
		Gui Add, Text, % Format("w{1:} Background{2:} c{2:}", this.TEXT_WIDTH, this.COLOR_SCHEME.DESCRIPTION), % description
		Gui Show, % Format("w{} Hide", this.GUI_WIDTH)
		
		;; Get the whole thing to render with a little bit of transparency. 230 is almost opaque (255), the less you have, the most transparent you get
		Gui, +Lastfound
		WinSet, TransColor, this.COLOR_SCHEME.BACKGROUND 230

		;; some dark magic you don't need to touch to preserve the balance of the Force
		hiddenWindowsSetting := A_DetectHiddenWindows
		DetectHiddenWindows On
		WinGetPos, , , , h, % "ahk_id " hwnd
		DetectHiddenWindows % hiddenWindowsSetting
		Gui Add, Progress, % Format("h{} w1 x0 y0 Background{3:} c{3:}", h, this.TEXT_WIDTH, this.COLOR_SCHEME.SEPARATOR), 100
		Gui Add, Progress, % Format("h1 w{} x0 y0 Background{2:} c{2:}", this.GUI_WIDTH, this.COLOR_SCHEME.SEPARATOR), 100
		Gui Add, Progress, % Format("h{} w1 x{} y0 Background{3:} c{3:}", h, this.GUI_WIDTH - 1, this.COLOR_SCHEME.SEPARATOR), 100
		Gui Add, Progress, % Format("h1 w{} x0 y{} Background{3:} c{3:}", this.GUI_WIDTH, h - 1, this.COLOR_SCHEME.SEPARATOR), 100
		keybind := Format("{:L}", keybind) ;; align Left
		this.keybind := keybind
		this.hwnd := hwnd
		
		fn := this.hideDescription.Bind("", hwnd, keybind) ;; calls the hideDescription method, that hides the box...
		Hotkey % Format("~{} Up", keybind), % fn ;; ...when hotkey is released
		
		;; If Premiere is active, activate the hotkeys that will invoke the showDescription function (see below)
		fn := this.showCondition := this.isPremiereActive.Bind("")
		Hotkey If, % fn
			fn := this.showDescription.Bind("", hwnd, keybind) ;; calls the showDescription method, that displays the box
			Hotkey % keybind, % fn
		Hotkey If
		

	}
	
	;; Destructor, when hotkey is released
	__Delete() {
		Hotkey % Format("~{} Up", this.keybind), Off
		fn := this.showCondition
		Hotkey If, % fn
			Hotkey % this.keybind, Off
		Hotkey If
	}

	;; check if the executable in the EXE static are active
	isPremiereActive() {
		return WinActive(PremiereTooltip.EXE) && !A_CaretX
	}

	;; shows the box
	showDescription(hwnd, keybind) {
		WinGetPos x, y, w, h, % PremiereTooltip.EXE
		Gui %hwnd%: Show, % Format("x{} y{} NoActivate", x + PremiereTooltip.MARGIN, h - PremiereTooltip.MARGIN - PremiereTooltip.GUI_HEIGHT )
		
		Send % "{" keybind "}"
	}

	;; hides the box
	hideDescription(hwnd, keybind) {
		sleep, PremiereTooltip.DELAY ;; wait for the duration of DELAY...
		Gui %hwnd%: Hide ;; ...then hide the box
	}
}

