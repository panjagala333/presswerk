// Presswerk FFI Implementation
//
// C-compatible FFI layer matching the Idris2 ABI definitions in src/abi/.
// Types and codes MUST match Types.idr and Protocol.idr exactly.
//
// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

const std = @import("std");

const VERSION = "0.1.0";
const BUILD_INFO = "Presswerk built with Zig " ++ @import("builtin").zig_version_string;

/// Thread-local error storage
threadlocal var last_error: ?[]const u8 = null;

fn setError(msg: []const u8) void {
    last_error = msg;
}

fn clearError() void {
    last_error = null;
}

//==============================================================================
// Core Types (must match src/abi/Types.idr)
//==============================================================================

/// Result codes — matches Types.idr resultToInt
pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    invalid_param = 2,
    out_of_memory = 3,
    null_pointer = 4,
    unsupported = 5,
};

/// Job status — matches Types.idr jobStatusToInt
pub const JobStatus = enum(c_int) {
    pending = 0,
    processing = 1,
    completed = 2,
    failed = 3,
    cancelled = 4,
    held = 5,
};

/// IPP operation codes — matches Protocol.idr ippOpCode
pub const IppOp = enum(u16) {
    print_job = 0x0002,
    validate_job = 0x0004,
    cancel_job = 0x0008,
    get_job_attributes = 0x0009,
    get_jobs = 0x000A,
    get_printer_attrs = 0x000B,
};

/// Document type
pub const DocType = enum(c_int) {
    pdf = 0,
    jpeg = 1,
    png = 2,
    tiff = 3,
    plain_text = 4,
    native_delegate = 5,
};

//==============================================================================
// Opaque Handle
//==============================================================================

const InternalHandle = struct {
    allocator: std.mem.Allocator,
    initialized: bool,
};

pub const Handle = opaque {};

/// Cast an opaque Handle back to the internal representation.
///
/// SAFETY: This cast is proven safe by the Idris2 ABI layer:
///   - Layout.idr proves struct alignment (all fields naturally aligned)
///   - Bridge.idr OpaqueHandleSafe proves the cast roundtrip is valid
///   - presswerk_init allocates via c_allocator (always aligned)
///   - @alignCast is a no-op for heap allocations (naturally aligned)
fn toInternal(handle: *Handle) *InternalHandle {
    return @ptrCast(@alignCast(handle));
}

//==============================================================================
// Library Lifecycle
//==============================================================================

/// Initialise the Presswerk FFI layer
export fn presswerk_init() ?*Handle {
    const allocator = std.heap.c_allocator;

    const internal = allocator.create(InternalHandle) catch {
        setError("Failed to allocate handle");
        return null;
    };

    internal.* = .{
        .allocator = allocator,
        .initialized = true,
    };

    clearError();
    // SAFETY: InternalHandle → Handle cast is the inverse of toInternal.
    // Proven safe by Bridge.idr OpaqueHandleSafe — same pointer, opaque type.
    return @ptrCast(internal);
}

/// Free the Presswerk handle
export fn presswerk_free(handle: ?*Handle) void {
    const h = handle orelse return;
    const internal = toInternal(h);

    internal.initialized = false;
    internal.allocator.destroy(internal);
    clearError();
}

//==============================================================================
// Job State Machine
//==============================================================================

/// Validate a job status transition.
/// Returns .ok if the transition is valid per Protocol.idr, .invalid_param otherwise.
export fn presswerk_validate_transition(from: JobStatus, to: JobStatus) Result {
    const valid = switch (from) {
        .pending => switch (to) {
            .processing, .cancelled, .held => true,
            else => false,
        },
        .processing => switch (to) {
            .completed, .failed, .cancelled => true,
            else => false,
        },
        .held => switch (to) {
            .pending, .cancelled => true,
            else => false,
        },
        // Terminal states
        .completed, .failed, .cancelled => false,
    };

    if (valid) {
        clearError();
        return .ok;
    } else {
        setError("Invalid job state transition");
        return .invalid_param;
    }
}

//==============================================================================
// Document Hashing (SHA-256)
//==============================================================================

/// Compute SHA-256 hash of a buffer.
/// Output must point to a 32-byte buffer.
export fn presswerk_hash(
    buffer: ?[*]const u8,
    len: u32,
    output: ?[*]u8,
) Result {
    const buf = buffer orelse {
        setError("Null input buffer");
        return .null_pointer;
    };

    const out = output orelse {
        setError("Null output buffer");
        return .null_pointer;
    };

    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(buf[0..len]);
    hasher.final(out[0..32]);

    clearError();
    return .ok;
}

//==============================================================================
// Error Handling
//==============================================================================

/// Get the last error message (null if none)
export fn presswerk_last_error() ?[*:0]const u8 {
    const err = last_error orelse return null;
    const allocator = std.heap.c_allocator;
    const c_str = allocator.dupeZ(u8, err) catch return null;
    return c_str.ptr;
}

//==============================================================================
// Version
//==============================================================================

export fn presswerk_version() [*:0]const u8 {
    return VERSION.ptr;
}

export fn presswerk_build_info() [*:0]const u8 {
    return BUILD_INFO.ptr;
}

//==============================================================================
// Utility
//==============================================================================

export fn presswerk_is_initialized(handle: ?*Handle) u32 {
    const h = handle orelse return 0;
    const internal = toInternal(h);
    return if (internal.initialized) 1 else 0;
}

//==============================================================================
// Tests
//==============================================================================

test "lifecycle" {
    const handle = presswerk_init() orelse return error.InitFailed;
    defer presswerk_free(handle);
    try std.testing.expect(presswerk_is_initialized(handle) == 1);
}

test "valid transitions" {
    try std.testing.expectEqual(Result.ok, presswerk_validate_transition(.pending, .processing));
    try std.testing.expectEqual(Result.ok, presswerk_validate_transition(.processing, .completed));
    try std.testing.expectEqual(Result.ok, presswerk_validate_transition(.pending, .cancelled));
    try std.testing.expectEqual(Result.ok, presswerk_validate_transition(.held, .pending));
}

test "invalid transitions" {
    try std.testing.expectEqual(Result.invalid_param, presswerk_validate_transition(.completed, .pending));
    try std.testing.expectEqual(Result.invalid_param, presswerk_validate_transition(.failed, .processing));
    try std.testing.expectEqual(Result.invalid_param, presswerk_validate_transition(.cancelled, .pending));
}

test "sha256 hash" {
    const input = "hello";
    var output: [32]u8 = undefined;
    const result = presswerk_hash(input.ptr, input.len, &output);
    try std.testing.expectEqual(Result.ok, result);
    // SHA-256("hello") first byte is 0x2c
    try std.testing.expectEqual(@as(u8, 0x2c), output[0]);
}

test "version" {
    const ver = presswerk_version();
    const ver_str = std.mem.span(ver);
    try std.testing.expectEqualStrings(VERSION, ver_str);
}
