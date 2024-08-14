use std::sync::Mutex;
use crate::queues::priority_queue;
use crate::pattern;

pub static TOTAL_PAD: Mutex<f64> = Mutex::new(0.0);

pub struct RoundRobinScheduler {
    /// Implementation of a round-robin scheduler to get packets from the priority queues and send them to the network while following the correct pattern.
    pub queues: Vec<priority_queue::PriorityQueue>,
    pub pps: f64
}

impl RoundRobinScheduler {
    pub fn new(num_queues: usize, pps: f64, src: [u8;4], dst: [u8;4]) -> RoundRobinScheduler {
        /// Creates a priority queue for every pattern state.
        /// The round robin scheduler operates at a certain rate defined by a number of packets per second (pps).
        let mut queues = Vec::with_capacity(num_queues);
        for i in 0..num_queues {
            queues.push(priority_queue::PriorityQueue::new(pattern::PATTERN[i], src, dst));
        }
        RoundRobinScheduler {
            queues,
            pps: pps,
        }
    }

    pub fn push(&self, packet: Vec<u8>, last_queues: &Vec<(usize,usize)>) -> usize {
        /// Pushes a packet to the correct priority queue.
        /// Decides on the priority queue based on the length of the packet.
        /// It assumes that the pattern is defined in ascending order in pattern.rs.
        let mut is_pushed = false;
        let mut current_q = self.queues.len(); // Return this if unable to push
        let length = packet.len();
        for i in 0..self.queues.len() {
            // Look if fits in pattern from smallest to largest element
            if packet.len() <= pattern::PATTERN[i] { // Assumes pattern is in ascending order!!
                let idx = last_queues[i].0;
                self.queues[idx].push(packet); 
                current_q = i;
                
                is_pushed = true;
                // Keep track of total padding
                let mut data = TOTAL_PAD.lock().unwrap();
                *data += (self.queues[i].length - length) as f64 / self.pps;
                break;
            }
        }
        if !is_pushed {
            //println!("Could not push packet of length {}", length);
        }
        current_q
    }

    pub fn push_no_reorder(&self, packet: Vec<u8>, idx: usize) -> usize {
        /// Push the packet to the next queue that can accomodate it instead of the one of the nearest length.
        /// This should decrease packet reordering at the cost of more padding.
        /// Could be interesting to explore more for future work.
        let pkt_len = packet.len();
        let mut current_q = idx;
        for i in 0..self.queues.len() {
            current_q = (idx+i) % self.queues.len();
            if pkt_len <= self.queues[current_q].length {
                self.queues[current_q].push(packet);
                break;
            }
        }
        (current_q+1) % self.queues.len()
    }

    pub fn pop(&self, idx: usize) -> Vec<u8> {
        /// Pop from the current with the given index.
        self.queues[idx].pop()
    }
}