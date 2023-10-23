const std = @import("std");
const pt = @import("./vtparse_table.zig");

const trait = std.meta.trait;

pub const Action = pt.Action;
pub const ParserState = pt.ParserState;

const MAX_INTERMEDIATE_CHARS = 2;

fn action(table_entry: u8) ?pt.Action {
    const val = table_entry & 0x0F;
    if (val == 0) {
        return null;
    }
    return @enumFromInt(val);
}

fn state(table_entry: u8) ?pt.ParserState {
    const val = table_entry >> 4;
    if (val == 0) {
        return null;
    }
    return @enumFromInt(val);
}

pub const ParserData = struct {
    index: usize = 0,
    state: pt.ParserState,
    intermediate_chars: [MAX_INTERMEDIATE_CHARS + 1]u8,
    num_intermediate_chars: u8,
    ignore_flagged: u8,
    params: [16]u32,
    num_params: u32,

    fn init() ParserData {
        return ParserData{
            .state = pt.ParserState.GROUND,
            .num_intermediate_chars = 0,
            .ignore_flagged = 0,
            .num_params = 0,
            .intermediate_chars = undefined,
            .params = undefined,
        };
    }
};

/// Set of actions returned by next
pub fn VTParser(comptime HandlerType: type) type {
    // Do Type Checking
    if (!trait.hasFn("handle_event")(HandlerType)) {
        @compileError("HandlerType must have handle_event function");
    }

    return struct {
        const Self = @This();
        data: ParserData,
        handler: *HandlerType,
        // The current index of the parser into the input text
        // Oh look a void pointer, I guess i forgot about that
        //     void*              user_data;

        pub fn init(stream_handler: *HandlerType) Self {
            return Self{
                .data = ParserData.init(),
                .handler = stream_handler,
            };
        }

        /// This will parse a whole system in a stream,
        /// calling a callback to process data
        pub fn parse(self: *Self, data: []const u8) void {
            self.data.index = 0;
            while (self.data.index < data.len) : (self.data.index += 1) {
                const ch = data[self.data.index];
                const state_change = pt.parse_table[@intFromEnum(self.data.state) - 1][ch];
                self.doStateChange(state_change, ch);
            }
        }

        fn doAction(self: *Self, in_action: pt.Action, ch: u8) void {

            // Some actions we handle internally (like parsing parameters), others
            // we hand to our client for processing

            switch (in_action) {
                pt.Action.PRINT, pt.Action.EXECUTE, pt.Action.HOOK, pt.Action.PUT, pt.Action.OSC_START, pt.Action.OSC_PUT, pt.Action.OSC_END, pt.Action.UNHOOK, pt.Action.CSI_DISPATCH, pt.Action.ESC_DISPATCH => self.handler.handle_event(&self.data, in_action, ch) catch {},
                // FIXME: ^^ I don't like just throwing this error away

                pt.Action.IGNORE => {},

                pt.Action.COLLECT => {
                    // Append the character to the intermediate params
                    if (self.data.num_intermediate_chars + 1 > MAX_INTERMEDIATE_CHARS) {
                        // Is this a bool?
                        self.data.ignore_flagged = 1;
                    } else {
                        self.data.intermediate_chars[self.data.num_intermediate_chars] = ch;
                        self.data.num_intermediate_chars += 1;
                    }
                },

                pt.Action.PARAM => {
                    // process the param character
                    if (ch == ';') {
                        self.data.num_params += 1;
                        self.data.params[self.data.num_params - 1] = 0;
                    } else {
                        // the character is a digit
                        var current_param: usize = undefined;

                        if (self.data.num_params == 0) {
                            self.data.num_params = 1;
                            self.data.params[0] = 0;
                        }

                        current_param = self.data.num_params - 1;
                        self.data.params[current_param] *= 10;
                        self.data.params[current_param] += (ch - '0');
                    }
                },

                pt.Action.CLEAR => {
                    self.data.num_intermediate_chars = 0;
                    self.data.num_params = 0;
                    self.data.ignore_flagged = 0;
                },
            }
        }

        fn doStateChange(self: *Self, change: u8, ch: u8) void {
            // A state change is an action and/or a new state to transition to

            const new_state = state(change);
            const in_action = action(change);

            if (new_state) |ns| {
                // Perform up to three actions:
                //   1. the exit action of the old state
                //   2. the action associated with the transition
                //   3. the entry action of the new state

                // I Don't like having to do minus - 1 here, but is necessary because
                // the Actions and states Enums start at 1 not 0. This is so that a
                // value of 0 in the table can represent no action or no state.
                // I did have those states explicity represented before, but
                // The problem is that they are not real states. They represent the
                // lack, or optionalness of them. That is why I decided to use optional
                // values instead.
                //
                // But because the table needs to be represented in simple bytes, the Null
                // byte was picked to represent that.
                const exit_action = pt.exit_actions[@intFromEnum(self.data.state) - 1];
                const entry_action = pt.entry_actions[@intFromEnum(ns) - 1];

                if (exit_action) |act| {
                    self.doAction(act, 0);
                }
                if (in_action) |act| {
                    self.doAction(act, ch);
                }
                if (entry_action) |act| {
                    self.doAction(act, 0);
                }
                self.data.state = ns;
            } else {
                if (in_action) |act| {
                    self.doAction(act, ch);
                }
            }
        }
    };
}

// fn testCallback(parser_state: *const ParserData, to_action: pt.Action, ch: u8) void {
//     std.debug.print("Recieved action: {?}, State: {?} parser, char: {?}\n", .{ to_action, parser_state, ch });
// }

// test "VTParser" {
//     const input = [_]u8{ 27, '[', '2', '2', 'm', 'a', 'b', 'c', 'd' };

//     var parser = VTParser.init(testCallback);
//     parser.parse(&input);
// }
