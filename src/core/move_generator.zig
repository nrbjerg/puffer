/// This files contains a psuedo legal move generator and tests to measure the performance of which.
const std = @import("std");
const types = @import("types.zig");
const Direction = @import("types.zig").Direction;
const Peice = @import("types.zig").Peice;
const Position = @import("types.zig").Position;
const Move = @import("types.zig").Move;

/// Generates a list of pseudo legal moves.
pub fn generate_moves(pos: Position, allocator: std.mem.Allocator) !std.ArrayList(Move) {
    // NOTE: Average number of legal moves are about 35, so we over eastimate it to avoid doing extra allocations
    // https://chess.stackexchange.com/questions/23135/what-is-the-average-number-of-legal-moves-per-turn
    var moves = std.ArrayList(Move).initCapacity(allocator, 64) catch unreachable;

    const player_byte = @intFromEnum(pos.active_color);
    //const opponent_byte = @intFromEnum(pos.active_color.flip());
    for (types.SquareIndicies) |sq0x88| {
        if (pos.board[sq0x88] & player_byte != 0) {
            switch (pos.board[sq0x88] ^ player_byte) {
                @intFromEnum(Peice.PAWN) => {},
                @intFromEnum(Peice.KNIGHT) => {},
                @intFromEnum(Peice.BISHOP) => {},
                @intFromEnum(Peice.ROOK) => {},
                @intFromEnum(Peice.QUEEN) => {},
                @intFromEnum(Peice.KING) => {
                    inline for (@typeInfo(Direction).Enum.fields) |field| {
                        const destination_sq0x88 = sq0x88 +% field.value;
                        if (destination_sq0x88 & 0x88 == 0 and pos.board[destination_sq0x88] & player_byte == 0) {
                            try moves.append(Move{ .frm = @enumFromInt(sq0x88), .to = @enumFromInt(destination_sq0x88), .move_flags = types.MoveFlags.Quiet });
                        }
                    }
                },
                else => unreachable,
            }
        }
    }
    return moves;
}

/// Used for performing perft tests.
fn perft(pos: Position, depth: usize, allocator: std.mem.Allocator) !usize {
    var moves = try generate_moves(pos, allocator);
    defer moves.deinit();

    if (depth == 1) {
        const number_of_moves = moves.items.len; // NOTE: needed because of the defer
        return number_of_moves;
    } else {
        // Count the number of nodes in the game tree.
        var nodes: usize = 0;
        for (moves.items) |move| {
            pos.play_move(move);
            if (!pos.is_in_check()) {
                nodes += perft(pos, depth - 1);
            }
            pos.undo_move();
        }
        return nodes;
    }
}

test "Perft Test" {
    // NOTE: enpassant on e3 is not technically posible in this position, since
    //       the white queen is on e2, however it is included for testing purposes

    // zig fmt: off
    const fen_strings = [3][]const u8{ 
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 
        "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
        "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", 
    };
    const array_of_expected_number_of_nodes = [3][4]usize{ 
        [_]usize{ 20, 400, 8_902, 197_281 }, 
        [_]usize{ 14, 191, 2_812, 43_238 },
        [_]usize{ 6, 264, 9_467, 422_333 }, 
    };
    // zig fmt: on

    for (fen_strings, array_of_expected_number_of_nodes) |fen_string, expected_number_of_nodes| {
        var total_number_of_nodes: usize = 0;
        for (expected_number_of_nodes) |number_of_nodes| {
            total_number_of_nodes += number_of_nodes;
        }

        std.debug.print("\n - Fen: '{s}'", .{fen_string});
        const pos = try Position.load_from_fen(fen_string);
        const start_timestamp = std.time.microTimestamp();
        for (expected_number_of_nodes, 1..) |number_of_nodes, depth| {
            try std.testing.expect(try perft(pos, depth, std.testing.allocator) == number_of_nodes);
        }
        std.debug.print("\n   Took a total of {any} ms for a total of {any}", .{ std.time.microTimestamp() - start_timestamp, total_number_of_nodes });
    }
    std.debug.print("\n", .{});
}
