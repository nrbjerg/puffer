#![allow(dead_code)]
#![allow(unused_variables)]

use crate::helpers::{convert_0x88_to_alg, convert_alg_to_0x88};
use crate::peices::{convert_color_and_type_to_u8, extract_color_and_type_from_u8, Color, Peice};

pub struct Position {
    pub board: [u8; 128],
    pub information: Information,
}

pub struct Information {
    pub active_color: Color,
    pub castling_rights: [[bool; 2]; 2],
    pub enpassant_square: Option<u8>,
    pub half_move_clock: u8, // NOTE: for 50 move rule.
    pub full_move_clock: usize,
}

impl Position {
    /// Loads a position from a fen string.
    pub fn load_from_fen(fen_string: String) -> Position {
        let mut iterator = fen_string.split_ascii_whitespace();
        let mut board: [u8; 128] = [0; 128];
        if let Some(board_info) = iterator.next() {
            let mut sq0x88 = 0x70;
            for c in board_info.chars() {
                if c == '/' {
                    sq0x88 -= 24;
                } else if c.is_numeric() {
                    sq0x88 += c as usize - '0' as usize;
                } else {
                    let color = if c.is_uppercase() {
                        Color::WHITE
                    } else {
                        Color::BLACK
                    };
                    let peice = match c.to_lowercase().next().unwrap() {
                        'p' => Peice::PAWN,
                        'n' => Peice::KNIGHT,
                        'k' => Peice::KING,
                        'r' => Peice::ROOK,
                        'q' => Peice::QUEEN,
                        'b' => Peice::BISHOP,
                        _ => panic!("Unexpected character in fen string!"),
                    };
                    board[sq0x88] = convert_color_and_type_to_u8(color, peice);

                    sq0x88 += 1;
                }
            }
        }

        let mut active_color = Color::WHITE;
        if let Some(active_color_info) = iterator.next() {
            if active_color_info == "b" {
                active_color = Color::BLACK;
            }
        }

        let mut castling_rights = [[false; 2]; 2];
        if let Some(castling_info) = iterator.next() {
            castling_rights = [
                [castling_info.contains("Q"), castling_info.contains("K")],
                [castling_info.contains("q"), castling_info.contains("k")],
            ];
        }

        let mut enpassant_square = None;
        if let Some(enpassant_info) = iterator.next() {
            if enpassant_info != "-" {
                enpassant_square = Some(convert_alg_to_0x88(enpassant_info.to_string()));
            }
        }

        let mut half_move_clock = 0;
        if let Some(half_move_info) = iterator.next() {
            half_move_clock = half_move_info.parse::<u8>().unwrap();
        }

        let mut full_move_clock = 0;
        if let Some(full_move_info) = iterator.next() {
            full_move_clock = full_move_info.parse::<usize>().unwrap();
        }

        return Position {
            board,
            information: Information {
                active_color,
                castling_rights,
                enpassant_square,
                half_move_clock,
                full_move_clock,
            },
        };
    }

    /// Initialises the starting position
    pub fn new() -> Position {
        return Position::load_from_fen(String::from(
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        ));
    }

    /// Returns the fen stirng coresponding to the given position
    pub fn convert_to_fen_string(self) -> String {
        let mut strings = Vec::new();

        let mut counter = 0;
        let mut board_info = String::new();

        // NOTE: We start in the upper most left corner. moving from A8 to B8 ect.
        for rank in (0..8).rev() {
            for file in (0..8) {
                let sq0x88 = 16 * rank + file;
                match extract_color_and_type_from_u8(self.board[sq0x88]) {
                    None => counter += 1,
                    Some((color, peice)) => {
                        if counter != 0 {
                            board_info.push((counter + '0' as u8) as char);
                            counter = 0;
                            board_info.push(peice.convert_to_char(color))
                        } else {
                            board_info.push(peice.convert_to_char(color))
                        }
                    }
                }
            }
            if counter != 0 {
                board_info.push((counter + '0' as u8) as char);
                counter = 0;
            }
            if rank != 0 {
                board_info.push('/');
            }
        }

        strings.push(board_info.as_str());

        strings.push(if self.information.active_color == Color::WHITE {
            "w"
        } else {
            "b"
        });

        let mut castling_info = String::new();

        if self.information.castling_rights[Color::WHITE.convert_to_bit()][1] {
            castling_info.push('K');
        }
        if self.information.castling_rights[Color::WHITE.convert_to_bit()][0] {
            castling_info.push('Q');
        }
        if self.information.castling_rights[Color::BLACK.convert_to_bit()][1] {
            castling_info.push('k');
        }
        if self.information.castling_rights[Color::BLACK.convert_to_bit()][0] {
            castling_info.push('q');
        }
        strings.push(if castling_info != "" {
            &castling_info
        } else {
            "-"
        });

        let mut enpassant_information = String::from("-");
        if let Some(square_index) = self.information.enpassant_square {
            enpassant_information = convert_0x88_to_alg(square_index).to_owned();
        }
        strings.push(&enpassant_information);

        let half_move_clock = self.information.half_move_clock.to_string().to_owned();
        strings.push(&half_move_clock);

        let full_move_clock = self.information.full_move_clock.to_string().to_owned();
        strings.push(&full_move_clock);

        return strings.join(" ");
    }
    /// Simply prints the board to the terminal
    pub fn print_0x88_board(&self) {
        todo!();
    }
}

#[cfg(test)]
mod tests {
    use crate::position::Position;

    #[test]
    fn test_fen() {
        let fen_strings = [
            // NOTE: These are also the perft test positions, from the chess programming wiki
            String::from("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"),
            String::from("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"),
            String::from("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"),
            String::from("r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"),
            String::from("rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8"),
        ];
        for fen_string in fen_strings {
            let pos = Position::load_from_fen(fen_string.clone());
            assert_eq!(fen_string, pos.convert_to_fen_string());
        }
    }
}
