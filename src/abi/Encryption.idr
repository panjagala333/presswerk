||| Presswerk ABI Encryption Invariants
|||
||| Formal properties of the encryption layer. These are axiomatised
||| (declared, not computed) since the actual crypto runs in Rust/Zig,
||| but they document the properties the implementation MUST satisfy.
|||
||| SPDX-License-Identifier: PMPL-1.0-or-later
||| Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

module Presswerk.ABI.Encryption

import Data.Vect

%default total

--------------------------------------------------------------------------------
-- Abstract Crypto Types
--------------------------------------------------------------------------------

||| An encryption key (abstract — actual representation in Rust/Zig)
public export
data Key : Type where
  EncKey : Key
  DecKey : Key

||| A pair of keys that belong to the same identity
public export
record KeyPair where
  constructor MkKeyPair
  encryptionKey : Key
  decryptionKey : Key

||| Plaintext bytes
public export
Plaintext : Type
Plaintext = List Bits8

||| Ciphertext bytes
public export
Ciphertext : Type
Ciphertext = List Bits8

--------------------------------------------------------------------------------
-- Encryption/Decryption (Axiomatised)
--------------------------------------------------------------------------------

||| Encrypt plaintext with a key (axiom — implemented in Rust via age crate)
public export
encrypt : Key -> Plaintext -> Ciphertext
encrypt _ _ = [] -- Axiom: actual implementation in Rust

||| Decrypt ciphertext with a key (axiom)
public export
decrypt : Key -> Ciphertext -> Maybe Plaintext
decrypt _ _ = Nothing -- Axiom: actual implementation in Rust

--------------------------------------------------------------------------------
-- Required Properties (Specification)
--------------------------------------------------------------------------------

||| Property 1: Decryption is the inverse of encryption.
||| For all keys k and plaintexts p:
|||   decrypt(k.dec, encrypt(k.enc, p)) = Just p
|||
||| This is stated as a type — any implementation must provide a proof term.
public export
0 RoundtripProperty : Type
RoundtripProperty =
  (kp : KeyPair) -> (p : Plaintext) ->
  decrypt (decryptionKey kp) (encrypt (encryptionKey kp) p) = Just p

||| Property 2: Ciphertext is non-empty when plaintext is non-empty.
||| encrypt(k, p) where p /= [] implies result /= []
public export
0 NonEmptyProperty : Type
NonEmptyProperty =
  (k : Key) -> (p : Plaintext) -> NonEmpty p ->
  NonEmpty (encrypt k p)

||| Property 3: Different keys produce different ciphertexts (probabilistic —
||| stated as a non-equality obligation).
public export
0 KeySeparation : Type
KeySeparation =
  (k1, k2 : Key) -> Not (k1 = k2) ->
  (p : Plaintext) -> NonEmpty p ->
  Not (encrypt k1 p = encrypt k2 p)

||| Property 4: Wrong key decryption fails.
||| Decrypting with a key that doesn't match the encryption key returns Nothing.
public export
0 WrongKeyFails : Type
WrongKeyFails =
  (kp1, kp2 : KeyPair) -> Not (kp1 = kp2) ->
  (p : Plaintext) -> NonEmpty p ->
  decrypt (decryptionKey kp2) (encrypt (encryptionKey kp1) p) = Nothing

--------------------------------------------------------------------------------
-- Hash Properties (SHA-256)
--------------------------------------------------------------------------------

||| SHA-256 hash output is always 32 bytes
public export
0 HashOutputSize : Type
HashOutputSize =
  (input : Plaintext) -> length (sha256 input) = 32
  where
    sha256 : Plaintext -> Vect 32 Bits8
    sha256 _ = replicate 32 0 -- Axiom

||| SHA-256 is deterministic
public export
0 HashDeterministic : Type
HashDeterministic =
  (a, b : Plaintext) -> a = b ->
  sha256 a = sha256 b
  where
    sha256 : Plaintext -> Vect 32 Bits8
    sha256 _ = replicate 32 0 -- Axiom
