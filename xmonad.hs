import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook

import XMonad.Layout
import XMonad.Layout.ResizableTile
-- import XMonad.Layout.LayoutHints

import XMonad.Actions.SwapWorkspaces
import XMonad.Actions.Warp

import XMonad.Util.EZConfig
import XMonad.Util.Run(spawnPipe)

import qualified Data.Map as M
import qualified XMonad.StackSet as W

import System.IO
import Graphics.X11.ExtraTypes.XF86

-------------------------------------------------------------------------------
-- Main
--
main = do
  dzenLeftBar  <- spawnPipe myXmonadBar
  dzenRightBar <- spawnPipe myStatusBar

  xmonad $ withUrgencyHook NoUrgencyHook $ defaultConfig
      { startupHook        = setWMName "LG3D"
      , modMask            = myModMask
      , terminal           = myTerminal
      , borderWidth        = myBorderWidth
      , normalBorderColor  = myNormalBorderColor
      , focusedBorderColor = myFocusedBorderColor
      , logHook            = myLogHook dzenLeftBar
      , workspaces         = myWorkspaces
      , manageHook         = myManageHook
      , layoutHook         = myLayout
      } `additionalKeys` addKeys

------------------------------------------------------------------------
-- Options and Theme
--
myModMask            = mod4Mask

myTerminal           = "urxvtc"
myBorderWidth        = 2

myWorkspaces = [ "1st"
               , "2nd" 
               , "3rd" 
               , "4th" 
               , "5th" 
               , "6th" 
               , "7th" 
               , "8th" 
               , "9th" 
               ]

myFont = "DroidSansFallback:bold:size=8"

background   = "#111111"
current_line = "#282a2e"
selection    = "#373b41"
foreground   = "#c5c8c6"
comment      = "#969896"
red          = "#cc6666"
orange       = "#de935f"
yellow       = "#f0c674"
green        = "#b5bd68"
aqua         = "#8abeb7"
blue         = "#81a2be"
purple       = "#b294bb"

myNormalBorderColor  = "#3f3f3f"
myFocusedBorderColor = purple

------------------------------------------------------------------------
-- Bars and Helpers
--
makeDmenu :: String -> String
makeDmenu p = "dmenu_run" ++
              " -fn '" ++ myFont     ++ "'" ++
              " -nf '" ++ foreground ++ "'" ++
              " -nb '" ++ background ++ "'" ++
              " -sf '" ++ purple ++ "'" ++
              " -sb '" ++ background ++ "'" ++
              " -p  '" ++ p          ++ "'" ++
              " -i "

dmenuCmd  = makeDmenu "Run:"

myXmonadBar = "dzen2 -e '' -x '0' -y '0' -w '600' -h '16' -ta 'l' -fn '" ++ myFont ++ "' -fg '" ++ foreground ++ "' -bg '" ++ background ++ "'"
myStatusBar = "~/.xmonad/simpleStatus/simpleStatus | dzen2 -e '' -x '600' -w '766' -h '16' -ta r -fn '" ++ myFont ++ "' -fg '" ++ foreground ++ "' -bg '" ++ background ++ "'"

------------------------------------------------------------------------
-- Layouts
--
myLayout = -- layoutHintsToCenter $
           avoidStruts
           $ tiled ||| Full
    where
        tiled = ResizableTall 1 (3/100) (1/2) []

------------------------------------------------------------------------
-- Window Rules
--
myManageHook :: ManageHook
myManageHook = mainManageHook -- <+> namedScratchpadManageHook myScratchPads
    where
        mainManageHook = composeAll $ concat
            [ [isFullscreen        --> doFullFloat]
            , [isDialog            --> doCenterFloat]
            , [className =? c      --> doFloat | c <- myFloats]
            , [title =? t          --> doFloat | t <- myOtherFloats]
            , [title =? center     --> doCenterFloat | center <- myCenterFloats]
            ]
        myFloats       = [ "wine"
                         --, "MPlayer"
                         --, "Gimp"
                         , "Snes9x-gtk"
                         , "Gvbam"
                         , "Skype"
                         , "org-igoweb-cgoban-CGoban"
                         ]

        myCenterFloats = [ "xmessage"
                         , "zenity"
                         , "xfontsel"
                         , "mpv"
                         ]

        myOtherFloats  = [ "Downloads"
                         , "Firefox Preferences"
                         , "Save As..."
                         , "Send file"
                         , "Open"
                         , "File Transfers"
                         ]

------------------------------------------------------------------------
-- Key Bindings
--

-- kill any running dzen and conky processes before recompiling.
-- The -threaded switch for ghc reduces the amount of wakeups per second from xmonad.
cleanStart :: MonadIO m => m ()
cleanStart = spawn $ "for pid in `pgrep simpleBar`; do kill -9 $pid; done && "
                  ++ "for pid in `pgrep dzen2`; do kill -9 $pid; done && "
                  ++ "cd ~/.xmonad; ghc -threaded xmonad.hs; mv xmonad xmonad-x86_64-linux; xmonad --restart"

addKeys :: [((ButtonMask, KeySym), X())]
addKeys =
    [ ((mod4Mask          , xK_p ), spawn dmenuCmd)
    , ((mod4Mask          , xK_m ), spawn "~/bin/menu/menumenu")
    , ((mod4Mask          , xK_o ), spawn "~/bin/menu/mpcmenu")
    , ((mod4Mask          , xK_r ), spawn "feh --bg-fill $(find ~/docs/wallpapers/current -type f | shuf -n1)")
    , ((mod4Mask          , xK_s ), spawn "~/bin/menu/shutdownmenu")
    , ((mod4Mask          , xK_u ), spawn "~/bin/menu/infomenu")
    , ((mod4Mask          , xK_v ), spawn "urxvtc -e alsamixer")

    , ((mod4Mask              , xK_q), banishScreen LowerLeft)
    , ((mod4Mask .|. shiftMask, xK_q), spawn "")
    , ((mod4Mask .|. shiftMask .|. controlMask, xK_q), cleanStart)
    , ((mod4Mask .|. shiftMask .|. controlMask, xK_m), spawn "xrandr --output LVDS1 --mode 1366x768 --primary && xrandr --output VGA1 --mode 1920x1080 --right-of LVDS1")

    -- Multimedia keys
    , ((0             , xF86XK_AudioPrev), spawn "mpc prev -q")
    , ((0             , xF86XK_AudioNext), spawn "mpc next -q")
    , ((0             , xF86XK_AudioPlay), spawn "mpc toggle -q")
    , ((0             , xF86XK_AudioStop), spawn "mpc stop -q")
    , ((0             , xF86XK_PowerOff), spawn "~/bin/menu/shutdownmenu")
    -- , ((mod4Mask .|. controlMask , xK_Left) , spawn "mpc -q seek -10")
    -- , ((mod4Mask .|. controlMask , xK_Right), spawn "mpc -q seek -10")


    -- Volume
    , ((0             , xF86XK_AudioLowerVolume), spawn "amixer -q set 'Master' '1-'")
    , ((0             , xF86XK_AudioRaiseVolume), spawn "amixer -q set 'Master' '1+'")
    , ((0             , xF86XK_AudioMute)       , spawn "amixer -q set 'Master' 'toggle'")

    , ((mod4Mask          , xK_Down) , spawn "amixer -q set 'Master' '1-'")
    , ((mod4Mask          , xK_Up)   , spawn "amixer -q set 'Master' '1+'")
    -- , ((mod4Mask .|. controlMask , xK_Down) , spawn "amixer -q set 'Speaker' '1-'")
    -- , ((mod4Mask .|. controlMask , xK_Up)   , spawn "amixer -q set 'Speaker' '1+'")

    -- Other Keys
    , ((mod4Mask                  , xK_Print), spawn "scrot -e 'mv $f ~/tmp/'")
    , ((mod4Mask .|. controlMask  , xK_Print), spawn "sleep 0.2 ; scrot -s -e 'mv $f ~/tmp/'")


    -- Brightness
    , ((mod4Mask          , xK_i)   , spawn "~/bin/menu/brightnessmenu")
    , ((mod4Mask          , xK_Left) , spawn "xbacklight -dec 10")
    , ((mod4Mask          , xK_Right), spawn "xbacklight -inc 10")
    ]
    ++
    -- Un-greedy view
    [((m .|. mod4Mask, k), windows $ f i)
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
    ++
    -- Swapping workspaces
    [((mod4Mask .|. controlMask, k), windows $ swapWithCurrent i)
        | (i, k) <- zip myWorkspaces [xK_1 ..]]

------------------------------------------------------------------------
-- Logging/Status Bar
--
myLogHook h = dynamicLogWithPP $ defaultPP
            { ppCurrent = dzenColor purple background . pad
            , ppHidden  = dzenColor foreground background . pad
            , ppVisible = dzenColor purple background . pad

            , ppLayout  = dzenColor purple "" . layoutNames
            , ppTitle   = dzenColor foreground "" . shorten 50

            , ppSep     = "  "
            , ppWsSep   = ""
            , ppOutput  = hPutStrLn h
            , ppOrder   = \(ws:l:_:_) -> [ws,l]
            }
        where
        layoutNames x
            | x == "ResizableTall" = "^i(/home/sanford/.xmonad/icons/tile.xbm)"
            | x == "Full" = "^i(/home/sanford/.xmonad/icons/float.xbm)"
            | otherwise   = x

