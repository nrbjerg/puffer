use crate::helpers::{convert_0x88_to_alg, convert_alg_to_0x88};
use crate::peices::Peice;
use std::fmt;
use std::str::FromStr;

#[derive(Debug)]
pub enum MoveFlag {
    QUIET,
    DOBULE_PUSH,
    OO,
    OOO,
    CAPTURE,
    EN_PASSANT,
    PR_KNIGHT,
    PR_BISHOP,
    PR_ROOK,
    PR_QUEEN,
}

/// Stores everything needed to make a move.
pub struct MoveInfo {
    // FIXME: It should be posible to store a move in 16 bits, 6 bits for "frm" and "to" and 4 bits for "move flags"
    pub to: u8,
    pub frm: u8,
    pub flag: MoveFlag,
}

impl fmt::Display for MoveInfo {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Move[from: {}, to: {}, flag: {:?}]",
            convert_0x88_to_alg(self.frm),
            convert_0x88_to_alg(self.to),
            self.flag
        )
    }
}

//impl FromStr for MoveInfo {
//    fn from_str(s: &str) -> Result<Self, &'static str> {
//        todo!();
//        // FIXME: Should probally do some error checking for instance we might have s = m9m10
//        // if let Some(frm) = convert_alg_to_0x88(&s[0..2]) {
//        //     if let Some(to) = convert_alg_to_0x88(&s[2..4]) {
//        //         return Ok(MoveInfo {
//        //             to,
//        //             frm,
//        //             flag: MoveFlag::QUIET, // TODO: should not automatically be quiet.
//        //         });
//        //     }
//        // }
//        // return Err("Invalid move.");
//    }
//}

/// Stores all information needed to undo a move.
pub struct UndoInfo {
    to: u8,
    frm: u8,
    captured: Option<Peice>,
    en_passant_sq0x88: Option<u8>,
}
