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
    effects: Effect,

    pub fn init(start: usize) StyledStr {
        return StyledStr{ .start = start, .end = start, .fg = null, .bg = null, .effects = Effect{} };
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
    DEFAULT,
    BLACK,
    RED,
    GREEN,
    YELLOW,
    BLUE,
    MAGENTA,
    CYAN,
    WHITE,
};

const Effect = packed struct(u16) {
    BOLD: bool = false,
    UNDERLINE: bool = false,
    REVERSE: bool = false,
    DIM: bool = false,
    BLINK: bool = false,
    PROTECT: bool = false,
    INVIS: bool = false,
    ITALIC: bool = false,
    _padding: u8 = 0,
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
                            str.effects = Effect{};
                            str.fg = .DEFAULT;
                            str.bg = .DEFAULT;
                        }
                        while (i < state.num_params) : (i += 1) {
                            handle_sgr_parameter(state.params[i], &str);
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
fn handle_sgr_parameter(param: u32, str: *StyledStr) void {
    switch (param) {
        0 => {
            str.effects = Effect{};
        },
        1 => {
            str.effects.BOLD = true;
        },
        2 => {
            str.effects.DIM = true;
        },
        3 => {
            str.effects.ITALIC = true;
        },
        4 => {
            str.effects.UNDERLINE = true;
        },
        5, 6 => {
            str.effects.BLINK = true;
        },
        7 => {
            str.effects.REVERSE = true;
        },
        8 => {
            str.effects.PROTECT = true;
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
            str.fg = .BLACK;
        },
        31 => {
            str.fg = .RED;
        },
        32 => {
            str.fg = .GREEN;
        },
        33 => {
            str.fg = .YELLOW;
        },
        34 => {
            str.fg = .BLUE;
        },
        35 => {
            str.fg = .MAGENTA;
        },
        36 => {
            str.fg = .CYAN;
        },
        37 => {
            str.fg = .WHITE;
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
