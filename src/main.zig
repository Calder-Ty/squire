const std = @import("std");

const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("locale.h");
});

const argparse = @import("./argparse.zig");

const MAX_READ_BYTES = 1 << 20;
const ESC: u8 = 27;

const NcursesError = error{ SetUpError, RefreshFailure };

pub fn main() !void {

    // Parse the Arguments
    const args = try std.process.argsAlloc(std.heap.c_allocator);
    defer std.process.argsFree(std.heap.c_allocator, args);
    //     std.debug.print("{s}\n", .{args});
    const parsed_args = try argparse.parse_args(args);

    try setup_ncurses();
    defer teardown_ncurses();

    const text = try read_input(std.heap.c_allocator, file_path_from_args(parsed_args.args));
    defer std.heap.c_allocator.free(text);

    //     std.debug.print("Number of Colors possible: {d}", .{c.COLORS});
    //     std.debug.print("Text Message is: {s}", .{text});

    send_input_to_screen(text);
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
    _ = c.start_color();

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
fn read_input(allocator: std.mem.Allocator, file_path: ?[]u8) ![]u8 {
    var file: std.fs.File = undefined;
    if (file_path) |path| {
        file = try std.fs.cwd().openFile(path, .{});
    } else {
        file = std.io.getStdIn();
    }
    defer file.close();

    var array_list = std.ArrayList(u8).init(allocator);
    defer array_list.deinit();

    try file.reader().readAllArrayList(&array_list, MAX_READ_BYTES);
    // Go to add a NULL byte to the slice so we can send it to NCurses
    try array_list.append(0x0);
    //     std.debug.print("Length of array_list: {?}", .{array_list});

    return try array_list.toOwnedSlice();
}

/// This is Squire Specific argument parsing
fn file_path_from_args(args: [][:0]u8) ?[:0]u8 {
    if (args.len == 0 or std.mem.eql(u8, args[0], "-")) {
        return null;
    }
    return args[0];
}

fn send_input_to_screen(content: []u8) void {
    for (content) |char| {
        // Allegedly ncurses handles multibyte characters ok
        // We just need to handle the attributes
        if (char == ESC) {
            continue;
        }
        _ = c.addch(char);
    }
}
