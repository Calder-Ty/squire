//! Callback for processing ansi escape sequences and stylings
const std = @import("std");
const vt = @import("./vtparse.zig");
const c = @cImport({
    @cInclude("ncurses.h");
});

/// A String With ansi styling information Attatched
const StyledStr = struct {
    start: usize,
    end: usize,
    fg: ?Color,
    bg: ?Color,
    effects: u8,

    pub fn init(start: usize) StyledStr {
        return StyledStr{ .start = start, .end = start, .fg = null, .bg = null, .effects = 0 };
    }

    pub fn add_effect(self: *StyledStr, effect: Effect) void {
        self.effects |= effect;
    }

    pub fn copy(orig: StyledStr) StyledStr {
        return StyledStr{
            .start = orig.start,
            .end = orig.end,
            .fg = orig.fg,
            .bg = orig.bg,
            .effects = orig.effects,
        };
    }
};

const Color = enum {
    BLACK,
    RED,
    GREEN,
    YELLOW,
    BLUE,
    MAGENTA,
    CYAN,
    WHITE,
};

const Effect = enum(u8) {
    BOLD = 1 << 1,
    UNDERLINE = 1 << 2,
    REVERSE = 1 << 3,
    DIM = 1 << 4,
    BLINK = 1 << 5,
    PROTECT = 1 << 6,
    INVIS = 1 << 7,
    ITALIC = 1 << 8,
};

pub const StyledStream = struct {
    text_data: std.ArrayList(StyledStr),

    pub fn init(allocator: std.mem.Allocator) StyledStream {
        var text_data = std.ArrayList(StyledStr).init(allocator);
        return StyledStream{ .text_data = text_data };
    }

    pub fn deinit(self: StyledStream) void {
        self.text_data.deinit();
    }

    pub fn handle_event(self: *StyledStream, state: *const vt.ParserData, to_action: vt.Action, char: u8) void {
        var str: StyledStr = self.text_data.getLastOrNull() orelse StyledStr.init(state.index);
        switch (to_action) {
            vt.Action.PRINT => {
                // Printing means we want to advance the printed string to include the next character
                str.end = state.index;
            },
            vt.Action.CSI_DISPATCH => {
                switch (char) {
                    // Color the console
                    'm' => {
                        var i: u8 = 0;
                        if (state.num_params == 0) {
                            // Reset the color state
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

    //     fn init(text: std.ArrayList(u8), allocator: std.mem.Allocator)
};

/// Process ansi styled text and send to stdscr
fn handle_sgr_parameter(param: u32) void {
    switch (param) {
        0 => {
            _ = c.attr_set(c.A_NORMAL, 0, null);
        },
        1 => {
            _ = c.attr_on(c.A_BOLD, null);
        },
        2 => {
            _ = c.attr_on(c.A_DIM, null);
        },
        3 => {
            _ = c.attr_on(c.A_ITALIC, null);
        },
        4 => {
            _ = c.attr_on(c.A_UNDERLINE, null);
        },
        5, 6 => {
            _ = c.attr_on(c.A_BLINK, null);
        },
        7 => {
            _ = c.attr_on(c.A_REVERSE, null);
        },
        8 => {
            _ = c.attr_on(c.A_PROTECT, null);
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
            _ = c.color_set(c.COLOR_BLACK, null);
        },
        31 => {
            _ = c.color_set(c.COLOR_RED, null);
        },
        32 => {
            _ = c.color_set(c.COLOR_GREEN, null);
        },
        33 => {
            _ = c.color_set(c.COLOR_YELLOW, null);
        },
        34 => {
            _ = c.color_set(c.COLOR_BLUE, null);
        },
        35 => {
            _ = c.color_set(c.COLOR_MAGENTA, null);
        },
        36 => {
            _ = c.color_set(c.COLOR_CYAN, null);
        },
        37 => {
            _ = c.color_set(c.COLOR_WHITE, null);
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
