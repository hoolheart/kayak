use bcrypt::{hash, DEFAULT_COST};

fn main() {
    let password = "Admin123";
    match hash(password, DEFAULT_COST) {
        Ok(hashed) => {
            println!("{}", hashed);
        }
        Err(e) => eprintln!("Error: {}", e),
    }
}
