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

    const text = try read_input(std.heap.c_allocator);
    defer std.heap.c_allocator.free(text);

    _ = c.addstr(text.*);
    _ = c.refresh();

    std.time.sleep(1_500_000_000);
    const errcode = c.endwin();
    switch (errcode) {
        0 => return,
        else => std.debug.print("An Error occured, error code {d}", .{errcode}),
    }
}

fn setup_ncurses() NcursesError!void {
    const x: c_int = c.LC_ALL;
    const y = "";

    const ret_code = c.setlocale(x, y);
    if (ret_code == null) {
        std.debug.print("Unable to set locale\n", .{});
        return NcursesError.SetUpError;
    }

    _ = c.initscr();

    if (c.refresh() != 0) {
        std.debug.print("Failure refreshing screen\n", .{});
        return NcursesError.RefreshFailure;
    }
}

/// Read the Input, returning the contents of the file.
/// Allocated
fn read_input(allocator: std.mem.Allocator) ![]u8 {
    const file = std.io.getStdIn();
    const content = try file.reader().readAllAlloc(allocator, MAX_READ_BYTES);
    return content;
}
