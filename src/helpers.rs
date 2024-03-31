/// Module containing helper functions.

/// Converts a set of algebraic cordinates to a square index
pub fn convert_alg_to_0x88(cords: String) -> Result<u8, &'static str> {
    let file = cords.chars().nth(0).unwrap();
    let rank = cords.chars().nth(1).unwrap();

    if "abcdefgh".contains(file) && "12345678".contains(rank) {
        return Ok(16 * (rank as u8 - 'a' as u8) + (file as u8 - '0' as u8));
    } else {
        return Err("Did not recive a set of valid algebraic cordinates");
    }
}

/// Converts a square index to a set of algebraic cordinates
pub fn convert_0x88_to_alg(sq0x88: u8) -> String {
    let file = sq0x88 & 7;
    let rank = sq0x88 >> 4;
    return format!("{}{}", (file + 'a' as u8) as char, rank);
}

pub enum Direction {
    NORTH = 16,
    SOUTH = -16,
    EAST = 1,
    WEST = -1,
    NORTH_EAST = 17,
    NORTH_WEST = 15,
    SOUTH_EASH = -15,
    SOUTH_WEST = -17,
}

#[rustfmt::skip]
pub enum Sq0x88 {
    A8 =0x70, B8, C8, D8, E8, F8, G8, H8,
    A7 =0x60, B7, C7, D7, E7, F7, G7, H7,
    A6 =0x50, B6, C6, D6, E6, F6, G6, H6,
    A5 =0x40, B5, C5, D5, E5, F5, G5, H5,
    A4 =0x30, B4, C4, D4, E4, F4, G4, H4,
    A3 =0x20, B3, C3, D3, E3, F3, G3, H3,
    A2 =0x10, B2, C2, D2, E2, F2, G2, H2,
    A1 =0x00, B1, C1, D1, E1, F1, G1, H1,
}
