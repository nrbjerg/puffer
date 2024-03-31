mod helpers;
mod move_and_undo;
mod move_generator;
mod peices;
mod position;

fn main() {
    let pos = position::Position::new();
    println!("{}", pos.convert_to_fen_string());
}
