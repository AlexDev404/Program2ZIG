const std = @import("std");

var tokens = std.ArrayList([]const u8).init(std.heap.page_allocator);

// ------------------------------------------------- Main Function -------------------------------------------------
// Loops the process
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
// Shortens the printing process
fn print(message: []const u8) void {
    std.debug.print("{s}\n", .{message});
}

// Function to display the BNF grammar
pub fn display_bnf() void {
    // Iterate through the tokens and print each one
    for (tokens.items) |token| {
        std.debug.print("{s}\n", .{token});
    }
    // Clear and free the tokens list
    tokens.clearAndFree();
    print("\n---------------- Meta-Language for iZEBOT Remote Control ----------------");
    print("\n------------------------------ BNF Grammar ------------------------------");
    print("<program>  \t->\t   wake <controls> sleep");
    print("<controls> \t->\t   <control>");
    print("           \t  \t | <control> <controls>");
    print("<control>  \t->\t   key <key> = <movement> ;");
    print("<key>      \t->\t   a | b | c | d");
    print("<movement> \t->\t   DRIVE | BACK | LEFT | RIGHT | SPINL | SPINR");
    print("\n-------------------------------------------------------------------------\n");
}

// ------------------------------------------------- Tokenization Function -------------------------------------------------
// Function to check if the input is valid
pub fn tokenize_controls(input: []const u8) !void {
    var start_index: usize = 0;

    while (start_index < input.len) {
        // Slice by space
        const next_delimiter = std.mem.indexOf(u8, input[start_index..], " ");

        // If a space delimiter is found, slice the token from start to the delimiter
        if (next_delimiter) |idx| {
            // Get the token and add it to the list
            if (start_index < start_index + idx) {
                const token = input[start_index .. start_index + idx];
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

    // Check if the input ends with "sleep"
    if (!std.mem.eql(u8, end_slice, sleep_suffix)) {
        // If it doesn't have the correct suffix, print an error message
        std.debug.print("Error: controls must end with 'sleep'.\n", .{});
        return;
    }

    // Make `next_input` equal to substring of `input` minus the end slice
    next_input = user_input;

    // Remove the "sleep" suffix
    user_input = user_input[0 .. user_input.len - sleep_suffix.len];

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

    // Get the next input to parse
    next_input = std.mem.trim(u8, user_input[first_derivation.len + 1 ..], " \t\n\r");

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
pub fn leftmost_derivation(input: std.ArrayList([]const u8)) !bool {
    // Display the derivation steps
    print("\n\n--------------------------- Leftmost Derivation ---------------------------\n");

    // Step 1: Initial form
    var original_form: []const u8 = undefined;
    original_form = "wake <controls> sleep ";
    std.debug.print("\n<program>  ->  {s}\n", .{original_form});
    var loop: usize = 1;
    const allocator = std.heap.page_allocator;

    // Step 2: Progressively replace <controls> with <control><controls> for each control
    var complete_control: bool = false;
    var past_equal: bool = false;
    var no_display: bool = false;
    for (input.items, 0..) |current_token, index| {
        std.debug.print("C_INDEX:  {d}--- C_TOKEN: {s}\n", .{ index, current_token });
        if (std.mem.eql(u8, std.mem.trim(u8, current_token, " \t"), "")) {
            // Strip spaces and tabs
            continue;
        }

        loop += 1;

        if (no_display) {
            std.debug.print("{d}         ->  {s}\n", .{ loop, original_form });
            no_display = false;
        }

        // Inner loop: Process controls, validate, and progressively derive
        var is_at_var: bool = false;
        for (input.items, 0..) |control_inner, index_inner| {
            var control = control_inner;

            std.debug.print("CONTROL: {s}\n", .{control});
            // if (validate_control(control)) {

            // Split the control into key and action parts
            var key_part: []const u8 = undefined;
            var action_part: []const u8 = undefined;
            var at_key: bool = false;

            if (complete_control) {
                // Override the current control with the outer control
                control = current_token;
            }
            if (complete_control and index == 1 and index_inner == 0) {
                // Make a patch replacement for the first control we missed
                control = "key";
                at_key = true;
            }
            std.debug.print("UPDATED_CONTROL: {s}\nINNER_INDEX: {d}\n", .{ control, index_inner });

            if (control.len > 0) {
                if (std.mem.eql(u8, control, "key")) {
                    at_key = true;
                    if (!complete_control) continue;
                }
                if (std.mem.eql(u8, control, "a") or std.mem.eql(u8, control, "b") or std.mem.eql(u8, control, "c") or std.mem.eql(u8, control, "d")) {
                    key_part = control;
                    is_at_var = true;
                    if (!complete_control) continue;
                }
                if (std.mem.eql(u8, control, "=")) {
                    past_equal = true;
                    std.debug.print("PAST_EQUAL_O: {}\n", .{past_equal});
                    if (!complete_control) {
                        // Make a patch replacement for the first control we missed
                        continue;
                    } else {
                        no_display = true;
                        break;
                    }
                }
                if (past_equal) {
                    std.debug.print("PAST_EQUAL: {s}\n", .{control});
                    if (std.mem.eql(u8, control, "DRIVE") or std.mem.eql(u8, control, "BACK") or std.mem.eql(u8, control, "LEFT") or std.mem.eql(u8, control, "RIGHT") or std.mem.eql(u8, control, "SPINL") or std.mem.eql(u8, control, "SPINR")) {
                        action_part = control;
                        past_equal = false;
                        if (!complete_control) {
                            // Check to see if we're at the last control
                            // Once we reach the last control, replace <controls> with just <control>
                            if (index_inner == input.capacity - 1) {
                                std.debug.print("END OF SEQUENCE\n", .{});

                                std.debug.print("{d}         ->  {s}\n", .{ loop, original_form });
                                const replacement = "<control>";
                                const size = std.mem.replacementSize(u8, original_form, "<controls>", replacement);
                                var output: []const u8 = try allocator.alloc(u8, size);
                                // original_form = std.mem.replace(u8, original_form, "<controls>", "");
                                output = try replaceFirstOccurrence(original_form, "<controls>", replacement);
                                // _ = std.mem.replace(u8, original_form, "<controls>", replacement, output);
                                original_form = output;

                                complete_control = true;
                                break;
                            } else if (index_inner == 0) {
                                const replacement = "\x1b[1;37m<control>\x1b[0;35m; \x1b[1;37m<controls>\x1b[1;0m";
                                const size = std.mem.replacementSize(u8, original_form, "<controls>", replacement);
                                const output = try allocator.alloc(u8, size);

                                _ = std.mem.replace(u8, original_form, "<controls>", replacement, output);
                                original_form = output;
                            } else {
                                const replacement = "\x1b[1;37m<control>\x1b[0;35m; \x1b[1;37m<controls>\x1b[1;0m";
                                const size = std.mem.replacementSize(u8, original_form, "<controls>", replacement);
                                const output = try allocator.alloc(u8, size);

                                // For subsequent steps, replace the remaining <controls> with <control><controls> progressively
                                _ = std.mem.replace(u8, original_form, "<controls>", replacement, output);
                                original_form = output;
                            }

                            continue;
                        }
                        // continue;
                    } else {
                        std.debug.print("\x1b[0;31mError2: Invalid movement control\x1b[1;0m\n", .{});
                        return false;
                    }
                }
            }

            // Replace the placeholders in sequence for each control
            if (at_key) {
                const replacement = "\x1b[0;33mkey \x1b[1;37m<key>\x1b[1;0m\x1b[0;35m=\x1b[1;37m<action>\x1b[1;0m";
                const size = std.mem.replacementSize(u8, original_form, "<control>", replacement);
                // const output = try allocator.alloc(u8, size);
                // original_form = std.mem.replace(u8, original_form, "<control>", );

                var output: []const u8 = try allocator.alloc(u8, size);
                output = try replaceFirstOccurrence(original_form, "<control>", replacement);
                // _ = std.mem.replace(u8, original_form, "<control>", replacement, output);
                original_form = output;
                loop += 1;
                std.debug.print("{d}         ->  {s}\n", .{ loop, original_form });
                if (index == 1 and index_inner == 0) {
                    continue;
                } else {
                    break;
                }
            }

            if (is_at_var) {
                if (std.mem.eql(u8, key_part, "a") or std.mem.eql(u8, key_part, "b") or std.mem.eql(u8, key_part, "c") or std.mem.eql(u8, key_part, "d")) {
                    // Replace the <key> placeholder with the actual value
                    const replacement = try std.fmt.allocPrint(allocator, "\x1b[0;31m{s}\x1b[1;0m", .{key_part});
                    const size = std.mem.replacementSize(u8, original_form, "<key>", replacement);
                    const output = try allocator.alloc(u8, size);
                    // original_form = std.mem.replace(u8, original_form, "<key>", "\x1b[0;31m" ++ key_part ++ "\x1b[1;0m");

                    _ = std.mem.replace(u8, original_form, "<key>", replacement, output);
                    original_form = output;
                    loop += 1;
                    // std.debug.print("{d}         ->  {s}\n", .{ loop, original_form });
                    is_at_var = false;
                    break;
                } else {
                    std.debug.print("Error: Key must be 'a', 'b', 'c', or 'd'.\n", .{});
                    return false;
                }
            }

            if (std.mem.eql(u8, action_part, "DRIVE") or std.mem.eql(u8, action_part, "BACK") or std.mem.eql(u8, action_part, "LEFT") or std.mem.eql(u8, action_part, "RIGHT") or std.mem.eql(u8, action_part, "SPINL") or std.mem.eql(u8, action_part, "SPINR")) {
                // Replace the <action> placeholder with the actual value
                const replacement = try std.fmt.allocPrint(allocator, "\x1b[0;34m{s}\x1b[1;0m", .{action_part});
                const size = std.mem.replacementSize(u8, original_form, "<action>", replacement);
                const output = try allocator.alloc(u8, size);
                // original_form = std.mem.replace(u8, original_form, "<action>", "\x1b[0;34m" ++ action_part ++ "\x1b[1;0m");
                _ = std.mem.replace(u8, original_form, "<action>", replacement, output);
                original_form = output;
                loop += 1;
                std.debug.print("{d}         ->  {s}\n", .{ loop, original_form });
                break;
            } else {
                std.debug.print("\x1b[0;31mError: Invalid movement control. Got '{s}'\x1b[1;0m\n", .{action_part});
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
        std.debug.print("\n------------------------------------------------------------\n", .{});
        std.debug.print("\x1b[0;31mError: Input must start with 'wake' and end with 'sleep'\x1b[0;0m\n", .{});
        return false;
    }
}

fn replaceFirstOccurrence(original: []const u8, target: []const u8, replacement: []const u8) ![]const u8 {
    // std.ArrayList([]const u8).init(std.heap.page_allocator);
    var result = std.ArrayList(u8).init(std.heap.page_allocator);
    defer result.deinit();

    var found = false;
    var i: usize = 0;
    while (i < original.len) : (i += 1) {
        if (!found and std.mem.startsWith(u8, original[i..], target)) {
            try result.appendSlice(replacement);
            i += target.len - 1; // Skip the target substring
            found = true;
        } else {
            try result.append(original[i]);
        }
    }

    return result.toOwnedSlice();
}
