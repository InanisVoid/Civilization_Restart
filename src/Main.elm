module Main exposing (main,subscriptions,key)
import Browser
import Browser.Dom exposing (getViewport)
import Browser.Events exposing (onAnimationFrameDelta,onKeyDown,onKeyUp, onResize)
import Html.Events exposing (keyCode)
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Messages exposing (Msg(..),SkillMsg(..))
import Task
import View exposing (view)
import Update
import Model exposing (Model, defaultMe, State(..), Sentence, Side(..), Role(..), sentenceInit,mapToViewBox)
import Map.MapDisplay exposing (mapInit)
import Map.MapGenerator exposing (roomInit)
-- import Html.Styled exposing (..)
-- import Html.Styled.Attributes exposing (..)

-- import Debug
-- import Model exposing (Model)

main : Program Value Model Msg
main =
    Browser.element
        { view =  View.view 
        , init = \value -> (init, Task.perform GetViewport getViewport)
        , update = Update.update        
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onAnimationFrameDelta Tick
        , onKeyUp (Decode.map (key False) keyCode)
        , onKeyDown (Decode.map (key True) keyCode)
        , onResize Resize
        ]

key : Bool -> Int -> Msg
key on keycode =
    case keycode of
        87 ->
            MoveUp on
        65 ->
            MoveLeft on
        68 ->
            MoveRight on       
        83 ->
            MoveDown on
        70 ->
            if on then
                NextFloor
            else
                Noop
        13 ->
            if on then
                NextSentence
            else
                Noop
        71 ->
            ShowDialogue
<<<<<<< HEAD
=======
        49 ->
            ChangeWeapon 1
        50 ->
            ChangeWeapon 2
        51 ->
            ChangeWeapon 3
        52 ->
            ChangeWeapon 4
        81 ->
            if on then
                ChangeWeapon_
            else Noop
>>>>>>> dev
        66 ->
            if on then
                SkillChange TriggerSkillWindow
            else
                Noop
        _ ->
            Noop

init : Model
init =
    { myself = defaultMe
    , bullet = []
    , bulletViewbox = []
    , map = mapInit
    , rooms = roomInit
    , viewbox = mapToViewBox defaultMe mapInit
    , size = (0, 0)
    , state = Others
    , currentDialogues = [{sentenceInit | text = "hello", side = Left}, {sentenceInit | text = "bad", side = Right}, {sentenceInit | text = "badddddd", side = Left}, {sentenceInit | text = "good", side = Right}]
    , explosion = []
    , explosionViewbox = []
    }


