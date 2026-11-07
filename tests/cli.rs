//! Smoke test for the template binary.

use std::error::Error;
use std::process::Command;

#[test]
fn binary_greets_and_exits_successfully() -> Result<(), Box<dyn Error>> {
    let output = Command::new(env!(concat!("CARGO_BIN_EXE_", env!("CARGO_PKG_NAME")))).output()?;

    assert!(output.status.success(), "binary exited with failure");
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "Hello, world!"
    );
    Ok(())
}
