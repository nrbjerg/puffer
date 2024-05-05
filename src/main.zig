const std = @import("std");
const types = @import("types.zig");
const Position = @import("position.zig").Position;
const move_generator = @import("move_generator.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const pos = try Position.load_from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    pos.debug_print();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();
    const fen = try pos.convert_to_fen(allocator);
    defer fen.deinit();
    std.debug.print("Fen string of position: {s}\n", .{fen.items});
}
