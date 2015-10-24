module dice;

import parser;
import std.algorithm;
import std.random;

auto diceParser(R)(ref R src) {
    return choice!(
            sequence!(number!R, character!('d', R), number!R, eos!R, R),
            sequence!(number!R, character!('d', R), eos!R, R),
            sequence!(character!('d', R), number!R, eos!R, R),
            R)(src);
}

unittest {
    import std.typecons;

    auto s = "2d6";
    auto r = diceParser(s);
    assert(r[0]);
    assert(r[2] == 0);
    assert(r[1][0] == tuple(2, 'd', 6, NoValue));

    s = "2d";
    r = diceParser(s);
    assert(r[0]);
    assert(r[2] == 1);
    assert(r[1][1] == tuple(2, 'd', NoValue));

    s = "d12";
    r = diceParser(s);
    assert(r[0]);
    assert(r[2] == 2);
    assert(r[1][2] == tuple('d', 12, NoValue));
}

uint dice(uint eyes) in {
    assert(eyes > 0);
} body {
    return uniform!"[]"(1, eyes);
}

struct DiceResult {
    uint sum;
    alias sum this;
    uint[] results;
}

auto dice(uint num, uint eyes) {
    auto results = new uint[num];

    foreach (ref r; results) {
        r = dice(eyes);
    }

    return DiceResult(results.sum(), results);
}

auto dice(R)(R src) {
    auto r = diceParser(src);

    if (!r[0]) {
        import std.exception;
        throw new Exception("Parse error: ", src);
    }

    switch (r[2]) {
        case 0:
            return dice(r[1][0][0], r[1][0][2]);
        case 1:
            return dice(r[1][1][0], 6);
        case 2:
            return dice(1, r[1][2][1]);
        default:
            assert(0);
    }
}

unittest {
    foreach (n; 0 .. 1000) {
        auto r = dice("2d6");
        assert(r.sum >= 2);
        assert(r.sum <= 12);
        assert(r.results.length == 2);
        foreach (v; r.results) {
            assert(v >= 1);
            assert(v <= 6);
        }
    }

    auto r = dice("2d");
    assert(r.results.length == 2);

    r = dice("d12");
    assert(r.results.length == 1);
}
