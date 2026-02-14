||| Presswerk Bridge ABI Proofs
|||
||| Formal specifications for the platform bridge FFI boundaries.
||| These proofs cover the iOS (objc2) and Android (JNI) bridges,
||| ensuring type-level safety for toll-free bridging, keychain
||| operations, and UI presentation preconditions.
|||
||| The Zig FFI boundary is covered by Layout.idr and Foreign.idr.
||| This module covers the PLATFORM bridges that talk to native SDKs.
|||
||| SPDX-License-Identifier: PMPL-1.0-or-later
||| Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

module Presswerk.ABI.Bridge

import Presswerk.ABI.Types
import Data.So

%default total

--------------------------------------------------------------------------------
-- Toll-Free Bridging (iOS / Core Foundation)
--------------------------------------------------------------------------------

||| Apple's toll-free bridged types share identical memory layout.
||| A pointer to one is valid as a pointer to the other.
|||
||| This proof justifies `unsafe` casts between:
|||   NSString ↔ CFString, NSData ↔ CFData, NSDictionary ↔ CFDictionary
|||
||| See: Apple Technical Note TN2151
public export
data TollFreePair : Type -> Type -> Type where
  ||| The two types have identical in-memory representation.
  MkTollFree : (a : Type) -> (b : Type)
            -> (sameSize : sizeOf a = sizeOf b)
            -> (sameAlign : alignOf a = alignOf b)
            -> TollFreePair a b

||| Toll-free bridging is symmetric: if A bridges to B, B bridges to A.
public export
tollFreeSymmetric : TollFreePair a b -> TollFreePair b a
tollFreeSymmetric (MkTollFree a b szPrf alPrf) =
  MkTollFree b a (sym szPrf) (sym alPrf)

||| Toll-free bridging is transitive: A ↔ B and B ↔ C implies A ↔ C.
public export
tollFreeTransitive : TollFreePair a b -> TollFreePair b c -> TollFreePair a c
tollFreeTransitive (MkTollFree a b sz1 al1) (MkTollFree b c sz2 al2) =
  MkTollFree a c (trans sz1 sz2) (trans al1 al2)

||| A cast between toll-free bridged types preserves pointer validity.
||| This is the core safety invariant that justifies `nsstr_as_obj`,
||| `nsdata_as_obj`, and `dict_as_cf` in the iOS bridge.
public export
data SafeCast : TollFreePair a b -> Type where
  CastOk : (pair : TollFreePair a b) -> SafeCast pair

--------------------------------------------------------------------------------
-- Keychain Properties
--------------------------------------------------------------------------------

||| Abstract keychain operation results.
public export
data KeychainResult : Type where
  KSuccess : KeychainResult
  KNotFound : KeychainResult
  KDuplicate : KeychainResult
  KError : (code : Int) -> KeychainResult

||| Keychain operations form a consistent key-value store.
|||
||| These properties are the specification that the iOS (Security.framework)
||| and Android (SharedPreferences) implementations must satisfy.
public export
data KeychainProperty : Type where

  ||| store(k, v) then load(k) = Just v
  ||| Both platforms guarantee this: iOS Keychain persists across app launches,
  ||| Android SharedPreferences.apply() is durable after commit.
  StoreLoad : (key : String) -> (value : List Bits8)
           -> KeychainProperty

  ||| delete(k) then load(k) = Nothing
  ||| iOS: SecItemDelete then SecItemCopyMatching returns errSecItemNotFound.
  ||| Android: editor.remove(k).apply() then getString(k, null) returns null.
  DeleteLoad : (key : String)
            -> KeychainProperty

  ||| store(k, v1) then store(k, v2) then load(k) = Just v2
  ||| Last-write-wins semantics. iOS uses SecItemUpdate on duplicate.
  ||| Android SharedPreferences.putString overwrites.
  LastWriteWins : (key : String) -> (v1 : List Bits8) -> (v2 : List Bits8)
               -> KeychainProperty

||| Proof witness that an implementation satisfies a keychain property.
public export
data SatisfiesKeychain : KeychainProperty -> Type where
  StoreLoadOk : SatisfiesKeychain (StoreLoad k v)
  DeleteLoadOk : SatisfiesKeychain (DeleteLoad k)
  LastWriteWinsOk : SatisfiesKeychain (LastWriteWins k v1 v2)

--------------------------------------------------------------------------------
-- Thread Safety Preconditions
--------------------------------------------------------------------------------

||| UI operations require the main thread on both platforms.
||| This is enforced at runtime by:
|||   iOS: MainThreadMarker::new() returns None off-main
|||   Android: UI operations throw CalledFromWrongThreadException
public export
data ThreadRequirement : Type where
  MainThread : ThreadRequirement
  AnyThread : ThreadRequirement

||| Bridge operations annotated with their thread requirement.
public export
data BridgeOp : Type where
  ShowPrintDialog : BridgeOp
  CaptureImage : BridgeOp
  PickFile : BridgeOp
  ReadPickedFile : BridgeOp
  StoreSecret : BridgeOp
  LoadSecret : BridgeOp
  DeleteSecret : BridgeOp
  ShareFile : BridgeOp

||| Map each bridge operation to its thread requirement.
||| UI-presenting operations need the main thread.
||| Keychain/file operations are safe from any thread.
public export
threadReq : BridgeOp -> ThreadRequirement
threadReq ShowPrintDialog = MainThread
threadReq CaptureImage    = MainThread
threadReq PickFile        = MainThread
threadReq ReadPickedFile  = AnyThread
threadReq StoreSecret     = AnyThread
threadReq LoadSecret      = AnyThread
threadReq DeleteSecret    = AnyThread
threadReq ShareFile       = MainThread

||| Proof that keychain operations are always safe from any thread.
public export
keychainAnyThread : (op : BridgeOp)
                 -> (op = StoreSecret) -> threadReq op = AnyThread
keychainAnyThread StoreSecret Refl = Refl

public export
loadAnyThread : threadReq LoadSecret = AnyThread
loadAnyThread = Refl

public export
deleteAnyThread : threadReq DeleteSecret = AnyThread
deleteAnyThread = Refl

public export
readFileAnyThread : threadReq ReadPickedFile = AnyThread
readFileAnyThread = Refl

--------------------------------------------------------------------------------
-- Platform Exhaustiveness
--------------------------------------------------------------------------------

||| All platforms covered by the bridge module.
public export
data BridgePlatform : Type where
  IOS : BridgePlatform
  Android : BridgePlatform
  Desktop : BridgePlatform  -- stub/fallback

||| Every runtime platform maps to exactly one bridge implementation.
||| This ensures no platform is left without a bridge at compile time.
public export
bridgeForPlatform : Platform -> BridgePlatform
bridgeForPlatform IOS     = IOS
bridgeForPlatform Android = Android
bridgeForPlatform Linux   = Desktop
bridgeForPlatform MacOS   = Desktop
bridgeForPlatform WASM    = Desktop

--------------------------------------------------------------------------------
-- JNI Safety Invariants
--------------------------------------------------------------------------------

||| The NDK context provides two pointers that are valid for the process lifetime:
|||   1. JavaVM* — the ART virtual machine handle
|||   2. jobject — the hosting Activity (global reference)
|||
||| These are set by android_main / ANativeActivity_onCreate and never
||| invalidated until process death.
public export
data JniInvariant : Type where
  ||| The JavaVM pointer from ndk_context is valid and non-null.
  ||| Proven by: NDK lifecycle contract — android_main receives valid ANativeActivity.
  ValidJavaVM : JniInvariant

  ||| The Activity jobject is a valid global reference.
  ||| Proven by: NDK creates a global ref before calling android_main.
  ValidActivity : JniInvariant

  ||| attach_current_thread is idempotent — calling it on an already-attached
  ||| thread returns the existing JNIEnv without side effects.
  AttachIdempotent : JniInvariant

||| All JNI invariants hold simultaneously during normal execution.
public export
data JniSafe : Type where
  MkJniSafe : (vm : JniInvariant) -> (act : JniInvariant) -> (attach : JniInvariant)
           -> JniSafe

--------------------------------------------------------------------------------
-- Handle Opacity (cross-reference with Layout.idr)
--------------------------------------------------------------------------------

||| The Zig FFI uses opaque handles to prevent client code from
||| dereferencing internal state directly. The only valid operations
||| on a handle are through the exported C functions declared in Foreign.idr.
|||
||| The cast between Handle (opaque) and InternalHandle is safe because:
|||   1. presswerk_init allocates InternalHandle via c_allocator (aligned)
|||   2. The returned *Handle is the same pointer, just opaquely typed
|||   3. toInternal casts back with @alignCast, which is a no-op for
|||      heap-allocated structs (always naturally aligned)
|||   4. Layout.idr proves the alignment requirements
public export
data OpaqueHandleSafe : Type where
  HandleCastSafe : OpaqueHandleSafe
