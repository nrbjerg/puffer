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
