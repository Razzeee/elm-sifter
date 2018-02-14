module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Places exposing (..)
import Sifter exposing (..)


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = init
        , view = view
        , update = update
        }



-- Model


type alias Place =
    { city : String
    , stateAbbrev : String
    , state : String
    }


type alias Model =
    { limit : String
    , inputText : String
    , places : List Place
    , config : Sifter.Config Place
    }


init : Model
init =
    { limit = "10"
    , inputText = ""
    , places = Places.all
    , config = config
    }



-- Update


type Msg
    = SetInputText String
    | SetLimit String


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetInputText text ->
            { model | inputText = text }

        SetLimit text ->
            let
                limit =
                    text |> String.toInt |> Result.withDefault 0

                old_config =
                    model.config

                config =
                    { old_config | limit = limit }
            in
                { model | limit = text, config = config }



-- View


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ header
        , mainBody model
        ]


header : Html Msg
header =
    div [ class "row" ]
        [ div [ class "col-12" ]
            [ div [ class "jumbotron jumbotron-fluid" ]
                [ div [ class "container" ]
                    [ h1 [ class "text-center" ] [ text "Elm-Sifter Demo Page" ]
                    ]
                ]
            ]
        ]


sideBar : Model -> Html Msg
sideBar model =
    div [ class "col-8" ]
        [ div [ class "form-group" ]
            [ label [ for "limit-input" ] [ text "limit" ]
            , input
                [ id "limit-input"
                , class "form-control"
                , value (toString model.config.limit)
                , onInput SetLimit
                ]
                []
            ]
        , div [ class "form-check" ]
            [ input
                [ id "city-checkbox"
                , class "form-check-input"
                , type_ "checkbox"
                , checked True
                ]
                []
            , label
                [ class "form-check-label"
                , for "city-checkbox"
                ]
                [ text "City" ]
            ]
        , div [ class "form-check" ]
            [ input
                [ id "state-abbrev-checkbox"
                , class "form-check-input"
                , type_ "checkbox"
                , checked True
                ]
                []
            , label
                [ class "form-check-label"
                , for "state-abbrev-checkbox"
                ]
                [ text "State Abbrev" ]
            ]
        , div [ class "form-check" ]
            [ input
                [ id "state-checkbox"
                , class "form-check-input"
                , type_ "checkbox"
                , checked True
                ]
                []
            , label
                [ class "form-check-label"
                , for "state-checkbox"
                ]
                [ text "State" ]
            ]
        , showConfig model.config
        ]


mainContent : Model -> Html Msg
mainContent model =
    let
        places =
            filteredPlaces model.config model.inputText model.places
    in
        div [ class "col-4" ]
            [ div [ class "form-group" ]
                [ label [ for "seartch-input" ] [ text "Search" ]
                , input
                    [ id "search-input"
                    , class "form-control"
                    , onInput SetInputText
                    ]
                    []
                ]
            , ul []
                (List.map
                    (\e -> li [] [ text (e.city ++ ", " ++ e.stateAbbrev) ])
                    places
                )
            ]


mainBody : Model -> Html Msg
mainBody model =
    div [ class "row" ]
        [ sideBar model
        , mainContent model
        ]


extractorsString : Sifter.Config Place -> String
extractorsString config =
    let
        extractorStrings =
            config.extractors
                |> List.map (\x -> getExtractorName x)
                |> String.join (", ")
    in
        "    { extractors = [ " ++ extractorStrings ++ " ]\n"


limitString : Sifter.Config Place -> String
limitString config =
    "    , limit = " ++ toString config.limit ++ "\n"


conjunctionString : Sifter.Config Place -> String
conjunctionString config =
    "    , conjunction = " ++ toString config.conjunction ++ "\n"


respectWordBoundariesString : Sifter.Config Place -> String
respectWordBoundariesString config =
    "    , respectWordBoundaries = " ++ toString config.respectWordBoundaries ++ "\n"


sortString : Sifter.Config Place -> String
sortString config =
    case config.sort of
        Nothing ->
            "    , sort = Nothing\n"

        Just sort ->
            "    , sort = Just { "
                ++ "field = "
                ++ getExtractorName sort.field
                ++ ", order = "
                ++ toString sort.order
                ++ " }\n"


filterString : Sifter.Config Place -> String
filterString config =
    "    , filter = " ++ toString config.filter ++ "\n"


getExtractorName : Extractor Place -> String
getExtractorName extractor =
    let
        place =
            { city = ".city"
            , stateAbbrev = ".stateAbbrev"
            , state = ".state"
            }
    in
        extractor place


showConfig : Sifter.Config Place -> Html Msg
showConfig config =
    pre [ style [ ( "margin-top", "30px" ) ] ]
        [ code []
            [ text
                ("    config =\n"
                    ++ extractorsString config
                    ++ limitString config
                    ++ conjunctionString config
                    ++ respectWordBoundariesString config
                    ++ sortString config
                    ++ filterString config
                    ++ "    }\n"
                )
            ]
        ]


config : Sifter.Config Place
config =
    { extractors = [ .city, .stateAbbrev, .state ]
    , limit = 10
    , sort =
        Just
            { field = .city
            , order = Sifter.Ascending
            }
    , filter = True
    , conjunction = Sifter.And
    , respectWordBoundaries = False
    }


filteredPlaces : Sifter.Config Place -> String -> List Place -> List Place
filteredPlaces config string places =
    Sifter.sifter config string places
