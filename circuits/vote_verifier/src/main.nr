/// bb write_vk -b ./target/vote_verifier.json
/// bb contract
//  nargo test --show-output

fn main(voter_address: pub Field, vote: str<8>, commitment: pub Field, curent_hash: pub Field, updated_hash: pub Field) {
    // Validate the vote format
    validate_vote_format(vote);
    // Convert the vote to a Field element
    let vote_field = convert_vote_to_field(vote);
    // Verify the commitment matches
    verify_commitment(voter_address, vote_field, commitment);

    // Verify the updated hash for the contract
    let updated_hash_computed = std::hash::poseidon2::Poseidon2::hash(
        [curent_hash, commitment],
        2, 
    );
    // Ensure the computed hash matches the expected hash
    assert_eq(updated_hash_computed, updated_hash, "Invalid updated hash");
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
    println("vote_string: ");
    println(vote_string);

    // Convert string to bytes to field, exactly as the main circuit does
    let vote_bytes = vote_string.as_bytes();

    let vote_field = Field::from_be_bytes::<8>(vote_bytes);
    println("Noir vote_field");
    println(vote_field);

    // Calculate commitment hash with domain separator 2
    let commitment = std::hash::poseidon2::Poseidon2::hash([voter_address, vote_field], 2);
    println("Noir commitment hash: ");
    println(commitment);

    // Initially current hash is 0
    let current_hash = 0;
    println("Initial current hash: ");
    println(current_hash);

    // Calculate updated hash (hash of current hash and commitment)
    let updated_hash = std::hash::poseidon2::Poseidon2::hash([current_hash, commitment], 2);
    println("Updated hash after vote: ");
    println(updated_hash);

    // Simulate a second vote to show how the hash is updated
    let second_voter_address: Field = 4567;
    let second_vote_string: str<8> = "10000000";
    let second_vote_field = Field::from_be_bytes::<8>
    (second_vote_string.as_bytes());
    
    println("Second voter_address: ");
    println(second_voter_address);
    println("Second vote_string: ");
    println(second_vote_string);
    // Calculate commitment for second vote
    let second_commitment = std::hash::poseidon2::Poseidon2::hash([second_voter_address, second_vote_field], 2);
    println("Second vote commitment: ");
    println(second_commitment);
    
    // Current hash is now the previous updated hash
    let second_current_hash = updated_hash;
    
    // Calculate new updated hash
    let second_updated_hash = std::hash::poseidon2::Poseidon2::hash([second_current_hash, second_commitment], 2);
    println("Updated hash after second vote: ");
    println(second_updated_hash);
}