||| Presswerk Foreign Function Interface Declarations
|||
||| All C-compatible functions implemented in the Zig FFI layer.
||| Each function is declared with its type signature and wrapped
||| in a safe Idris2 interface that enforces non-null handles.
|||
||| Implementations live in ffi/zig/src/main.zig
|||
||| SPDX-License-Identifier: PMPL-1.0-or-later
||| Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

module Presswerk.ABI.Foreign

import Presswerk.ABI.Types
import Presswerk.ABI.Layout

%default total

--------------------------------------------------------------------------------
-- Library Lifecycle
--------------------------------------------------------------------------------

||| Initialize the Presswerk library.
||| Returns a non-null handle on success, 0 on failure.
export
%foreign "C:presswerk_init, libpresswerk"
prim__init : PrimIO Bits64

||| Safe wrapper: returns Nothing on null pointer.
export
init : IO (Maybe Handle)
init = do
  ptr <- primIO prim__init
  pure (createHandle ptr)

||| Shut down the library and free all resources.
export
%foreign "C:presswerk_free, libpresswerk"
prim__free : Bits64 -> PrimIO ()

||| Safe wrapper: only accepts a valid Handle.
export
free : Handle -> IO ()
free h = primIO (prim__free (handlePtr h))

||| Check whether the library is initialized.
export
%foreign "C:presswerk_is_initialized, libpresswerk"
prim__isInitialized : Bits64 -> PrimIO Bits32

export
isInitialized : Handle -> IO Bool
isInitialized h = do
  r <- primIO (prim__isInitialized (handlePtr h))
  pure (r /= 0)

--------------------------------------------------------------------------------
-- Version Information
--------------------------------------------------------------------------------

||| Return a pointer to a static version string ("0.1.0").
export
%foreign "C:presswerk_version, libpresswerk"
prim__version : PrimIO Bits64

||| Read the static version string.
export
%foreign "support:idris2_getString, libidris2_support"
prim__getString : Bits64 -> String

export
version : IO String
version = do
  ptr <- primIO prim__version
  pure (prim__getString ptr)

--------------------------------------------------------------------------------
-- Print Job Operations
--------------------------------------------------------------------------------

||| Submit a print job.
|||
||| Parameters:
|||   handle      – library handle
|||   data_ptr    – pointer to document bytes
|||   data_len    – byte length of document
|||   doc_type    – document type code (see Types.DocType)
|||   printer_uri – pointer to null-terminated printer URI
|||
||| Returns: result code (0 = Ok, 1 = Error, …)
export
%foreign "C:presswerk_print_submit, libpresswerk"
prim__printSubmit : Bits64 -> Bits64 -> Bits32 -> Bits32 -> Bits64 -> PrimIO Bits32

||| Safe wrapper with error translation.
export
printSubmit : Handle -> (dataPtr : Bits64) -> (dataLen : Bits32)
            -> (docType : Bits32) -> (printerUri : Bits64)
            -> IO (Either Result ())
printSubmit h dataPtr dataLen docType uri = do
  r <- primIO (prim__printSubmit (handlePtr h) dataPtr dataLen docType uri)
  pure (resultFromCode r)

||| Cancel a print job by its internal integer ID.
export
%foreign "C:presswerk_print_cancel, libpresswerk"
prim__printCancel : Bits64 -> Bits32 -> PrimIO Bits32

export
printCancel : Handle -> (jobId : Bits32) -> IO (Either Result ())
printCancel h jid = do
  r <- primIO (prim__printCancel (handlePtr h) jid)
  pure (resultFromCode r)

||| Query job status.  Returns the JobStatus integer code, or 0xFF on error.
export
%foreign "C:presswerk_job_status, libpresswerk"
prim__jobStatus : Bits64 -> Bits32 -> PrimIO Bits32

export
jobStatus : Handle -> (jobId : Bits32) -> IO (Maybe JobStatus)
jobStatus h jid = do
  code <- primIO (prim__jobStatus (handlePtr h) jid)
  pure (jobStatusFromCode code)

--------------------------------------------------------------------------------
-- Discovery
--------------------------------------------------------------------------------

||| Start mDNS printer discovery.
export
%foreign "C:presswerk_discovery_start, libpresswerk"
prim__discoveryStart : Bits64 -> PrimIO Bits32

export
discoveryStart : Handle -> IO (Either Result ())
discoveryStart h = do
  r <- primIO (prim__discoveryStart (handlePtr h))
  pure (resultFromCode r)

||| Stop mDNS printer discovery.
export
%foreign "C:presswerk_discovery_stop, libpresswerk"
prim__discoveryStop : Bits64 -> PrimIO Bits32

export
discoveryStop : Handle -> IO (Either Result ())
discoveryStop h = do
  r <- primIO (prim__discoveryStop (handlePtr h))
  pure (resultFromCode r)

||| Get the number of currently discovered printers.
export
%foreign "C:presswerk_discovery_count, libpresswerk"
prim__discoveryCount : Bits64 -> PrimIO Bits32

export
discoveryCount : Handle -> IO Nat
discoveryCount h = do
  n <- primIO (prim__discoveryCount (handlePtr h))
  pure (cast n)

--------------------------------------------------------------------------------
-- IPP Server
--------------------------------------------------------------------------------

||| Start the embedded IPP print server on the configured port.
export
%foreign "C:presswerk_server_start, libpresswerk"
prim__serverStart : Bits64 -> Bits16 -> PrimIO Bits32

export
serverStart : Handle -> (port : Bits16) -> IO (Either Result ())
serverStart h port = do
  r <- primIO (prim__serverStart (handlePtr h) port)
  pure (resultFromCode r)

||| Stop the embedded IPP print server.
export
%foreign "C:presswerk_server_stop, libpresswerk"
prim__serverStop : Bits64 -> PrimIO Bits32

export
serverStop : Handle -> IO (Either Result ())
serverStop h = do
  r <- primIO (prim__serverStop (handlePtr h))
  pure (resultFromCode r)

--------------------------------------------------------------------------------
-- Audit Trail
--------------------------------------------------------------------------------

||| Record an audit entry.
export
%foreign "C:presswerk_audit_record, libpresswerk"
prim__auditRecord : Bits64 -> Bits64 -> Bits64 -> Bits32 -> Bits64 -> PrimIO Bits32

export
auditRecord : Handle -> (actionPtr : Bits64) -> (hashPtr : Bits64)
            -> (success : Bool) -> (detailsPtr : Bits64)
            -> IO (Either Result ())
auditRecord h action hash success details = do
  let s : Bits32 = if success then 1 else 0
  r <- primIO (prim__auditRecord (handlePtr h) action hash s details)
  pure (resultFromCode r)

||| Get the total number of audit entries.
export
%foreign "C:presswerk_audit_count, libpresswerk"
prim__auditCount : Bits64 -> PrimIO Bits64

export
auditCount : Handle -> IO Nat
auditCount h = do
  n <- primIO (prim__auditCount (handlePtr h))
  pure (cast n)

--------------------------------------------------------------------------------
-- Document Hashing
--------------------------------------------------------------------------------

||| Compute SHA-256 hash of a buffer.  Writes 32 bytes to output_ptr.
export
%foreign "C:presswerk_hash_sha256, libpresswerk"
prim__hashSha256 : Bits64 -> Bits32 -> Bits64 -> PrimIO Bits32

export
hashSha256 : (inputPtr : Bits64) -> (inputLen : Bits32)
           -> (outputPtr : Bits64) -> IO (Either Result ())
hashSha256 inp len out = do
  r <- primIO (prim__hashSha256 inp len out)
  pure (resultFromCode r)

--------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------

||| Retrieve the last error message (pointer to static string).
export
%foreign "C:presswerk_last_error, libpresswerk"
prim__lastError : PrimIO Bits64

export
lastError : IO (Maybe String)
lastError = do
  ptr <- primIO prim__lastError
  if ptr == 0
    then pure Nothing
    else pure (Just (prim__getString ptr))

||| Human-readable description for a result code.
export
errorDescription : Result -> String
errorDescription Ok           = "Success"
errorDescription Error        = "Generic error"
errorDescription InvalidParam = "Invalid parameter"
errorDescription OutOfMemory  = "Out of memory"
errorDescription NullPointer  = "Null pointer"
errorDescription Unsupported  = "Operation not supported on this platform"

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

||| Convert a C result code to a Result ADT.
resultFromCode : Bits32 -> Either Result ()
resultFromCode 0 = Right ()
resultFromCode 1 = Left Error
resultFromCode 2 = Left InvalidParam
resultFromCode 3 = Left OutOfMemory
resultFromCode 4 = Left NullPointer
resultFromCode 5 = Left Unsupported
resultFromCode _ = Left Error

||| Convert a C integer to a JobStatus.
jobStatusFromCode : Bits32 -> Maybe JobStatus
jobStatusFromCode 0 = Just Pending
jobStatusFromCode 1 = Just Processing
jobStatusFromCode 2 = Just Completed
jobStatusFromCode 3 = Just Failed
jobStatusFromCode 4 = Just Cancelled
jobStatusFromCode 5 = Just Held
jobStatusFromCode _ = Nothing
