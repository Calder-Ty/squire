//! An implementation of a DEC ansi Parser state machine detailed at
//! https://vt100.net/emu/dec_ansi_parser.
//!
//! For A Reference implementation see https://github.com/haberman/vtparse
//!

// Generate the tables for vtparse
// What we want is a transition table
// of every Byte Value and what it goes to

pub const ParserState = enum(u8) {
    CSI_ENTRY = 1,
    CSI_IGNORE,
    CSI_INTERMEDIATE,
    CSI_PARAM,
    DCS_ENTRY,
    DCS_IGNORE,
    DCS_INTERMEDIATE,
    DCS_PARAM,
    DCS_PASSTHROUGH,
    ESCAPE,
    ESCAPE_INTERMEDIATE,
    GROUND,
    OSC_STRING,
    SOS_PM_APC_STRING,
};

pub const Action = enum(u8) {
    CLEAR = 1,
    COLLECT,
    CSI_DISPATCH,
    ESC_DISPATCH,
    EXECUTE,
    HOOK,
    IGNORE,
    OSC_END,
    OSC_PUT,
    OSC_START,
    PARAM,
    PRINT,
    PUT,
    UNHOOK,
};

const StateTransition = struct { action: ?Action, to_state: ?ParserState };
const TransitionMap = struct { start_val: u8, end_val: ?u8, transition: StateTransition };
const TableFunc = *const fn (char: u8) ?StateTransition;

fn ground_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x20...0x7f => .{ .action = .PRINT, .to_state = null },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn escape_table(char: u8) ?StateTransition {
    return switch (char) {
        //     :on_entry  => :clear,
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = .ESCAPE_INTERMEDIATE },
        0x30...0x4f => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x51...0x57 => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x59 => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x5a => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x5c => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x60...0x7e => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x5b => .{ .action = null, .to_state = .CSI_ENTRY },
        0x5d => .{ .action = null, .to_state = .OSC_STRING },
        0x50 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x58 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x5e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x5f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn escape_intermediate_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x30...0x7e => .{ .action = .ESC_DISPATCH, .to_state = .GROUND },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn csi_entry_table(char: u8) ?StateTransition {
    return switch (char) {
        //     :on_entry  => :clear,
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = .CSI_INTERMEDIATE },
        0x3a => .{ .action = null, .to_state = .CSI_IGNORE },
        0x30...0x39 => .{ .action = .PARAM, .to_state = .CSI_PARAM },
        0x3b => .{ .action = .PARAM, .to_state = .CSI_PARAM },
        0x3c...0x3f => .{ .action = .COLLECT, .to_state = .CSI_PARAM },
        0x40...0x7e => .{ .action = .CSI_DISPATCH, .to_state = .GROUND },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn csi_ignore_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x20...0x3f => .{ .action = .IGNORE, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x40...0x7e => .{ .action = null, .to_state = .GROUND },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn csi_param_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x30...0x39 => .{ .action = .PARAM, .to_state = null },
        0x3b => .{ .action = .PARAM, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x3a => .{ .action = null, .to_state = .CSI_IGNORE },
        0x3c...0x3f => .{ .action = null, .to_state = .CSI_IGNORE },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = .CSI_INTERMEDIATE },
        0x40...0x7e => .{ .action = .CSI_DISPATCH, .to_state = .GROUND },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn csi_intermediate_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .EXECUTE, .to_state = null },
        0x19 => .{ .action = .EXECUTE, .to_state = null },
        0x1c...0x1f => .{ .action = .EXECUTE, .to_state = null },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x30...0x3f => .{ .action = null, .to_state = .CSI_IGNORE },
        0x40...0x7e => .{ .action = .CSI_DISPATCH, .to_state = .GROUND },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn dcs_entry_table(char: u8) ?StateTransition {
    return switch (char) {
        //     :on_entry  => :clear,
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x3a => .{ .action = null, .to_state = .DCS_IGNORE },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = .DCS_INTERMEDIATE },
        0x30...0x39 => .{ .action = .PARAM, .to_state = .DCS_PARAM },
        0x3b => .{ .action = .PARAM, .to_state = .DCS_PARAM },
        0x3c...0x3f => .{ .action = .COLLECT, .to_state = .DCS_PARAM },
        0x40...0x7e => .{ .action = null, .to_state = .DCS_PASSTHROUGH },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn dcs_intermediate_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x30...0x3f => .{ .action = null, .to_state = .DCS_IGNORE },
        0x40...0x7e => .{ .action = null, .to_state = .DCS_PASSTHROUGH },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn dcs_ignore_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x7f => .{ .action = .IGNORE, .to_state = null },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn dcs_param_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x30...0x39 => .{ .action = .PARAM, .to_state = null },
        0x3b => .{ .action = .PARAM, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x3a => .{ .action = null, .to_state = .DCS_IGNORE },
        0x3c...0x3f => .{ .action = null, .to_state = .DCS_IGNORE },
        0x20...0x2f => .{ .action = .COLLECT, .to_state = .DCS_INTERMEDIATE },
        0x40...0x7e => .{ .action = null, .to_state = .DCS_PASSTHROUGH },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn dcs_passthrough_table(char: u8) ?StateTransition {
    return switch (char) {
        //     :on_entry  => :hook,
        0x00...0x17 => .{ .action = .PUT, .to_state = null },
        0x19 => .{ .action = .PUT, .to_state = null },
        0x1c...0x1f => .{ .action = .PUT, .to_state = null },
        0x20...0x7e => .{ .action = .PUT, .to_state = null },
        0x7f => .{ .action = .IGNORE, .to_state = null },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
        //     :on_exit   => :unhook
    };
}

fn sos_pm_apc_string_table(char: u8) ?StateTransition {
    return switch (char) {
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x7f => .{ .action = .IGNORE, .to_state = null },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
    };
}

fn osc_string_table(char: u8) ?StateTransition {
    return switch (char) {
        //     :on_entry  => :osc_start,
        0x00...0x17 => .{ .action = .IGNORE, .to_state = null },
        0x19 => .{ .action = .IGNORE, .to_state = null },
        0x1c...0x1f => .{ .action = .IGNORE, .to_state = null },
        0x20...0x7f => .{ .action = .OSC_PUT, .to_state = null },
        0x18 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x1a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x80...0x8f => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x91...0x97 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x99 => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9a => .{ .action = .EXECUTE, .to_state = .GROUND },
        0x9c => .{ .action = null, .to_state = .GROUND },
        0x1b => .{ .action = null, .to_state = .ESCAPE },
        0x98 => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9e => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x9f => .{ .action = null, .to_state = .SOS_PM_APC_STRING },
        0x90 => .{ .action = null, .to_state = .DCS_ENTRY },
        0x9d => .{ .action = null, .to_state = .OSC_STRING },
        0x9b => .{ .action = null, .to_state = .CSI_ENTRY },
        else => null,
        //     :on_exit   => :osc_end
    };
}

fn make_table_entry(func: TableFunc) [0xFF]u8 {
    var table: [0xFF]u8 = undefined;
    for (&table, 0..) |*slot, i| {
        const value = func(i);
        if (value) |v| {
            var act: u8 = undefined;
            var to_state: u8 = undefined;
            if (v.action) |a| {
                act = @intFromEnum(a);
            } else {
                act = 0;
            }
            if (v.to_state) |s| {
                to_state = @intFromEnum(s);
            } else {
                to_state = 0;
            }
            slot.* = act | (to_state << 4);
        } else {
            slot.* = 0;
        }
    }
    return table;
}

const table_funcs = [@typeInfo(ParserState).Enum.fields.len]TableFunc{
    csi_entry_table,
    csi_ignore_table,
    csi_intermediate_table,
    csi_param_table,
    dcs_entry_table,
    dcs_ignore_table,
    dcs_intermediate_table,
    dcs_param_table,
    dcs_passthrough_table,
    escape_table,
    escape_intermediate_table,
    ground_table,
    osc_string_table,
    sos_pm_apc_string_table,
};

/// Make the table by looping over the
fn make_table() [@typeInfo(ParserState).Enum.fields.len][0xFF]u8 {
    @setEvalBranchQuota(10000);
    var table: [@typeInfo(ParserState).Enum.fields.len][0xFF]u8 = undefined;
    for (&table, table_funcs) |*slot, func| {
        slot.* = make_table_entry(func);
    }
    return table;
}

pub const parse_table = make_table();

pub const entry_actions = [@typeInfo(ParserState).Enum.fields.len]?Action{
    Action.CLEAR, // CSI_ENTRY
    null, // none for CSI_IGNORE ,
    null, // none for CSI_INTERMEDIATE ,
    null, // none for CSI_PARAM ,
    Action.CLEAR, // DCS_ENTRY
    null, // none for DCS_IGNORE ,
    null, // none for DCS_INTERMEDIATE ,
    null, // none for DCS_PARAM ,
    Action.HOOK, // DCS_PASSTHROUGH
    Action.CLEAR, // ESCAPE
    null, // none for ESCAPE_INTERMEDIATE ,
    null, // none for GROUND ,
    Action.OSC_START, // OSC_STRING
    null, // none for SOS_PM_APC_STRING ,
};

pub const exit_actions = [@typeInfo(ParserState).Enum.fields.len]?Action{
    null, // none for CSI_ENTRY
    null, // none for CSI_IGNORE
    null, // none for CSI_INTERMEDIATE
    null, // none for CSI_PARAM
    null, // none for DCS_ENTRY
    null, // none for DCS_IGNORE
    null, // none for DCS_INTERMEDIATE
    null, // none for DCS_PARAM
    Action.UNHOOK, // DCS_PASSTHROUGH
    null, // none for ESCAPE
    null, // none for ESCAPE_INTERMEDIATE
    null, // none for GROUND
    Action.OSC_END, // OSC_STRING
    null, // none for SOS_PM_APC_STRING
};
