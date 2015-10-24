import dice;
import std.stdio;
import std.string;

void run(string s) {
    auto r = dice.dice(s);

    write(s, '=');
    writef("[%(%s,%)]=", r.results);
    writeln(r.sum);
}

void main(string[] args) {
    if (args.length == 2) {
        run(args[1]);
    } else {
        while (1) {
            write("> ");
            run(readln().chomp());
        }
    }
}
