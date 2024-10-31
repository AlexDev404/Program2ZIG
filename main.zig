// Tokenization complete

const std = @import("std");

// Global variables
const valid_keys: [4]u8 = [_]u8{ 'a', 'b', 'c', 'd' };
const valid_movement: [4]u8 = [_]u8{ "DRIVE", "BACK", "LEFT", "RIGHT", "SPINL", "SPINR" };
var tokens = std.ArrayList([]const u8).init(std.heap.page_allocator);

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
        try parse(input.?);
        const derivation_success: bool = try leftmost_derivation(tokens);
        if (!derivation_success) {
            std.debug.print("Error in derivation\n", .{});
            // try main();
        }
    }
}

// ------------------------------------------------- Utility Function -------------------------------------------------
// Function to display the BNF grammar
pub fn display_bnf() void {
    // Iterate through the tokens and print each one
    for (tokens.items) |token| {
        std.debug.print("{s}\n", .{token});
    }
    // Clear and free the tokens list
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

// ------------------------------------------------- Tokenization Function -------------------------------------------------
// Function to check if the input is valid
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
// ------------------------------------------------- Parse Function -------------------------------------------------

// To get the controls, wake and sleep will be removed
pub fn parse(input: []const u8) !void {
    // std.debug.print("\nLeftmost Derivation\n", .{});
    var user_input = input;
    var next_input: []const u8 = "";

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

    // Make `next_input` equal to substring of `input` minus the end slice
    next_input = user_input;
    // std.debug.print("Next input 1: '{s}'\n", .{next_input});

    // Remove the "sleep" suffix
    user_input = user_input[0 .. user_input.len - sleep_suffix.len];

    // Print the user input after removing "wake" and "sleep"
    // std.debug.print("User input after removing 'wake' and 'sleep': '{s}'\n", .{user_input});

    // Count semicolons
    var count: usize = 0;
    // Iterate through each character in the input string
    for (user_input) |sc| {
        if (sc == ';') {
            count += 1; // Increment the count if a semicolon is found
        }
    }

    // Find the position of the first semicolon
    const semicolon_index = std.mem.indexOf(u8, user_input, ";");

    // If no semicolon is found, return the entire input as is
    if (semicolon_index == null) {
        std.debug.print("No valid controls found. Controls must end with a ';'.\n", .{});
        return;
    }

    // Dereference the index
    const derivation = semicolon_index.?;
    const first_derivation = user_input[0..derivation];

    // std.debug.print("First derivation: '{s}'\n", .{first_derivation});

    // Use this later to iterate
    // std.debug.print("Count: '{d}'\n", .{count});

    // Get the next input to parse
    next_input = std.mem.trim(u8, user_input[first_derivation.len + 1 ..], " \t\n\r");
    // Print user_input
    // std.debug.print("User input: '{s}'\n", .{user_input});
    // std.debug.print("Next input: '{s}'\n", .{next_input});
    try tokenize_controls(first_derivation);

    // Continue parsing the remaining input
    while (next_input.len > 0) {
        const next_semicolon_index = std.mem.indexOf(u8, next_input, ";");

        if (next_semicolon_index == null) {
            std.debug.print("Error: Missing semicolon in controls.\n", .{});
            return;
        }

        const next_derivation = next_semicolon_index.?;
        const next_control = next_input[0..next_derivation];
        try tokenize_controls(next_control);

        next_input = std.mem.trim(u8, next_input[next_derivation + 1 ..], " \t\n\r");
    }
}

// ------------------------------------------------- Derivation Function -------------------------------------------------

// Function to generate the leftmost derivation output
// pub fn leftmost_derivation() c_int {
//     std.debug.print("\nLeftmost Derivation\n", .{});

//     return 0;

// }

pub fn leftmost_derivation(input: std.ArrayList([]const u8)) !bool {
    // Display the derivation steps
    std.debug.print("\n************************************************************\n", .{});
    std.debug.print("                  Leftmost Derivation:\n", .{});
    std.debug.print("\x1b[1;32m\n", .{});

    // Step 1: Initial form
    var sentential_form: []const u8 = undefined;
    sentential_form = "\x1b[0;32mwake \x1b[1;37m<commands>\x1b[1;0m  \x1b[0;32msleep\x1b[1;0m ";
    std.debug.print("\n<program>  ->  {s}\n", .{sentential_form});
    var loop: usize = 1;
    const allocator = std.heap.page_allocator;

    // Step 2: Progressively replace <commands> with <command><commands> for each command
    const complete_command: bool = false;
    for (input.items, 0..) |current_token, index| {
        std.debug.print("C_INDEX:  {d}--- C_TOKEN: {s}\n", .{ index, current_token });
        if (std.mem.eql(u8, std.mem.trim(u8, current_token, " \t"), "")) {
            // Strip spaces and tabs
            continue;
        }

        // Once we reach the last command, replace <commands> with just <command>
        if (index == input.capacity - 1) {
            const replacement = "";
            const size = std.mem.replacementSize(u8, sentential_form, "<commands>", replacement);
            const output = try allocator.alloc(u8, size);
            // sentential_form = std.mem.replace(u8, sentential_form, "<commands>", "");
            _ = std.mem.replace(u8, sentential_form, "<commands>", replacement, output);
            sentential_form = output;
        }

        loop += 1;
        std.debug.print("{d}         ->  {s}\n", .{ loop, sentential_form });

        // Inner loop: Process commands, validate, and progressively derive
        var past_equal: bool = false;
        var is_at_var: bool = false;
        for (input.items) |command| {
            std.debug.print("COMMAND: {s}\n", .{command});
            // if (validate_command(command)) {

            // Split the command into key and action parts
            var key_part: []const u8 = undefined;
            var action_part: []const u8 = undefined;
            var at_key: bool = false;

            if (command.len > 0) {
                if (std.mem.eql(u8, command, "key")) {
                    at_key = true;
                    if (!complete_command) continue;
                }
                if (std.mem.eql(u8, command, "a") or std.mem.eql(u8, command, "b") or std.mem.eql(u8, command, "c") or std.mem.eql(u8, command, "d")) {
                    key_part = command;
                    is_at_var = true;
                    if (!complete_command) continue;
                }
                if (std.mem.eql(u8, command, "=")) {
                    past_equal = true;
                    continue;
                }
                if (past_equal) {
                    if (std.mem.eql(u8, command, "DRIVE") or std.mem.eql(u8, command, "BACK") or std.mem.eql(u8, command, "LEFT") or std.mem.eql(u8, command, "RIGHT") or std.mem.eql(u8, command, "SPINL") or std.mem.eql(u8, command, "SPINR")) {
                        action_part = command;
                        past_equal = false;
                        if (!complete_command) {
                            if (index == 0) {
                                const replacement = "\x1b[1;37m<command>\x1b[0;35m; \x1b[1;37m<commands>\x1b[1;0m";
                                const size = std.mem.replacementSize(u8, sentential_form, "<commands>", replacement);
                                const output = try allocator.alloc(u8, size);

                                _ = std.mem.replace(u8, sentential_form, "<commands>", replacement, output);
                                sentential_form = output;
                            } else {
                                const replacement = "\x1b[1;37m<command>\x1b[0;35m; \x1b[1;37m<commands>\x1b[1;0m";
                                const size = std.mem.replacementSize(u8, sentential_form, "<commands>", replacement);
                                const output = try allocator.alloc(u8, size);

                                // For subsequent steps, replace the remaining <commands> with <command><commands> progressively
                                _ = std.mem.replace(u8, sentential_form, "<commands>", replacement, output);
                                sentential_form = output;
                            }
                            break;
                        }
                    } else {
                        std.debug.print("\x1b[0;31mError: Invalid movement command\x1b[1;0m\n", .{});
                        return false;
                    }
                }
            }

            // Replace the placeholders in sequence for each command
            if (at_key) {
                const replacement = "\x1b[0;33mkey \x1b[1;37m<button>\x1b[1;0m\x1b[0;35m=\x1b[1;37m<action>\x1b[1;0m";
                const size = std.mem.replacementSize(u8, sentential_form, "<command>", replacement);
                const output = try allocator.alloc(u8, size);
                // sentential_form = std.mem.replace(u8, sentential_form, "<command>", );

                _ = std.mem.replace(u8, sentential_form, "<command>", replacement, output);
                sentential_form = output;
                loop += 1;
                std.debug.print("{d}         ->  {s}\n", .{ loop, sentential_form });
                continue;
            }

            if (is_at_var) {
                if (std.mem.eql(u8, key_part, "a") or std.mem.eql(u8, key_part, "b") or std.mem.eql(u8, key_part, "c") or std.mem.eql(u8, key_part, "d")) {
                    // Replace the <button> placeholder with the actual value
                    const replacement = try std.fmt.allocPrint(allocator, "\x1b[0;31m{s}\x1b[1;0m", .{key_part});
                    const size = std.mem.replacementSize(u8, sentential_form, "<button>", replacement);
                    const output = try allocator.alloc(u8, size);
                    // sentential_form = std.mem.replace(u8, sentential_form, "<button>", "\x1b[0;31m" ++ key_part ++ "\x1b[1;0m");

                    _ = std.mem.replace(u8, sentential_form, "<button>", replacement, output);
                    sentential_form = output;
                    loop += 1;
                    std.debug.print("{d}         ->  {s}\n", .{ loop, sentential_form });
                    is_at_var = false;
                    continue;
                } else {
                    std.debug.print("\x1b[0;31mError: Key must be 'a', 'b', 'c', or 'd'\x1b[1;0m\n", .{});
                    return false;
                }
            }

            if (std.mem.eql(u8, action_part, "DRIVE") or std.mem.eql(u8, action_part, "BACK") or std.mem.eql(u8, action_part, "LEFT") or std.mem.eql(u8, action_part, "RIGHT") or std.mem.eql(u8, action_part, "SPINL") or std.mem.eql(u8, action_part, "SPINR")) {
                // Replace the <action> placeholder with the actual value
                const replacement = try std.fmt.allocPrint(allocator, "\x1b[0;34m{s}\x1b[1;0m", .{action_part});
                const size = std.mem.replacementSize(u8, sentential_form, "<action>", replacement);
                const output = try allocator.alloc(u8, size);
                // sentential_form = std.mem.replace(u8, sentential_form, "<action>", "\x1b[0;34m" ++ action_part ++ "\x1b[1;0m");
                _ = std.mem.replace(u8, sentential_form, "<action>", replacement, output);
                sentential_form = output;
                loop += 1;
                std.debug.print("{d}         ->  {s}\n", .{ loop, sentential_form });
                break;
            } else {
                std.debug.print("\x1b[0;31mError: Invalid movement command\x1b[1;0m\n", .{});
                return false;
            }
            // } else {
            //     return false;
            // }
        }
        std.debug.print("\x1b[0;0m\n", .{});
        // return true;
        // continue;
    } else {
        // Handle invalid format (if "wake" or "sleep" is missing or misplaced)
        std.debug.print("\n************************************************************\n", .{});
        std.debug.print("\x1b[0;31mError: Input must start with 'wake' and end with 'sleep'\x1b[0;0m\n", .{});
        return false;
    }
}
