const std = @import("std");

pub const Square = enum(u8) {
    // zig fmt: off
    A1 = 0, B1, C1, D1, E1, F1, G1, H1,
    A2 = 16, B2, C2, D2, E2, F2, G2, H2,
    A3 = 32, B3, C3, D3, E3, F3, G3, H3,
    A4 = 48, B4, C4, D4, E4, F4, G4, H4,
    A5 = 64, B5, C5, D5, E5, F5, G5, H5,
    A6 = 80, B6, C6, D6, E6, F6, G6, H6,
    A7 = 96, B7, C7, D7, E7, F7, G7, H7,
    A8 = 112, B8, C8, D8, E8, F8, G8, H8,
    // zig fmt: on

    /// The set of indicies corresponding to the set of characters.
    pub const indicies = init: {
        var indicies_array: [64]u8 = [_]u8{undefined} ** 64;
        inline for (@typeInfo(Square).Enum.fields, 0..) |field, idx| {
            const sq0x88 = field.value;
            indicies_array[idx] = sq0x88;
        }

        break :init indicies_array;
    };

    /// Gets the appropriate square from a set of algebraic cordinates.
    pub fn from_algebraic(cords: []const u8) ?Square {
        if (cords.len != 2) {
            return null;
        } else {
            const file: usize = @as(u8, @truncate(cords[0] - 'a'));
            const rank: usize = @as(u8, @truncate(cords[1] - '1'));
            return @enumFromInt(rank * 16 + file);
        }
    }

    /// Converts a square to a string representation of its self.
    pub fn to_algebraic(self: Square) []const u8 {
        const rank = @intFromEnum(self) >> 4;
        const file = @intFromEnum(self) % 16;
        const coords = [_]u8{ 'a' + file, '1' + rank };
        return coords[0..coords.len];
    }
};

pub const Direction = enum(u8) {
    NORTHWEST = 15, // 255 - 17
    NORTH,
    NORTHEAST,
    WEST = 255,
    EAST = 1,
    SOUTHWEST = 239,
    SOUTH = 240,
    SOUTHEAST = 241,

    /// Returns the set of offsets for pawn attacks of a given color
    pub fn pawnAttackOffsets(color: Color) [2]u8 {
        if (color == Color.WHITE) {
            return [_]u8{ @intFromEnum(Direction.NORTHEAST), @intFromEnum(Direction.NORTHWEST) };
        } else {
            return [_]u8{ @intFromEnum(Direction.SOUTHEAST), @intFromEnum(Direction.SOUTHWEST) };
        }
    }

    // zig fmt: off
    pub const orthogonalOffsets: [4]u8 = [_]u8{
            @intFromEnum(Direction.NORTH), 
            @intFromEnum(Direction.EAST), 
            @intFromEnum(Direction.SOUTH), 
            @intFromEnum(Direction.WEST)
        };

    pub const diagonalOffsets: [4]u8 = [_]u8{
            @intFromEnum(Direction.NORTHEAST), 
            @intFromEnum(Direction.NORTHWEST), 
            @intFromEnum(Direction.SOUTHEAST), 
            @intFromEnum(Direction.SOUTHWEST)
    };
    pub const knightOffsets: [8]u8 = [_]u8{  
        @intFromEnum(Direction.NORTH) +% @intFromEnum(Direction.NORTHWEST),
        @intFromEnum(Direction.NORTH) +% @intFromEnum(Direction.NORTHEAST),
        @intFromEnum(Direction.EAST) +% @intFromEnum(Direction.NORTHEAST),
        @intFromEnum(Direction.EAST) +% @intFromEnum(Direction.SOUTHEAST),
        @intFromEnum(Direction.SOUTH) +% @intFromEnum(Direction.SOUTHEAST),
        @intFromEnum(Direction.SOUTH) +% @intFromEnum(Direction.SOUTHWEST),
        @intFromEnum(Direction.WEST) +% @intFromEnum(Direction.SOUTHWEST),
        @intFromEnum(Direction.WEST) +% @intFromEnum(Direction.NORTHWEST),
    };
    // zig fmt: on
};

pub const MoveFlags = enum(u4) {
    Quiet,
    Capture,
    Promotion,
    DoublePush,
};

pub const Move = struct {
    frm: Square,
    to: Square,
    move_flags: MoveFlags, // Capture,
};

pub const Color = enum(u8) {
    WHITE = 0b1000_0000,
    BLACK = 0b0100_0000,

    /// Simply flips the color.
    pub inline fn flip(self: Color) Color {
        return @enumFromInt(@intFromEnum(self) ^ 0b1100_0000);
    }
};

pub const Peice = enum(u8) {
    PAWN = 0b0000_0001,
    ROOK = 0b0000_0010,
    BISHOP = 0b0000_0100,
    QUEEN = 0b000_0110,
    KNIGHT = 0b0000_1000,
    KING = 0b0001_0000,
    EMPTY = 0b0000_0000,

    pub fn convert_byte_to_char(byte: u8) u8 {
        return switch (byte) {
            @intFromEnum(Peice.PAWN) => 'p',
            @intFromEnum(Peice.ROOK) => 'r',
            @intFromEnum(Peice.BISHOP) => 'b',
            @intFromEnum(Peice.QUEEN) => 'q',
            @intFromEnum(Peice.KNIGHT) => 'n',
            @intFromEnum(Peice.KING) => 'k',
            else => '.',
        };
    }
};
