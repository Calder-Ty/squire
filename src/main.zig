const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("locale.h");
});

const text = "Bi Cuimhneach";

pub fn main() void {
    const x: c_int = c.LC_ALL;
    const y = "";

    _ = c.setlocale(x, y);

    //     initscr
    _ = c.initscr();
    _ = c.refresh();
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        _ = c.addch(text[i]);
    }
    _ = c.refresh();
    std.time.sleep(1_000_000_000);
    const errcode = c.endwin();
    switch (errcode) {
        0 => return,
        else => std.debug.print("An Error occured, error code {d}", .{errcode}),
    }
}
