module Main exposing (..)

import Html exposing (Attribute, Html, br, div, input, program, section, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, int, string, bool, map2, field, oneOf, succeed)

import Msg as Main exposing (..)


-- MAIN
-- https://github.com/elm-lang/elm-platform/blob/master/upgrade-docs/0.18.md


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { name : String
    , videos : List VideoItem
    }


type alias VideoItem =
    { title : String
    , description : String
    , videoId : String
    , selected : Bool
    }

youtubePlaylistId : String
youtubePlaylistId =
    "PLy227h3xpH-FcHw79drVFiVGMRDU8YhLH"

googleApiKey : String
googleApiKey =
    "AIzaSyDkTKtIGxMcyLX2IsfTpCvYr4n7WmMw3Jw"

maxVideoDescriptionLength : Int
maxVideoDescriptionLength =
    50


videoItems : List VideoItem
videoItems =
    [ { title = "Title of video"
      , description = "Description of video"
      , videoId = "#ABC"
      , selected = True
      }
    , { title = "Title of video 2"
      , description = "Description of video 2"
      , videoId = "#DEF"
      , selected = False
      }
    ]


initialModel : Model
initialModel =
    { name = "Codestar VideoPlayer"
    , videos = videoItems
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, getVideos (googleApiKey, youtubePlaylistId) )


-- STYLES
-- TODO: make a stylesheet for this?


videoPlayerStyle : Attribute msg
videoPlayerStyle =
    style
        [ ( "height", "500px" )
        , ( "width", "900px" )
        , ( "fontFamily", "Arial, Helvetica, sans-serif" )
        ]


videoPlayerVideoStyle : Attribute msg
videoPlayerVideoStyle =
    style
        [ ( "backgroundColor", "#000" )
        , ( "height", "100%" )
        , ( "width", "60%" )
        , ( "float", "left" )
        , ( "overflow", "hidden" )
        , ( "color", "#fff" )
        ]


videoPlayerListStyle : Attribute msg
videoPlayerListStyle =
    style
        [ ( "backgroundColor", "#232323" )
        , ( "height", "100%" )
        , ( "width", "40%" )
        , ( "float", "right" )
        , ( "overflow", "hidden" )
        ]


videoPlayerListItemStyle : Attribute msg
videoPlayerListItemStyle =
    style
        [ ( "height", "70px" )
        , ( "width", "100%" )
        , ( "borderBottom", "1px solid #393939" )
        , ( "padding", "15px" )
        , ( "color", "#ddd" )
        , ( "boxSizing", "border-box" )
        , ( "whiteSpace", "nowrap" )
        ]



-- use a function to return a selected style or nothing


videoPlayerListItemSelectedStyle : VideoItem -> Attribute msg
videoPlayerListItemSelectedStyle v =
    if v.selected then
        style
            [ ( "backgroundColor", "rgb(238,129,0)" ) ]
    else
        style []


videoPlayerListItemTitleStyle : Attribute msg
videoPlayerListItemTitleStyle =
    style
        [ ( "color", "#fff" )
        , ( "fontSize", "14px" )
        , ( "overflow", "hidden" )
        , ( "marginBottom", "10px" )
        ]


videoPlayerListItemDescriptionStyle : Attribute msg
videoPlayerListItemDescriptionStyle =
    style
        [ ( "fontSize", "11px" )
        , ( "overflow", "hidden" )
        ]



-- RENDER VIDEOS


toVideoItem : VideoItem -> Html msg
toVideoItem v =
    div [ class "video-list-item", videoPlayerListItemStyle, videoPlayerListItemSelectedStyle v ]
        [ div [ class "video-list-item-title", videoPlayerListItemTitleStyle ]
            [ text v.title
            ]
        , div [ class "video-list-item-description", videoPlayerListItemDescriptionStyle ]
            [ text ( sliceText v.description maxVideoDescriptionLength )
            ]
        ]


renderVideos : List VideoItem -> Html msg
renderVideos video =
    div [] (List.map toVideoItem video)

sliceText : String -> Int -> String
sliceText text limit =
    if String.length text > limit then
        String.slice 0 limit text ++ "..."
    else
        text

-- UPDATE


type Msg
    = NewVideos (Result Http.Error (List VideoItem))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewVideos (Ok videos) ->
            ( { model | videos = videos }, Cmd.none )

        NewVideos (Err _) ->
            ( { model | videos = [] }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "video-player", videoPlayerStyle ]
        [ div [ class "video-container", videoPlayerVideoStyle ] [ text model.name ]
        , div [ class "video-list", videoPlayerListStyle ]
            [ renderVideos model.videos
            ]
        ]



-- HTTP


getVideos : ( String, String ) -> Cmd Msg
getVideos ( apiKey, playlistId ) =
    let
        url =
            "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&key=" ++ apiKey ++ "&playlistId=" ++ playlistId ++ "&maxResults=50"
    in
    Http.send NewVideos (Http.get url videosDecoder)


videosDecoder: Decoder (List VideoItem)
videosDecoder =
  field "items" (Json.Decode.list videoDecoder)

videoDecoder : Decoder VideoItem
videoDecoder =
    Json.Decode.map4 VideoItem
        (field "snippet" (field "title" Json.Decode.string))
        (field "snippet" (field "description" Json.Decode.string))
        (field "contentDetails" (field "videoId" Json.Decode.string))
        (oneOf [ field "selected" bool, succeed False ])
