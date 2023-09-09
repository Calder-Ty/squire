//! Funcs for parsing the arguments
const std = @import("std");

const DELIMETER = ' ';

const String = [:0]u8;

/// The Arguments that are parsed into the file
pub const CmdArgs = struct {
    /// Name of the program
    cmd: String,
    args: []String,
};

const ArgparseErrors = error{
    EmptyArgumentSet,
};

pub fn parse_args(args: [][:0]u8) ArgparseErrors!CmdArgs {
    if (args.len == 0) {
        return ArgparseErrors.EmptyArgumentSet;
    }
    return CmdArgs{ .cmd = args[0], .args = args[1..] };
}
