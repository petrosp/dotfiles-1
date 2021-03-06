{- xmonad.hs
 - Author: Jelle van der Waa ( jelly1 )
 -}

-- Import stuff
import XMonad
import qualified XMonad.StackSet as W
import qualified XMonad.StackSet as Z
import qualified Data.Map as M
import XMonad.Util.EZConfig(additionalKeys)
import System.Exit
import Graphics.X11.Xlib
import System.IO

-- actions
import XMonad.Actions.CycleWS
import XMonad.Actions.WindowGo
import qualified XMonad.Actions.Submap as SM
import XMonad.Actions.GridSelect
import XMonad.Actions.FloatKeys
import XMonad.Actions.Submap

-- utils
import XMonad.Util.Run
import qualified XMonad.Prompt as P
import XMonad.Prompt.Shell
import XMonad.Prompt
import XMonad.Prompt.AppendFile (appendFilePrompt)
import XMonad.Prompt.RunOrRaise
import XMonad.Util.NamedWindows (getName)
import Graphics.X11.ExtraTypes.XF86
import XMonad.Util.Scratchpad
import XMonad.Util.NamedScratchpad

-- hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName

-- layouts
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Reflect
import XMonad.Layout.IM
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Grid
import XMonad.Layout.ComboP
import XMonad.Layout.Column
import XMonad.Layout.Named
import XMonad.Layout.TwoPane
-- import XMonad.Layout.LayoutModifier

-- Data.Ratio for IM layout
import Data.Ratio ((%))
import Data.List (isInfixOf)

import XMonad.Hooks.EwmhDesktops

-- Main --
main = do
  xmproc <- spawnPipe "xmobar ~/.xmonad/xmobar.hs"
  spawn "~/bin/autostart.sh"
  spawn "trayer --edge top --align right --SetDockType true --SetPartialStrut true --expand true --width 15 --height 12 --transparent true --tint 0x000000"
  xmonad $ withUrgencyHook NoUrgencyHook $ defaultConfig  {
    manageHook = manageDocks <+> myManageHook
      , layoutHook = myLayoutHook
      , borderWidth = myBorderWidth
      , normalBorderColor = myNormalBorderColor
      , focusedBorderColor = myFocusedBorderColor
      , keys = myKeys
      , modMask = myModMask
      , terminal = myTerminal
      , workspaces = myWorkspaces
      , focusFollowsMouse = True
      , logHook = dynamicLogWithPP $ xmobarPP
      { ppOutput = hPutStrLn xmproc
        , ppTitle = xmobarColor "blue" "" . shorten 50
          , ppLayout = const "" -- to disable the layout info on xmobar
      }
      , startupHook = ewmhDesktopsStartup >> setWMName "LG3D"
  }

-- hooks
-- automaticly switching app to workspace
-- http://www.haskell.org/haskellwiki/Xmonad/General_xmonad.hs_config_tips
-- http://www.haskell.org/haskellwiki/Xmonad/Config_archive/John_Goerzen%27s_Configuration
-- resource (also known as appName) is the first element in WM_CLASS(STRING) 
-- className is the second element in WM_CLASS(STRING) 
-- title is WM_NAME(STRING)
-- stringProperty "WM_WINDOW_ROLE" =? "presentationWidget" --> doFloat
myManageHook :: ManageHook
myManageHook = composeAll . concat $
  [ [ isFullscreen --> doFullFloat ]
  , [ isDialog --> doCenterFloat ]
  , [ (className =? "Firefox" <&&> appName =? "Navigator") --> doShift "2:web" ]
  , [ (className =? "Firefox" <&&> appName =? "Dialog") --> doCenterFloat ]
  , [ className =? "Pidgin" --> doShift "2:web" ]
  , [ className =? "Empathy" --> doShift "2:web" ]
  , [ className =? "Revelation" --> doShift "3:revelation" ]
  , [ className =? "Skype" --> doShift "2:web" ]
  , [ stringProperty "WM_WINDOW_ROLE" =? "CallWindow" --> doShift "6:misc" ]
  , [ className =? "Steam" --> doShift "7:games" ]
  , [ className =? "Terminator" --> doShift "1:term" ]
  , [ className =? "urxvt" --> doShift "1:term" ]
  , [ className =? "Trayer" --> doIgnore ]
  , [ className =? "VirtualBox" --> doShift "4:virt" ]
  , [ className =? "Xmessage" --> doCenterFloat ]
  , [ className =? "Pavucontrol" --> doFloat ]
  , [ className =? "chromium-browser" --> doShift "2:web" ]
  , [ className =? "deluge" --> doShift "5:download" ]
  , [ (appName =? "sun-awt-X11-XFramePeer" <&&> className =? "jd-Main") --> doShift "5:download" ]
  , [ (appName =? "sun-awt-X11-XFramePeer" <&&> className =? "JDownloader") --> doShift "5:download" ]
  , [ className =? "trayer" --> doIgnore ]
  , [ className =? "warzone2100" --> doShift "7:games" ]
  , [ fmap ("libreoffice" `isInfixOf`) className --> doShift "6:misc" ]
  , [ className =? "MPlayer" --> (ask >>= doF . W.sink) ]
  , [ className =? c --> doCenterFloat | c <- myFloatsC ]
  , [ fmap (c `isInfixOf`) className --> doCenterFloat | c <- myMatchAnywhereFloatsC ]
  , [ fmap (c `isInfixOf`) title --> doCenterFloat | c <- myMatchAnywhereFloatsT ]
  ]
  -- what is it for?
    -- should be set in main like manageDocks?
  --, scratchpadManageHook (W.RationalRect 0.125 0.25 0.75 0.5)
  where
  -- filter on class name
  myFloatsC = ["Evince", "Gedit", "mpv", "MPlayer", "net-sourceforge-jnlp-runtime-Boot", "Pavucontrol", "Skype", "Smplayer", "Vlc", "Firefox Preferences"]
  -- filter on any part of the class name
  myMatchAnywhereFloatsC = [ "Foxmarks" ]
  -- filter on any part of the title
  myMatchAnywhereFloatsT = ["VLC"] -- this one is silly for only one string!

-- scratchpads
scratchpads = [ NS "gvim" "gvim -S ~/.vim/sessions/Session.vim" (className =? "Gvim") (customFloating $ W.RationalRect (0) (0) (0) (0)) ]

--logHook
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ customPP { ppOutput = hPutStrLn h }

---- Looks --
---- bar
customPP :: PP
customPP = defaultPP {
  ppHidden = xmobarColor "#00FF00" ""
  , ppCurrent = xmobarColor "#FF0000" "" . wrap "[" "]"
  , ppUrgent = xmobarColor "#FF0000" "" . wrap "*" "*"
  , ppLayout = xmobarColor "#FF0000" ""
  , ppTitle = xmobarColor "#00FF00" "" . shorten 80
  , ppSep = "<fc=#0033FF> | </fc>"
}

-- some nice colors for the prompt windows to match the dzen status bar.
myXPConfig = defaultXPConfig {
  font  = "Inconsolata-16"
  , fgColor = "#0096d1"
  , bgColor = "#000000"
  , bgHLight    = "#000000"
  , fgHLight    = "#FF0000"
  , position = Top
  , historySize = 512
  , showCompletionOnTab = True
  , historyFilter = deleteConsecutive
}

--LayoutHook
myLayoutHook = onWorkspace "1:term" fullL $ onWorkspace "2:web" webL $ onWorkspace "4:virt" fullL $  onWorkspace "5:download" fullL $ onWorkspace "7:games" full $ standardLayouts
  where
  standardLayouts = avoidStruts $ (tiled ||| reflectTiled ||| Mirror tiled ||| Grid ||| Full)

  --Layouts
  tiled = smartBorders (ResizableTall 1 (2/100) (1/2) [])
  reflectTiled = (reflectHoriz tiled)
  full = noBorders Full

  --Im Layout
  --Show pidgin tiled left and skype right
  --  imLayout = avoidStruts $ smartBorders $ withIM ratio pidginRoster $ reflectHoriz $ withIM skypeRatio skypeRoster (tiled ||| reflectTiled ||| Grid) where
  --  chatLayout = Grid
  --  ratio = (1%9)
--    skypeRatio = (1%8)
  --  pidginRoster = And (ClassName "Pidgin") (Role "buddy_list")
  --  skypeRoster = (ClassName "Skype")     `And`
  --  (Not (Title "Options")) `And`
  --  (Not (Role "Chats"))    `And`
  --  (Not (Role "CallWindowForm"))
  --Weblayout
  webL = avoidStruts $ tiled ||| reflectHoriz tiled

  --VirtualLayout
  fullL = avoidStruts $ full

-------------------------------------------------------------------------------
---- Terminal --
myTerminal :: String
myTerminal = "urxvt"

-------------------------------------------------------------------------------
-- Keys/Button bindings --
-- modmask
myModMask :: KeyMask
myModMask = mod3Mask

-- borders
myBorderWidth :: Dimension
myBorderWidth = 1
myNormalBorderColor, myFocusedBorderColor :: String
myNormalBorderColor = "#333333"
myFocusedBorderColor = "#306EFF"

--Workspaces
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1:term", "2:web", "3:revelation", "4:virt", "5:download", "6:misc" , "7:games"]

-- keys
myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
  -- killing programs
  [ ((modMask, xK_Return), spawn $ XMonad.terminal conf)
  , ((modMask .|. shiftMask, xK_c ), kill)

  -- opening program launcher / search engine
  ,((modMask , xK_p), shellPrompt myXPConfig)

  -- GridSelect
  , ((modMask, xK_g), goToSelected defaultGSConfig)

  -- Display key
  --, ("<XF86Display>", spawn "xrandr --auto")

  -- layouts
  , ((modMask, xK_space ), sendMessage NextLayout)
  , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)
  , ((modMask, xK_b ), sendMessage ToggleStruts)

  -- floating layer stuff
  , ((modMask, xK_t ), withFocused $ windows . W.sink)

  -- refresh'
  , ((modMask, xK_n ), refresh)

  -- focus
  , ((modMask, xK_Tab ), windows W.focusDown)
  , ((modMask, xK_j ), windows W.focusDown)
  , ((modMask, xK_k ), windows W.focusUp)
  , ((modMask, xK_m ), windows W.focusMaster)

  -- swapping
  , ((modMask .|. shiftMask, xK_Return), windows W.swapMaster)
  , ((modMask .|. shiftMask, xK_j ), windows W.swapDown )
  , ((modMask .|. shiftMask, xK_k ), windows W.swapUp )

  -- increase or decrease number of windows in the master area
  , ((modMask , xK_comma ), sendMessage (IncMasterN 1))
  , ((modMask , xK_period), sendMessage (IncMasterN (-1)))

  -- resizing
  , ((modMask, xK_h ), sendMessage Shrink)
  , ((modMask, xK_l ), sendMessage Expand)
  , ((modMask .|. shiftMask, xK_h ), sendMessage MirrorShrink)
  , ((modMask .|. shiftMask, xK_l ), sendMessage MirrorExpand)

  -- scratchpad
  , ((modMask,  xK_f ),  namedScratchpadAction scratchpads "gvim")
  , ((modMask,  xK_x ),  safeSpawn "xscreensaver-command" ["--lock"] )

  --Spotify
  -- , ((modMask , xK_a ), safeSpawn "dbus-send" ["--print-reply"," --dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.Previous"] )
  -- , ((modMask, xK_s ), safeSpawn "dbus-send" ["--print-reply", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.PlayPause"] )
  -- , ((0, xF86XK_AudioPlay ), safeSpawn "dbus-send" ["--print-reply", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.PlayPause"] )
  -- , ((modMask, xK_d ), safeSpawn "dbus-send" ["--print-reply", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.Next"] )

  --Launching programs
  -- , ((0, xF86XK_Favorites ), safeSpawn "")
  -- , ((0, xF86XK_Mail ), runOrRaise "thunderbird" (className =? "Thunderbird"))
  -- , ((0, xF86XK_Messenger ), runOrRaise "pidgin" (className =? "Pidgin"))

  -- , ((0, 0x1008ff18 ), runOrRaise "aurora" (className =? "Aurora"))
  , ((0, xF86XK_Calculator ), safeSpawn "gnome-calculator" [])
  -- , ((0, xF86XK_Display ), spawn "bash /home/jelle/bin/xrandr-laptop")

  -- volume control
  , ((0, xF86XK_AudioRaiseVolume ), safeSpawn "pactl" ["set-sink-volume","alsa_output.pci-0000_00_1b.0.analog-stereo", "--", "+10% "])
  , ((0, xF86XK_AudioLowerVolume ), safeSpawn "pactl" ["set-sink-volume","alsa_output.pci-0000_00_1b.0.analog-stereo", "--", "-10% "])
  , ((0, xF86XK_AudioMute ), safeSpawn "pactl" ["set-sink-mute", "alsa_output.pci-0000_00_1b.0.analog-stereo", "toggle"])

  -- brightness control
  , ((0 , 0x1008ff03 ), safeSpawn "xbacklight" ["-inc", "10"])
  , ((0 , 0x1008ff02 ), safeSpawn "xbacklight" ["-dec","10"])

  -- toggle trackpad
  , ((modMask .|. shiftMask, xK_t ), safeSpawn "/home/jelle/bin/trackpad-toggle.sh" [] )

  -- quit, or restart
  , ((modMask .|. shiftMask, xK_q ), io (exitWith ExitSuccess))
  , ((modMask , xK_q ), restart "xmonad" True)
  ]
  ++
  -- mod-[1..9] %! Switch to workspace N
  -- mod-shift-[1..9] %! Move client to workspace N
  [((m .|. modMask, k), windows $ f i)
  | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
  , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
  ++
  -- mod-[w,e] %! switch to twinview screen 1/2
  -- mod-shift-[w,e] %! move window to screen 1/2
  [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
  | (key, sc) <- zip [xK_w, xK_e ] [0..]
  , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
