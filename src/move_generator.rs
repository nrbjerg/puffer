use crate::move_and_undo::MoveInfo;
use crate::peices::Color;
use crate::position::Position;

/// Returns a vector containing the moves
pub fn get_moves(pos: &Position, color: &Color) -> Vec<MoveInfo> {
    return vec![];
}

/// A perft performance test.
pub fn perft(pos: &mut Position, depth: usize) -> usize {
    let active_color = &pos.information.active_color;
    let moves = get_moves(pos, active_color);
    if depth == 1 {
        return moves.len();
    }

    let mut counter = 0;
    for move_info in moves {
        pos.make_move(move_info);
        counter += perft(pos, depth - 1);
        pos.undo_move();
    }
    return counter;
}

mod tests {
    use crate::move_generator::perft;
    use crate::position::Position;
    use std::time::Instant;

    #[test]
    #[cfg(feature = "with_perft")]
    fn perft_test() {
        // NOTE: Can be run along the usual test suite using "cargo test --features with_perft"
        let fens_and_number_of_nodes = [
            (
                String::from("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"),
                vec![20, 400, 8902, 197281, 4865609],
            ),
            (
                String::from(
                    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
                ),
                vec![48, 2039, 97862],
            ),
            (
                String::from("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"),
                vec![14, 191, 2812, 43238, 674624],
            ),
            (
                String::from("r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"),
                vec![6, 264, 9467, 422333],
            ),
            (
                String::from("rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8"),
                vec![44, 1486, 62379, 2103487],
            ),
        ];
        for (fen, nodes_per_depth) in fens_and_number_of_nodes {
            let start = Instant::now();
            let mut pos = Position::load_from_fen(fen.clone());
            for (depth, nodes) in nodes_per_depth.iter().enumerate() {
                assert_eq!(perft(&mut pos, depth + 1), *nodes);
            }
            let end = Instant::now();
            println!(
                "FEN: {}, took: {}.{}",
                fen,
                (end - start).as_secs(),
                (end - start).as_millis() % 1000
            );
        }
    }
}
