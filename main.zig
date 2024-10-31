// Tokenization complete

const std = @import("std");

// Global variables
const valid_keys: [4]u8 = [_]u8{ 'a', 'b', 'c', 'd' };
const valid_movement: [4]u8 = [_]u8{ "DRIVE", "BACK", "LEFT", "RIGHT", "SPINL", "SPINR" };
var tokens = std.ArrayList([]const u8).init(std.heap.page_allocator);

// Function to display the BNF grammar
pub fn display_bnf() void {
    for (tokens.items) |token| {
        std.debug.print("{s}\n", .{token});
    }
    tokens.clearAndFree();
    std.debug.print("\n---------------- Meta-Language for iZEBOT Remote Control ----------------", .{});
    std.debug.print("\n------------------------------ BNF Grammar ------------------------------\n", .{});
    std.debug.print("<program>  \t->\t   wake <controls> sleep\n", .{});
    std.debug.print("<controls> \t->\t   <control>\n", .{});
    std.debug.print("           \t  \t | <control> <controls>\n", .{});
    std.debug.print("<control>  \t->\t   key <key> = <movement> ;\n", .{});
    std.debug.print("<key>      \t->\t   a | b | c | d\n", .{});
    std.debug.print("<movement> \t->\t   DRIVE | BACK | LEFT | RIGHT | SPINL | SPINR\n", .{});
    std.debug.print("\n-------------------------------------------------------------------------\n\n", .{});
}

// ------------------------------------------------- Derivation Process -------------------------------------------------

//pub fn parse_key(input: []const u8) !void {}

//pub fn parse_movement(input: []const u8) !void {}

// To get the controls, wake and sleep will be removed
pub fn get_controls(input: []const u8) !void {
    std.debug.print("\nLeftmost Derivation\n", .{});
    var user_input = input;

    // Define the prefix and suffix
    const wake_prefix = "wake ";
    const sleep_suffix = " sleep";

    // Check if there is content between "wake" and "sleep"
    if (user_input.len <= 11) { // 10 characters for validation
        std.debug.print("Error: No content between wake and sleep.\n", .{});
        return;
    }

    // Check if the input starts with "wake"
    if (!std.mem.startsWith(u8, user_input, wake_prefix)) {
        std.debug.print("Error: controls must start with 'wake'.\n", .{});
        return; // Exit the function on error
    }

    // Remove the "wake " prefix
    user_input = user_input[wake_prefix.len..];

    // Calculate the starting index for the slice we want to check
    const end_slice_start = (user_input.len - 1) - sleep_suffix.len;
    // Get the portion of the input that should match the suffix
    const end_slice = user_input[end_slice_start + 1 ..];

    // std.debug.print("end_slice_start: {}\n", .{end_slice_start});
    // std.debug.print("end_slice: '{s}'\n", .{end_slice});

    // Check if the input ends with "sleep"
    if (!std.mem.eql(u8, end_slice, sleep_suffix)) {
        // If it doesn't have the correct suffix, print an error message
        std.debug.print("Error: controls must end with 'sleep'.\n", .{});
        return;
    }

    // Remove the "sleep" suffix
    user_input = user_input[0 .. user_input.len - sleep_suffix.len];

    // Print the user input after removing "wake" and "sleep"
    // std.debug.print("User input after removing 'wake' and 'sleep': '{s}'\n", .{user_input});

    try parse_controls(user_input);
}

// Parsing the instuctions to be derivated
pub fn parse_controls(input: []const u8) !void {

    // Count semicolons
    var count: usize = 0;
    // Iterate through each character in the input string
    for (input) |sc| {
        if (sc == ';') {
            count += 1; // Increment the count if a semicolon is found
        }
    }

    // Find the position of the first semicolon
    const semicolon_index = std.mem.indexOf(u8, input, ";");

    // If no semicolon is found, return the entire input as is
    if (semicolon_index == null) {
        std.debug.print("No valid controls found. Controls must end with a ';'.\n", .{});
        return;
    }

    // Derefernce the index
    const derivation = semicolon_index.?;
    const first_derivation = input[0..derivation];

    std.debug.print("First derivation: '{s}'\n", .{first_derivation});

    // Use this later to iterate
    std.debug.print("Count: '{d}'\n", .{count});

    try tokenize_controls(first_derivation);
}

pub fn tokenize_controls(input: []const u8) !void {
    var start_index: usize = 0;

    while (start_index < input.len) {
        // slice by space
        const next_delimiter = std.mem.indexOf(u8, input[start_index..], " ");

        // If a space delimiter is found, slice the token from start to the delimiter
        if (next_delimiter) |idx| {
            // Get the token and add it to the list
            if (start_index < start_index + idx) {
                const token = input[start_index .. start_index + idx];
                //try parse_key(token[1]);
                //try parse_movement(token[3]);
                // std.debug.print("Second character of token {s}\n", .{token});
                try tokens.append(token);
            }
            // Move the start index past the delimiter
            start_index += idx + 1; // +1 to skip the space itself
        } else {
            // No more delimiters, add the last token
            if (start_index < input.len) {
                const token = input[start_index..];
                try tokens.append(token);
            }
            break;
        }
    }
}

// Main function that loops the process
pub fn main() !void {
    const stdin = std.io.getStdIn().reader();

    // Continue getting input from the user until input is "END"
    while (true) {
        // Display BNF grammar
        display_bnf();

        // Prompt user to input string
        std.debug.print("Enter a string (or 'END' to exit): ", .{});

        // Storing the input
        var buffer: [128]u8 = undefined;
        const input = try stdin.readUntilDelimiterOrEof(&buffer, '\n');

        // Check if the input length is at least 3
        const exit_prog = "END";
        const check = std.mem.eql(u8, input.?.ptr[0..3], exit_prog);

        if (check == true) {
            std.debug.print("Exiting program...\n\n", .{});
            break;
        }

        // Call Derivation and handle potential error
        try get_controls(input.?);
    }
}
