const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("locale.h");
});

const CString = [:0]u8;

const MAX_READ_BYTES = 1 << 20;

const NcursesError = error{ SetUpError, RefreshFailure };

pub fn main() !void {
    try setup_ncurses();
    defer teardown_ncurses();

    const text = try read_input(std.heap.c_allocator);
    defer std.heap.c_allocator.free(text);

    //     std.debug.print("Text Message is: {s}", .{text});

    _ = c.addstr((text[0 .. text.len - 1 :0]).ptr);
    _ = c.refresh();

    std.time.sleep(1_500_000_000);
    //     std.debug.print("Text len = {d}", .{text.len});
}

fn setup_ncurses() NcursesError!void {
    const x: c_int = c.LC_ALL;
    const y = "";

    const ret_code = c.setlocale(x, y);
    if (ret_code == null) {
        //         std.debug.print("Unable to set locale\n", .{});
        return NcursesError.SetUpError;
    }

    _ = c.initscr();

    if (c.refresh() != 0) {
        //         std.debug.print("Failure refreshing screen\n", .{});
        return NcursesError.RefreshFailure;
    }
}

fn teardown_ncurses() void {
    const errcode = c.endwin();
    switch (errcode) {
        0 => return,
        else => std.debug.print("An Error occured when tearing down Ncurses, error code {d}", .{errcode}),
    }
}

/// Read the Input, returning the contents of the file.
fn read_input(allocator: std.mem.Allocator) ![]u8 {
    const file = std.io.getStdIn();
    var array_list = std.ArrayList(u8).init(allocator);
    defer array_list.deinit();

    try file.reader().readAllArrayList(&array_list, MAX_READ_BYTES);
    // Go to add a NULL byte to the slice so we can send it to NCurses
    try array_list.append(0x0);
    //     std.debug.print("Length of array_list: {?}", .{array_list});

    return try array_list.toOwnedSlice();
}
