module parser;

import std.algorithm;
import std.range;
import std.typecons;
import std.traits;
import std.uni;
import std.typetuple;

enum NoValue = 0;

//version = ParserLog;

version (ParserLog) {
    void log(T...)(T args) {//, string file = __FILE__, uint line = __LINE__) {
        import std.stdio;
        import std.datetime;
        writeln('[', Clock.currTime, "] ", /*file, '@', line, ": ",*/ args);
    }
} else {
    void log(T...)(lazy T args) {
    }
}

template ValueTypeTuple(T...) {
    private template SelectType(size_t index) {
        template SelectType(alias T) if (T.Types.length > index) {
            alias SelectType = T.Types[index];
        }
    }

    alias ValueTypeTuple = Tuple!(staticMap!(SelectType!(1), staticMap!(ReturnType, T)));
}

enum isParser(alias T) = isInputRange!(ParameterTypeTuple!T[0])
    && isTuple!(ReturnType!T)
    && ReturnType!T.length >= 2
    && is(typeof(ReturnType!T[0]) == bool)
    ;


auto character(alias C, R)(ref R src) if (isInputRange!R) {
    log("Character ", C, ' ', src);
    if (!src.empty && src.front == C) {
        log("Character OK");
        src.popFront();
        return tuple(true, C);
    } else {
        log("Character Fail");
        return tuple(false, C);
    }
}

unittest {
    string s;
    Tuple!(bool, char) r;

    static assert(isParser!(character!('a', char[])));

    s = "abc";
    r = s.character!'a'();
    assert(r[0]);
    assert(r[1] == 'a');
    assert(s == "bc");

    r = s.character!'a'();
    assert(!r[0]);
    assert(s == "bc");

    r = s.character!'b'();
    assert(r[0]);
    assert(r[1] == 'b');
    assert(s == "c");
}

auto number(R, T = int)(ref R src) if (isInputRange!R) {
    log("Number ", src);
    if (!src.empty && src.front.isNumber()) {
        T n = 0;

        do {
            n *= 10;
            n += cast(T)(src.front - '0');
            src.popFront();
        } while (!src.empty && src.front.isNumber);

        log("Number OK");
        return tuple(true, n);
    } else {
        log("Number Fail");
        return tuple(false, cast(T)0);
    }
}

unittest {
    string s;
    Tuple!(bool, int) r;

    static assert(isParser!(number!(char[])));

    s = "123";
    r = s.number();
    assert(r[0]);
    assert(r[1] == 123);
    assert(s == "");

    s = "56a34";
    r = s.number();
    assert(r[0]);
    assert(r[1] == 56);
    assert(s == "a34");

    r = s.number();
    assert(!r[0]);
    assert(s == "a34");
}

auto eos(R)(ref R src) {
    log("EOS ", src);
    return tuple(src.empty, NoValue);
}

auto choice(T...)(ref T[T.length-1] src) if (isForwardRange!(T[T.length-1])) {
    alias R = ValueTypeTuple!(T[0 .. $-1]);

    log("Choice ", T[0 .. $-1].stringof, ' ', src);

    foreach (i, p; T[0 .. $-1]) {
        auto s = src.save;
        auto r = p(s);

        if (r[0]) {
            log("Choice OK ", typeof(p).stringof);
            R _r;
            _r[i] = r[1];
            src = s;
            return tuple(true, _r, i);
        }
    }

    log("Choice Fail");
    return tuple(false, R(), cast(uint)-1);
}

unittest {
    alias parser = choice!(character!('a', string), number!(string), string);
    static assert(isParser!parser);

    auto s = "123ab8a9";
    auto r = parser(s);
    assert(r[0]);
    assert(r[2] == 1);
    assert(r[1][1] == 123);
    assert(s == "ab8a9");

    r = parser(s);
    assert(r[0]);
    assert(r[2] == 0);
    assert(r[1][0] == 'a');
    assert(s == "b8a9");

    r = parser(s);
    assert(!r[0]);
    assert(s == "b8a9");
}

auto sequence(T...)(ref T[$-1] src) if (isInputRange!(T[$-1])) {
    alias R = ValueTypeTuple!(T[0 .. $-1]);
    R results;

    log("Sequence ", T[$ - 1].stringof, ' ', src);

    uint j;
    foreach (i, p; T[0 .. $-1]) {
        auto r = p(src);

        results[i] = r[1];

        if (!r[0]) {
            log("Sequence Fail", typeof(p).stringof);
            return tuple(false, results);
        }
    }

    log("Sequence OK");
    return tuple(true, results);
}

unittest {
    alias parser = sequence!(character!('a', string), character!('b', string), string);
    static assert(isParser!parser);

    auto s = "abcdef";
    auto r = parser(s);
    assert(r[0]);
    assert(r[1] == tuple('a', 'b'));
    assert(s == "cdef");

    r = parser(s);
    assert(!r[0]);
}
