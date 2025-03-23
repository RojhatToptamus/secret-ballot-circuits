/// bb write_vk -b ./target/tally_verifier.json
/// bb contract
//  nargo test --show-output
use dep::std;
global MAX_VOTERS: u32 = 100;

fn main(
    final_commitment: pub Field, // Public input - final commitment hash stored on-chain
    yes_votes: pub u32, // Public input - number of yes votes
    user_addresses: [Field; MAX_VOTERS],
    plain_votes: [str<8>; MAX_VOTERS],
) {
    // initial values
    let mut total_voters = 0;
    let mut current_hash: Field = 0;
    let mut yes_vote_count = 0;

    for i in 0..MAX_VOTERS {
        let zero_field: Field = 0;
        if user_addresses[i] != zero_field {
            let (vote, is_yes_vote) = get_vote(plain_votes[i]);
            let vote_commitment =
                std::hash::poseidon2::Poseidon2::hash([user_addresses[i], vote], 2);
            // note the order of the hash inputs matters
            current_hash =
                std::hash::poseidon2::Poseidon2::hash([current_hash, vote_commitment], 2);
            total_voters += 1;

            // Increment yes_vote_count if it's a yes vote
            yes_vote_count += is_yes_vote;
        }
    }

    // Verify the computed hash matches the root
    assert_eq(final_commitment, current_hash, "Invalid hash");
    println(final_commitment);
    // Verify the count of yes votes matches the public input
    assert_eq(yes_votes, yes_vote_count, "Invalid yes vote count");
}

// Function to extract vote information
fn get_vote(plain_vote: str<8>) -> (Field, u32) {
    let vote_bytes = plain_vote.as_bytes();
    let vote_field = Field::from_be_bytes::<8>(vote_bytes);

    // Check if the first character is '1' (ASCII code 49)
    // If it is, return 1 for yes vote, otherwise 0
    let is_yes_vote = if vote_bytes[0] == 49 { 1 } else { 0 };

    (vote_field, is_yes_vote)
}
#[test]
fn test_voting_flow() {
    let mut user_addresses: [Field; MAX_VOTERS] = [0; MAX_VOTERS];
    let mut plain_votes: [str<8>; MAX_VOTERS] = ["00000000"; MAX_VOTERS];

    user_addresses[0] = 123;
    // First voter votes 'yes' (starts with 1)
    plain_votes[0] = "10123456";

    user_addresses[1] = 456;
    // Second voter votes 'no' (starts with 0)
    plain_votes[1] = "00123456";

    user_addresses[2] = 789;
    // Third voter votes 'no' (starts with 0)
    plain_votes[2] = "05123456";

    user_addresses[3] = 101112;
    // Fourth voter votes 'no' (starts with 0)
    plain_votes[3] = "01123456";

    let mut current_hash: Field = 0;

    for i in 0..4 {
        let (vote, _) = get_vote(plain_votes[i]);
        let vote_commitment = std::hash::poseidon2::Poseidon2::hash([user_addresses[i], vote], 2);
        current_hash = std::hash::poseidon2::Poseidon2::hash([current_hash, vote_commitment], 2);
    }

    let expected_root_hash = current_hash;
    // Count of 'yes' votes (only the first vote is 'yes')
    let expected_yes_count: u32 = 1;

    main(
        expected_root_hash,
        expected_yes_count,
        user_addresses,
        plain_votes,
    );
}
