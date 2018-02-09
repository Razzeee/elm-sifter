module Sifter exposing (..)

import Regex


type SortOrder
    = Ascending
    | Descending


type ConjunctionType
    = And
    | Or


type alias ScoredResult a =
    ( Float, a )


type alias SortFields a =
    { fields : List (Extractor a)
    , order : SortOrder
    }


type alias Config a =
    { extractors : List (Extractor a)
    , limit : Int
    , sort : SortFields a
    , filter : Bool
    , conjunction : ConjunctionType
    , respectWordBoundaries : Bool
    }


type alias Extractor a =
    a -> String


reducer : List (ScoredResult a) -> Float
reducer list =
    (List.foldl (\e accum -> accum + Tuple.first (e)) 0.0 list) / (toFloat <| List.length list)


matchAll : String -> a -> List (Extractor a) -> ScoredResult a
matchAll string elem extractors =
    let
        hasMatch =
            List.map (\e -> matchOne e string elem) extractors
                |> reducer
    in
        ( hasMatch, elem )


matchOne : Extractor a -> String -> a -> ScoredResult a
matchOne extractor string elem =
    let
        matcher =
            string
                |> Regex.regex
                |> Regex.caseInsensitive

        matchResult =
            Regex.find (Regex.AtMost 1) matcher (extractor elem)
    in
        ( computeScore string matchResult, elem )


startOfWordScore : Regex.Match -> Float
startOfWordScore matchResult =
    if matchResult.index == 0 then
        0.5
    else
        0.0


baseMatchScore : String -> Regex.Match -> Float
baseMatchScore string matchResult =
    (toFloat <| String.length (matchResult.match))
        / (toFloat <| String.length (string))


computeScore : String -> List Regex.Match -> Float
computeScore string matchResult =
    case matchResult of
        [] ->
            0.0

        elem :: _ ->
            baseMatchScore string elem + startOfWordScore elem


sifter : List a -> Config a -> String -> List a
sifter data config string =
    let
        matcher =
            Regex.regex (string)
    in
        data
            |> List.map (\e -> matchAll string e config.extractors)
            |> List.filter (\e -> Tuple.first e > 0)
            |> List.sortBy Tuple.first
            |> List.map Tuple.second
            |> List.take config.limit
