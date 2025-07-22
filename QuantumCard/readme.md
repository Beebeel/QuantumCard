# QuantumCards Digital Trading Platform

A decentralized NFT marketplace built on the Stacks blockchain for trading digital cards with built-in royalty mechanisms and auction functionality.

## Overview

QuantumCards enables users to mint, trade, and auction digital trading cards as NFTs. The platform features automatic royalty distribution to original creators and secure peer-to-peer transactions.

## Smart Contract Features

### Core Functionality
- **NFT Minting**: Create unique digital trading cards
- **Auction System**: List cards for sale with custom pricing
- **Royalty Distribution**: Automatic payment to original creators
- **Admin Management**: Controlled governance system
- **Secure Transfers**: Built-in ownership verification

### Contract Components

#### NFT Token
```clarity
(define-non-fungible-token qc-token uint)
```
- Unique identifier for each digital card
- Standard NFT functionality with ownership tracking

#### State Variables
- `admin`: Contract administrator principal
- `next-id`: Sequential card ID counter starting from 1

#### Data Storage

**Vault Map** - Card Registry
```clarity
(define-map vault
  { id: uint }
  { owner: principal, minter: principal, design: (string-ascii 256), fee: uint })
```
- `id`: Unique card identifier
- `owner`: Current card owner
- `minter`: Original creator
- `design`: Card metadata/design information
- `fee`: Royalty percentage (basis points, max 1000 = 10%)

**Floor Map** - Auction Listings
```clarity
(define-map floor
  { id: uint }
  { amount: uint, host: principal })
```
- `id`: Card identifier
- `amount`: Asking price in microSTX
- `host`: Seller principal

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-unauth` | Unauthorized access attempt |
| u101 | `err-not-owner` | Not card owner |
| u102 | `err-no-auction` | Auction doesn't exist |
| u103 | `err-bid-low` | Price must be greater than 0 |
| u104 | `err-card-missing` | Card doesn't exist |
| u105 | `err-bad-data` | Invalid metadata |
| u106 | `err-commission-high` | Royalty fee exceeds 10% |
| u107 | `err-invalid-principal` | Invalid principal address |

## Public Functions

### Administrative Functions

#### `set-admin(new-admin: principal)`
Transfer administrative privileges to a new principal.
- **Access**: Admin only
- **Returns**: `(response bool uint)`
- **Validations**: 
  - Caller must be current admin
  - New admin cannot be zero address

#### `get-admin()`
View current contract administrator.
- **Access**: Public read-only
- **Returns**: `(response principal uint)`

### Card Management

#### `mint(design: string-ascii-256, fee: uint)`
Create a new digital trading card.
- **Parameters**:
  - `design`: Card metadata/design (max 256 ASCII characters)
  - `fee`: Royalty percentage in basis points (0-1000)
- **Returns**: `(response uint uint)` - Card ID if successful
- **Validations**:
  - Design string must not be empty
  - Fee cannot exceed 1000 basis points (10%)

#### `view(id: uint)`
Retrieve card information.
- **Parameters**: `id` - Card identifier
- **Returns**: Card data including owner, minter, design, and fee
- **Access**: Public read-only

### Auction System

#### `start-auction(id: uint, amount: uint)`
List a card for sale at specified price.
- **Parameters**:
  - `id`: Card identifier
  - `amount`: Asking price in microSTX
- **Access**: Card owner only
- **Validations**:
  - Caller must own the card
  - Amount must be greater than 0

#### `cancel-auction(id: uint)`
Remove card from auction listings.
- **Parameters**: `id` - Card identifier
- **Access**: Auction host (seller) only
- **Validations**:
  - Auction must exist
  - Caller must be the seller

#### `view-auction(id: uint)`
View active auction details.
- **Parameters**: `id` - Card identifier
- **Returns**: Auction data including price and seller
- **Access**: Public read-only

### Trading

#### `buy(id: uint)`
Purchase a card from an active auction.
- **Parameters**: `id` - Card identifier
- **Process**:
  1. Validates auction exists and card is valid
  2. Calculates royalty payment to original creator
  3. Transfers remaining amount to seller
  4. Transfers card ownership to buyer
  5. Updates vault records
  6. Removes auction listing
- **Payments**:
  - Royalty to original minter: `(price * fee) / 10000`
  - Remainder to seller: `price - royalty`

## Usage Examples

### Minting a Card
```clarity
;; Mint a card with 5% royalty (500 basis points)
(contract-call? .quantum-cards mint "Dragon Warrior v1.0" u500)
;; Returns: (ok u1) - Card ID 1
```

### Starting an Auction
```clarity
;; List card #1 for 1000000 microSTX (1 STX)
(contract-call? .quantum-cards start-auction u1 u1000000)
;; Returns: (ok true)
```

### Purchasing a Card
```clarity
;; Buy card #1 from auction
(contract-call? .quantum-cards buy u1)
;; Automatically handles payments and ownership transfer
```

## Security Features

1. **Ownership Verification**: All functions verify caller permissions
2. **Principal Validation**: Prevents zero-address assignments
3. **Royalty Caps**: Maximum 10% royalty protection
4. **Atomic Transactions**: All transfers occur together or fail completely
5. **Input Validation**: Comprehensive parameter checking

## Deployment Considerations

- Deploy with appropriate admin principal
- Test all functions on testnet before mainnet
- Verify error handling for edge cases
- Consider gas optimization for high-volume usage

## Integration

The contract follows standard Stacks NFT patterns and can integrate with:
- NFT marketplace frontends
- Wallet applications
- Trading analytics platforms
- Portfolio management tools

