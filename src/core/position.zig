const std = @import("std");
const Square = @import("types.zig").Square;
const Color = @import("types.zig").Color;
const Peice = @import("types.zig").Peice;
const Direction = @import("types.zig").Direction;

pub const Position = struct {
    board: [128]u8,
    enpassant: ?Square,
    castling_rights: [2][2]bool,
    half_move_clock: u8,
    full_move_clock: u16,
    active_color: Color,
    parrent: ?*Position, // Simply used to undo moves (NOTE: temperary, should be updated later.)

    pub fn load_from_fen(fen: []const u8) !Position {
        var iter = std.mem.split(u8, fen, " ");

        // 1. Parse the board information
        var board = [_]u8{0} ** 128;
        var idx0x88: usize = 0x70;
        for (iter.next().?) |c| {
            switch (c) {
                '1'...'8' => {
                    idx0x88 += @as(usize, c - '0');
                },
                '/' => {
                    idx0x88 = ((idx0x88 / 16) - 1) * 16;
                },
                else => {
                    const color = if (std.ascii.isUpper(c)) Color.WHITE else Color.BLACK;
                    board[idx0x88] = @intFromEnum(color) | switch (std.ascii.toLower(c)) {
                        'p' => @intFromEnum(Peice.PAWN),
                        'n' => @intFromEnum(Peice.KNIGHT),
                        'b' => @intFromEnum(Peice.BISHOP),
                        'r' => @intFromEnum(Peice.ROOK),
                        'q' => @intFromEnum(Peice.QUEEN),
                        'k' => @intFromEnum(Peice.KING),
                        else => unreachable,
                    };
                    idx0x88 += 1;
                },
            }
        }

        // 2. Parse the active color
        const active_color = if (iter.next().?[0] == 'w') Color.WHITE else Color.BLACK;

        // 3. Pass castling rights
        var castling_rights = [2][2]bool{ [_]bool{ false, false }, [_]bool{ false, false } };
        for (iter.next().?) |c| {
            switch (c) {
                'K' => castling_rights[0][0] = true,
                'Q' => castling_rights[0][1] = true,
                'k' => castling_rights[1][0] = true,
                'q' => castling_rights[1][1] = true,
                '-' => break,
                else => unreachable,
            }
        }

        // 4. Parse the en passant square
        const enpassant = Square.from_algebraic(iter.next().?);

        // 5. Parse half and full move clocks
        const half_move_clock = try std.fmt.parseUnsigned(u8, iter.next().?, 10);
        const full_move_clock = try std.fmt.parseUnsigned(u16, iter.next().?, 10);

        return Position{ .board = board, .active_color = active_color, .castling_rights = castling_rights, .enpassant = enpassant, .half_move_clock = half_move_clock, .full_move_clock = full_move_clock, .parrent = null };
    }

    /// Converts a chess position to a fen string.
    pub fn convert_to_fen(self: Position, allocator: std.mem.Allocator) !std.ArrayList(u8) {
        // 1. Convert the 0x88 array to the inital part of a fen string.

        var buffer = try std.ArrayList(u8).initCapacity(allocator, 128);

        var number_of_empty_squares: u8 = 0;
        for (0..8) |reversed_rank| {
            for (0..8) |file| {
                const sq0x88 = (7 - reversed_rank) * 16 + file;
                // If we just got to a new rank, we need to add a '/' before the peice information.
                if (sq0x88 % 8 == 0 and sq0x88 != 0x70) {
                    if (number_of_empty_squares != 0) {
                        try buffer.append('0' + number_of_empty_squares);
                        number_of_empty_squares = 0;
                    }
                    try buffer.append('/');
                }

                if (self.board[sq0x88] != @intFromEnum(Peice.EMPTY)) {
                    if (number_of_empty_squares != 0) {
                        try buffer.append('0' + number_of_empty_squares);
                        number_of_empty_squares = 0;
                    }

                    // NOTE: Only the 5 final bits are for the peice type.
                    const peice_char: u8 = switch (self.board[sq0x88] & 0b0001_1111) {
                        @intFromEnum(Peice.PAWN) => 'p',
                        @intFromEnum(Peice.KNIGHT) => 'n',
                        @intFromEnum(Peice.BISHOP) => 'b',
                        @intFromEnum(Peice.ROOK) => 'r',
                        @intFromEnum(Peice.QUEEN) => 'q',
                        @intFromEnum(Peice.KING) => 'k',
                        else => unreachable,
                    };

                    const is_white_peice = self.board[sq0x88] & 0b1100_0000 == @intFromEnum(Color.WHITE);
                    try buffer.append(if (is_white_peice) std.ascii.toUpper(peice_char) else peice_char);
                } else {
                    number_of_empty_squares += 1;
                }
            }
        }
        if (number_of_empty_squares != 0) {
            try buffer.append('0' + number_of_empty_squares);
        }

        //std.mem.reverse(u8, buffer.items);
        //std.debug.print("{s}\n", .{buffer.items});

        // 2. Append the active color
        try buffer.append(' ');
        try buffer.append(if (self.active_color == Color.WHITE) 'w' else 'b');

        // 3. Append the castling rights
        try buffer.append(' ');
        if (self.castling_rights[0][0] or self.castling_rights[0][1] or self.castling_rights[1][0] or self.castling_rights[1][1]) {
            if (self.castling_rights[0][0]) try buffer.append('K');
            if (self.castling_rights[0][1]) try buffer.append('Q');
            if (self.castling_rights[1][0]) try buffer.append('k');
            if (self.castling_rights[1][1]) try buffer.append('q');
        } else {
            try buffer.append('-');
        }

        // 4. Append the en passant square
        if (self.enpassant == null) {
            try buffer.appendSlice(" -");
        } else {
            try buffer.append(' ');
            try buffer.append(@constCast(self.enpassant.?.to_algebraic())[0]); // FIXME: Weird but nessary to avoid a segfault.
            try buffer.append(@constCast(self.enpassant.?.to_algebraic())[1]);
        }

        // 5. Append half and full move clocks
        var temp: [16]u8 = undefined;
        try buffer.append(' ');
        try buffer.appendSlice(try std.fmt.bufPrint(&temp, "{}", .{self.half_move_clock}));

        try buffer.append(' ');
        try buffer.appendSlice(try std.fmt.bufPrint(&temp, "{}", .{self.full_move_clock}));

        return buffer;
    }

    /// Checks if the current player is in check
    pub fn is_in_check(self: Position) bool {
        const player_byte = @intFromEnum(self.active_color);
        const opponent_byte = @intFromEnum(self.active_color.flip());

        // 1. Find the position of the king.
        var king0x88: u8 = undefined;
        for (Square.indicies) |sq0x88| {
            if (self.board[sq0x88] == @intFromEnum(Peice.KING) ^ player_byte) {
                king0x88 = sq0x88;
                break;
            }
        }

        // 2. Check for pawns and kngihts.
        for (Direction.pawnAttackOffsets(self.active_color)) |offset| {
            // NOTE: if the king can attack the pawns on the diagonal, then the pawns can attack him.
            const sq0x88 = king0x88 +% offset;
            if (sq0x88 & 0x88 == 0 and self.board[sq0x88] == @intFromEnum(Peice.PAWN) | opponent_byte) {
                return true;
            }
        }

        for (Direction.knightOffsets) |offset| {
            const sq0x88 = king0x88 +% offset;
            if (sq0x88 & 0x88 == 0 and self.board[sq0x88] == @intFromEnum(Peice.KNIGHT) | opponent_byte) {
                return true;
            }
        }

        // 3. Check for sliding peices (Rooks, Bishops, Queens and Kings).
        for (Direction.diagonalOffsets) |offset| {
            for (1..8) |steps_in_dir| {
                const n: u8 = @truncate(steps_in_dir);
                const sq0x88: u8 = king0x88 +% n *% offset;
                if (sq0x88 & 0x88 != 0) break;

                if (self.board[sq0x88] != @intFromEnum(Peice.EMPTY)) {
                    if (self.board[sq0x88] & player_byte != 0) {
                        break;
                    } else {
                        const peice_bits = self.board[sq0x88] ^ opponent_byte;
                        if (peice_bits == @intFromEnum(Peice.BISHOP) or peice_bits == @intFromEnum(Peice.QUEEN) or peice_bits == @intFromEnum(Peice.KING)) {
                            return true;
                        }
                    }
                }
            }
        }
        for (Direction.orthogonalOffsets) |offset| {
            for (1..8) |steps_in_dir| {
                const n: u8 = @truncate(steps_in_dir);
                const sq0x88: u8 = king0x88 +% n *% offset;
                if (sq0x88 & 0x88 != 0) break;

                if (self.board[sq0x88] != @intFromEnum(Peice.EMPTY)) {
                    if (self.board[sq0x88] & player_byte != 0) {
                        break;
                    } else {
                        const peice_bits = self.board[sq0x88] ^ opponent_byte;
                        if (peice_bits == @intFromEnum(Peice.ROOK) or peice_bits == @intFromEnum(Peice.QUEEN) or peice_bits == @intFromEnum(Peice.KING)) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    pub fn debug_print(self: Position) void {
        for (0..8) |reversed_rank| {
            for (0..8) |file| {
                const sq0x88 = (7 - reversed_rank) * 16 + file;

                var char = Peice.convert_byte_to_char(self.board[sq0x88] & 0b0011_1111);
                if (self.board[sq0x88] & @intFromEnum(Color.WHITE) != 0) {
                    char = std.ascii.toUpper(char);
                }
                std.debug.print("{c} ", .{char});
            }
            std.debug.print("\n", .{});
        }
    }
};

test "Basic Test Of Fen String Functionallity" {
    // NOTE: enpassant on e3 is not technically posible in this position, since
    //       the white queen is on e2, however it is included for testing purposes
    // zig fmt: off
    const fen_strings = [2][]const u8{ 
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - e3 0 10",
    };
    // zig fmt: on
    for (fen_strings) |fen_string| {
        const pos = try Position.load_from_fen(fen_string);
        const generated_fen = try pos.convert_to_fen(std.testing.allocator);
        defer generated_fen.deinit();
        std.debug.print("\n - Board Fen: '{s}'", .{generated_fen.items});
        try std.testing.expect(std.mem.eql(u8, generated_fen.items, fen_string));
    }
    std.debug.print("\n", .{});
}

test "Test for the 'is_in_check' method." {
    // zig fmt: off
    const fen_strings = [_][]const u8{
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "8/8/8/5k2/4P3/8/8/8 b - - 0 1",
        "8/8/8/5p2/4K3/8/8/8 w - - 0 1",
        "8/8/8/4n3/8/5K2/8/8 w - - 0 1",
        "r6K/8/8/8/8/8/8/8 w - - 0 1",
        "r4P1K/8/8/8/8/8/8/8 w - - 0 1",
        "8/8/8/8/2b5/8/4K3/8 w - - 0 1",
        "8/8/8/8/2b5/3P4/4K3/8 w - - 0 1",
    };
    const should_the_corresponding_position_be_in_check = [_]bool{
        false, 
        true,
        true, 
        true, 
        true, 
        false, 
        true, 
        false
    };
    // zig fmt: on
    for (fen_strings, should_the_corresponding_position_be_in_check) |fen_string, should_be_in_check| {
        std.debug.print("\n - Board Fen: '{s}'\n    + should be in check: {}\n", .{ fen_string, should_be_in_check });
        const pos = try Position.load_from_fen(fen_string);
        pos.debug_print();
        try std.testing.expect(pos.is_in_check() == should_be_in_check);
    }
    std.debug.print("\n", .{});
}
