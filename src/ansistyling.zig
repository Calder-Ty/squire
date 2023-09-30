//! Callback for processing ansi escape sequences and stylings
const std = @import("std");
const vt = @import("./vtparse.zig");
const c = @cImport({
    @cInclude("ncurses.h");
});

/// Process ansi styled text and send to stdscr
pub fn handle_parse_events(state: *const vt.ParserData, to_action: vt.Action, char: u8) void {
    switch (to_action) {
        vt.Action.PRINT => {
            _ = c.addch(char);
        },
        vt.Action.CSI_DISPATCH => {
            std.debug.print("CSI_DISPATCH: state {}", .{state});
            switch (char) {
                // Color the console
                'm' => {
                    var i: u8 = 0;
                    if (state.num_params == 0) {
                        // Reset the color state
                        std.debug.print("Resetting state", .{});
                        _ = c.attr_set(c.A_NORMAL, 0, null);
                    }
                    while (i < state.num_params) : (i += 1) {
                        handle_sgr_parameter(state.params[i]);
                    }
                },
                else => {},
            }
        },
        else => {
            switch (char) {
                // HACK: This should be done via the proper action, but for now, we are just inspecting
                // the characters and then printing them
                '\n', '\t' => _ = c.addch(char),
                else => {},
            }
        },
    }
}

fn handle_sgr_parameter(param: u32) void {
    switch (param) {
        0 => {
            _ = c.attr_set(c.A_NORMAL, 0, null);
        },
        1 => {
            _ = c.attr_set(c.A_BOLD, 0, null);
        },
        2 => {
            _ = c.attr_set(c.A_DIM, 0, null);
        },
        3 => {
            _ = c.attr_set(c.A_ITALIC, 0, null);
        },
        4 => {
            _ = c.attr_set(c.A_UNDERLINE, 0, null);
        },
        5, 6 => {
            _ = c.attr_set(c.A_BLINK, 0, null);
        },
        7 => {
            _ = c.attr_set(c.A_REVERSE, 0, null);
        },
        8 => {
            _ = c.attr_set(c.A_PROTECT, 0, null);
        },
        9 => {
            // Not Supported by ncurses
        },
        10 => {
            // Not Supported by Me
        },
        11...19 => {
            // Again not supported by Me
        },
        20 => {
            // Again not supported by Me
        },
        //         21 => {},
        //         22 => {},
        //         23 => {},
        //         24 => {},
        //         25 => {},
        //         26 => {},
        //         27 => {},
        //         28 => {},
        //         29 => {},
        30 => {
            _ = c.attr_set(0, c.COLOR_BLACK, null);
        },
        31 => {
            _ = c.attr_set(0, c.COLOR_RED, null);
        },
        32 => {
            _ = c.attr_set(0, c.COLOR_GREEN, null);
        },
        33 => {
            _ = c.attr_set(0, c.COLOR_YELLOW, null);
        },
        34 => {
            _ = c.attr_set(0, c.COLOR_BLUE, null);
        },
        35 => {
            _ = c.attr_set(0, c.COLOR_MAGENTA, null);
        },
        36 => {
            _ = c.attr_set(0, c.COLOR_CYAN, null);
        },
        37 => {
            _ = c.attr_set(0, c.COLOR_WHITE, null);
        },
        //         38 => {},
        //         39 => {},
        //         40 => {},
        //         41 => {},
        //         42 => {},
        //         43 => {},
        //         44 => {},
        //         45 => {},
        //         46 => {},
        //         47 => {},
        //         48 => {},
        //         49 => {},
        //         50 => {},
        //         51 => {},
        //         52 => {},
        //         53 => {},
        //         54 => {},
        //         55 => {},
        //         56 => {},
        //         57 => {},
        //         58 => {},
        //         59 => {},
        //         60 => {},
        //         61 => {},
        //         62 => {},
        //         63 => {},
        //         64 => {},
        //         65 => {},
        //         66 => {},
        //         67 => {},
        //         68 => {},
        //         69 => {},
        //         70 => {},
        //         71 => {},
        //         72 => {},
        //         73 => {},
        //         74 => {},
        //         75 => {},
        //         76 => {},
        //         77 => {},
        //         78 => {},
        //         79 => {},
        //         80 => {},
        //         81 => {},
        //         82 => {},
        //         83 => {},
        //         84 => {},
        //         85 => {},
        //         86 => {},
        //         87 => {},
        //         88 => {},
        //         89 => {},
        //         90 => {},
        //         91 => {},
        //         92 => {},
        //         93 => {},
        //         94 => {},
        //         95 => {},
        //         96 => {},
        //         97 => {},
        //         98 => {},
        //         99 => {},
        //         100 => {},
        //         101 => {},
        //         102 => {},
        //         103 => {},
        //         104 => {},
        //         105 => {},
        //         106 => {},
        //         107 => {},
        else => {},
    }
}
