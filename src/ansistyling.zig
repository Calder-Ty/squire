//! Callback for processing ansi escape sequences and stylings

const vt = @import("./vtparse.zig");
const c = @cImport({
    @cInclude("ncurses.h");
});

/// Process ansi styled text and send to stdscr
pub fn handle_parse_events(state: *const vt.ParserData, to_action: vt.Action, char: u8) void {
    _ = state;
    // FIXME: THIS IS OLD, lets use the new version
    _ = c.attrset(c.A_BOLD);
    switch (to_action) {
        vt.Action.PRINT => {
            _ = c.addch(char);
        },
        //         vt.Actton.CSI_DISPATCH => {
        //             switch (char) {
        //                 Color the console
        //                 'm' => {
        //                     var i = 0
        //                     while (i < state.num_params) : (i += 1) {
        //                     }
        //                 }
        //             }
        //         }
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
