/*
TO BE MORE EFFICIENT ASSUME THAT PATTERN IS IN ASCENDING ORDER
*/

// Constants used in the program
// Most constants have been centralized here except if they are only used in one file
pub const PATTERN: [usize; 3] = [467, 933, 1400];
pub const MTU: usize = 1500;
pub const CHAFF: [u8; MTU] = [0; MTU];
const WRAP_AND_WIREGUARD_OVERHAD: f64 = 100.0;
pub const IP_HEADER_LEN: usize = 20;
pub const IP_SRC_ADDR_OFFSET: usize = 12;
pub const IP_DST_ADDR_OFFSET: usize = 16;
pub const ETH_HEADER_LEN: usize = 14;
pub const ETH_MAC_SRC_ADDR_OFFSET: usize = 6;
pub const IP_ADDR_LEN: usize = 4;
pub const MAC_ADDR_LEN: usize = 6;
pub const IP_VERSION: u8 = 4;
pub const OBF_ETHERTYPE: pnet::packet::ethernet::EtherType = pnet::packet::ethernet::EtherType(2049);

// Usually this would be done with routing tables, but since I needed to send the packet back to its source for my test I hardcoded the wireguard address of Zurich
pub const IP_NEXT_HOP: [u8;4] = [10, 7, 0 , 2];

pub fn get_sorted_indices() -> Vec<usize> {
    /// Gets sorted indices needed to match incoming packets and the corresponding queue index to choose.
    let mut indices: Vec<usize> = (0..PATTERN.len()).collect();
    // Sort the indices based on the corresponding values in the data vector
    indices.sort_by_key(|&i| &PATTERN[i]);
    indices
}

pub fn get_push_state_vector() -> Vec<(usize,usize)> {
    /// Store in a vector the ranges of each state [state_start_index,next_state_start.
    /// Fancy encoding so no need to use hash maps and reduce overhead compared to accessing lists. 
    /// Since patterns are relatively small and in increasing order it should be ok.
    /// Make the vector as long as the pattern for easier processing after.
    /// e.g PATTERN=[100,200,300,300,300,500] gives [(0,1),(1,2),(2,5),(2,5),(2,5),(5,6)].
    /// First number in tuple is next queue to push to, second number is the index at which the next state starts.
    let mut state = Vec::new();
    let mut count = 0;

    let mut previous_state = 0;
    for i in 0..PATTERN.len() {
        if i < PATTERN.len()-1 && PATTERN[i] == PATTERN[i+1] {
            count += 1
        } else {
            for _ in 0..count+1 {
                state.push((previous_state,i+1));
            }
            previous_state = i+1;
            count = 0;
        }
    }
    state
}

pub fn get_average_pattern_length() -> f64 {
    /// Utility function to get the average length of the pattern.
    let mut total = 0.0;
    for p in PATTERN {
        total += p as f64;
    }
    total / PATTERN.len() as f64 + WRAP_AND_WIREGUARD_OVERHAD
}