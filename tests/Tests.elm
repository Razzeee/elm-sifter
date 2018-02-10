module Tests exposing (..)

import Test exposing (..)
import Expect
import Sifter exposing (..)


type alias Element =
    { firstName : String
    , lastName : String
    , address : String
    }


elem1 : Element
elem1 =
    { firstName = "Joe", lastName = "Johnson", address = "123 Hill Road" }


elem2 : Element
elem2 =
    { firstName = "Jane", lastName = "Bachman", address = "47 Blueberry Court" }


elem3 : Element
elem3 =
    { firstName = "Nancy", lastName = "Filmann", address = "1 Heartland Drive" }


data : List Element
data =
    [ elem1
    , elem2
    , elem3
    ]


config : Config Element
config =
    { extractors =
        [ .firstName
        , .lastName
        , .address
        ]
    , limit = 3
    , sort = Nothing
    , filter = False
    , conjunction = Or
    , respectWordBoundaries = False
    }


extractor : Element -> String
extractor =
    .firstName


all : Test
all =
    describe "A Test Suite"
        [ test "Returns an empty list with no search string" <|
            \() ->
                Expect.equal (sifter config "" data) []
        , test "Can perform a simple match in first field" <|
            \() ->
                Expect.equal (sifter config "Joe" data) [ elem1 ]
        , test "Can perform a case insensitive match" <|
            \() ->
                Expect.equal (sifter config "joe" data) [ elem1 ]
        , test "Can match address field" <|
            \() ->
                Expect.equal (sifter config "blue" data) [ elem2 ]
        , test "Can return more than one match" <|
            \() ->
                Expect.equal (sifter config "man" data) [ elem3, elem2 ]
        , test "Properly limits results" <|
            \() ->
                let
                    newConfig =
                        { config | limit = 1 }
                in
                    Expect.equal (sifter newConfig "man" data) [ elem3 ]
        , test "Properly handles multiple tokens in seatrch string" <|
            \() ->
                Expect.equal (sifter config "court blueberry" data) [ elem2 ]
        , test "Score 1" <|
            \() ->
                let
                    matchResult =
                        [ { match = "abc"
                          , submatches = []
                          , index = 0
                          , number = 1
                          }
                        ]
                in
                    Expect.equal (computeScore "abc" matchResult) 1.5
        , test "Score 2" <|
            \() ->
                let
                    matchResult =
                        [ { match = "ab"
                          , submatches = []
                          , index = 0
                          , number = 1
                          }
                        ]
                in
                    Expect.equal (computeScore "abcd" matchResult) 1.0
        ]
