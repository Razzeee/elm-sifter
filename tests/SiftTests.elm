module SiftTests exposing (..)

import Test exposing (..)
import Expect
import Sifter exposing (..)


type alias NameElement =
    { name : String
    }


nameConfig : Config NameElement
nameConfig =
    { extractors = [ .name ]
    , limit = 10
    , sort = Nothing
    , filter = True
    , conjunction = Or
    , respectWordBoundaries = False
    }


type alias MultiElement =
    { name : String
    , address : String
    }


multiConfig : Config MultiElement
multiConfig =
    { extractors = []
    , limit = 10
    , sort = Nothing
    , filter = True
    , conjunction = Or
    , respectWordBoundaries = False
    }


all : Test
all =
    describe "A Test Suite"
        [ test "Returns an empty list with no search string" <|
            \() ->
                let
                    result =
                        sifter nameConfig "" [ { name = "Joe" } ]
                in
                    Expect.equal result []
        , test "Can process a simple match" <|
            \() ->
                let
                    result =
                        sifter nameConfig "Joe" [ { name = "Joe" } ]
                in
                    Expect.equal result [ { name = "Joe" } ]
        , test "Search is case insensitive" <|
            \() ->
                let
                    result =
                        sifter nameConfig "joe" [ { name = "Joe" } ]
                in
                    Expect.equal result [ { name = "Joe" } ]
        , test "Returns empty list if no match" <|
            \() ->
                let
                    result =
                        sifter nameConfig "mary" [ { name = "Joe" } ]
                in
                    Expect.equal result []
        , test "Can return more than one match" <|
            \() ->
                let
                    data =
                        [ { name = "Joe Johnson" }
                        , { name = "Joe Smith" }
                        , { name = "Jane Doe" }
                        ]

                    result =
                        sifter nameConfig "joe" data
                in
                    Expect.equal result
                        [ { name = "Joe Smith" }
                        , { name = "Joe Johnson" }
                        ]
        , test "Setting filter to false returns all results" <|
            \() ->
                let
                    config =
                        { nameConfig | filter = False }

                    data =
                        [ { name = "Joe Johnson" }
                        , { name = "Joe Smith" }
                        , { name = "Jane Doe" }
                        ]

                    result =
                        sifter config "joe" data
                in
                    Expect.equal result
                        [ { name = "Joe Smith" }
                        , { name = "Joe Johnson" }
                        , { name = "Jane Doe" }
                        ]
        , test "Can limit results" <|
            \() ->
                let
                    config =
                        { nameConfig | limit = 1 }

                    data =
                        [ { name = "Joe Johnson" }
                        , { name = "Joe Smith" }
                        , { name = "Jane Doe" }
                        ]

                    result =
                        sifter config "joe" data
                in
                    Expect.equal result [ { name = "Joe Smith" } ]
        , test "Can handle multiple tokens in a search string with Or conjunction" <|
            \() ->
                let
                    data =
                        [ { name = "Joe Johnson" }
                        , { name = "Joe Smith" }
                        , { name = "Jane Doe" }
                        ]

                    result =
                        sifter nameConfig "smith joe" data
                in
                    Expect.equal result [ { name = "Joe Smith" }, { name = "Joe Johnson" } ]
        , test "Can handle multiple tokens in a search string with And conjunction" <|
            \() ->
                let
                    config =
                        { nameConfig | conjunction = And }

                    data =
                        [ { name = "Joe Johnson" }
                        , { name = "Joe Smith" }
                        , { name = "Jane Doe" }
                        ]

                    result =
                        sifter config "smith joe" data
                in
                    Expect.equal result [ { name = "Joe Smith" } ]
        , test "Can handle diacritics" <|
            \() ->
                let
                    data =
                        [ { name = "Hüsker" } ]

                    result =
                        sifter nameConfig "husker" data
                in
                    Expect.equal result [ { name = "Hüsker" } ]
        , test "Can handle diacritics matching multiples" <|
            \() ->
                let
                    data =
                        [ { name = "Husker" }, { name = "Hüsker" } ]

                    result =
                        sifter nameConfig "husker" data
                in
                    Expect.equal result [ { name = "Hüsker" }, { name = "Husker" } ]
        , test "Can search on multiple fields" <|
            \() ->
                let
                    config =
                        { multiConfig | extractors = [ .name, .address ] }

                    data =
                        [ { name = "Joe Johnson", address = "Hill St" }
                        , { name = "Jane Doe", address = "Johnson St" }
                        ]

                    result =
                        sifter config "johnson" data
                in
                    Expect.equal result
                        [ { name = "Jane Doe", address = "Johnson St" }
                        , { name = "Joe Johnson", address = "Hill St" }
                        ]
        , test "Only searches with supplied extractors" <|
            \() ->
                let
                    config =
                        { multiConfig | extractors = [ .address ] }

                    data =
                        [ { name = "Joe Johnson", address = "Hill St" }
                        , { name = "Jane Doe", address = "Johnson St" }
                        ]

                    result =
                        sifter config "johnson" data
                in
                    Expect.equal result
                        [ { name = "Jane Doe", address = "Johnson St" } ]
        , test "If no extractors are provided, returns an empty list" <|
            \() ->
                let
                    data =
                        [ { name = "Joe Johnson", address = "Hill St" }
                        , { name = "Jane Doe", address = "Johnson St" }
                        ]

                    result =
                        sifter multiConfig "johnson" data
                in
                    Expect.equal result []
        , test "If respectWordBoundaries is set, it doesn't match in middle of string" <|
            \() ->
                let
                    config =
                        { nameConfig | respectWordBoundaries = True }

                    result =
                        sifter config "os" [ { name = "Jose" } ]
                in
                    Expect.equal result []
        , test "With respectWordBoundaries and conjunction And" <|
            \() ->
                let
                    config =
                        { nameConfig
                            | conjunction = And
                            , respectWordBoundaries = True
                        }

                    result =
                        sifter config "orth andover" [ { name = "North Andover" } ]
                in
                    Expect.equal result []
        ]
