/// Module which contains definitions for peices (in 0x88)

#[derive(PartialEq)]
pub enum Color {
    WHITE = 32,
    BLACK = 64,
}

impl Color {
    /// Simply flips the color.
    pub fn oponent_color(&self) -> Color {
        match *self {
            Color::WHITE => Color::BLACK,
            Color::BLACK => Color::WHITE,
        }
    }
    /// Converts a color to a bit, which can be used to index fx. castling right information
    pub fn convert_to_bit(&self) -> usize {
        match *self {
            Color::WHITE => 0,
            Color::BLACK => 1,
        }
    }
}

pub enum Peice {
    EMPTY = 0,
    PAWN = 1,
    ROOK = 2,
    BISHOP = 4,
    QUEEN = 6,
    KING = 8,
    KNIGHT = 16,
}

impl Peice {
    pub fn convert_to_char(&self, color: Color) -> char {
        match *self {
            Peice::EMPTY => ' ',
            Peice::PAWN => {
                if color == Color::WHITE {
                    'P'
                } else {
                    'p'
                }
            }
            Peice::ROOK => {
                if color == Color::WHITE {
                    'R'
                } else {
                    'r'
                }
            }
            Peice::BISHOP => {
                if color == Color::WHITE {
                    'B'
                } else {
                    'b'
                }
            }
            Peice::QUEEN => {
                if color == Color::WHITE {
                    'Q'
                } else {
                    'q'
                }
            }
            Peice::KING => {
                if color == Color::WHITE {
                    'K'
                } else {
                    'k'
                }
            }
            Peice::KNIGHT => {
                if color == Color::WHITE {
                    'N'
                } else {
                    'n'
                }
            }
        }
    }
}

/// Converts a 0x88 square, containing information about peice occupancy and color to the appropriate ascii char.
pub fn convert_0x88_square_to_char(information: u8) -> char {
    todo!()
}

/// Converts a color and peice type to an u8.
pub fn convert_color_and_type_to_u8(color: Color, peice: Peice) -> u8 {
    return color as u8 | peice as u8;
}

/// Extracts the color and type from a u8, if possible.
pub fn extract_color_and_type_from_u8(information: u8) -> Option<(Color, Peice)> {
    if information != 0 {
        let color = if information & Color::WHITE as u8 != 0 {
            Color::WHITE
        } else {
            Color::BLACK
        };

        if information & Peice::KNIGHT as u8 != 0 {
            return Some((color, Peice::KNIGHT));
        } else if information & Peice::ROOK as u8 != 0 && information & Peice::BISHOP as u8 != 0 {
            return Some((color, Peice::QUEEN));
        } else if information & Peice::ROOK as u8 != 0 {
            return Some((color, Peice::ROOK));
        } else if information & Peice::BISHOP as u8 != 0 {
            return Some((color, Peice::BISHOP));
        } else if information & Peice::KING as u8 != 0 {
            return Some((color, Peice::KING));
        }
        return Some((color, Peice::PAWN));
    }
    return None;
}
