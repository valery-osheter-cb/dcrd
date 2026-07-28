// Copyright (c) 2026 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

//go:build arm64 && !purego

package secp256k1

//go:noescape
func field64Mul(r *[4]uint64, a, b *[4]uint64)

//go:noescape
func field64Square(r *[4]uint64, a *[4]uint64)
