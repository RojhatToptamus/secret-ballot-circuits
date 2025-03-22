/// bb write_vk -b ./target/vote_verifier.json
/// bb contract
//  nargo test --show-output

fn main(voter_address: pub Field, vote: str<8>, commitment: pub Field) {
    // Validate the vote format
    validate_vote_format(vote);
    // Convert the vote to a Field element
    let vote_field = convert_vote_to_field(vote);
    // Verify the commitment matches
    verify_commitment(voter_address, vote_field, commitment);
}

/// Ensures the vote has valid format - 8 characters with first char being '0' or '1'
fn validate_vote_format(vote: str<8>) {
    let vote_bytes = vote.as_bytes();
    // Verify the length
    assert(vote_bytes.len() == 8, "Vote must be exactly 8 characters");
    // Check first character is either '0' (48) or '1' (49) in ASCII
    let first_char = vote_bytes[0];
    assert((first_char == 48) | (first_char == 49), "Vote must start with 0 or 1");
}

/// Converts a vote string to its Field representation
fn convert_vote_to_field(vote: str<8>) -> Field {
    let vote_bytes = vote.as_bytes();
    Field::from_be_bytes::<8>(vote_bytes)
}

/// Verifies that the commitment hash matches the computed hash
fn verify_commitment(voter_address: Field, vote_field: Field, expected_hash: Field) {
    let computed_hash = std::hash::poseidon2::Poseidon2::hash(
        [voter_address, vote_field],
        2, // Domain separator
    );

    assert_eq(computed_hash, expected_hash, "Invalid commitment hash");
}

#[test]
fn test_commitment_hash_calculation() {
    // Use the exact values from our application
    let voter_address: Field = 1323;
    let vote_string: str<8> = "01234567";
    println("voter_address: ");
    println(voter_address);

    // Convert string to bytes to field, exactly as the main circuit does
    let vote_bytes = vote_string.as_bytes();
    println("Noir vote bytes:");
    println(vote_bytes);

    let vote_field = Field::from_be_bytes::<8>(vote_bytes);
    println("Noir vote_field");
    println(vote_field);

    // Calculate hash with domain separator 2
    let hash = std::hash::poseidon2::Poseidon2::hash([voter_address, vote_field], 2);
    println("Noir final hash with separator 2: ");
    println(hash);
}
