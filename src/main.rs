mod helpers;
mod peices;
mod position;

fn main() {
    let pos = position::Position::new();
    println!("{}", pos.convert_to_fen_string());
}
