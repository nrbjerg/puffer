/// Module containing helper functions.

/// Converts a set of algebraic cordinates to a square index
pub fn convert_alg_to_0x88(cords: String) -> u8 {
    let file = cords.chars().nth(0).unwrap() as u8 - 'a' as u8;
    let rank = cords.chars().nth(1).unwrap() as u8 - '0' as u8;
    return 16 * rank + file;
}

/// Converts a square index to a set of algebraic cordinates
pub fn convert_0x88_to_alg(sq0x88: u8) -> String {
    let file = sq0x88 & 7;
    let rank = sq0x88 >> 4;
    return format!("{}{}", (file + 'a' as u8) as char, rank);
}
