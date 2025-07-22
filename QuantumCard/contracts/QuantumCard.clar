;; QuantumCards Digital Trading Platform

;; Error definitions
(define-constant err-unauth (err u100))
(define-constant err-not-owner (err u101))
(define-constant err-no-auction (err u102))
(define-constant err-bid-low (err u103))
(define-constant err-card-missing (err u104))
(define-constant err-bad-data (err u105))
(define-constant err-commission-high (err u106))
(define-constant err-invalid-principal (err u107))

;; NFT declaration
(define-non-fungible-token qc-token uint)

;; State
(define-data-var admin principal tx-sender)
(define-data-var next-id uint u1)

;; Storage
(define-map vault
  { id: uint }
  { owner: principal, minter: principal, design: (string-ascii 256), fee: uint })

(define-map floor
  { id: uint }
  { amount: uint, host: principal })

;; Permission check
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Validate principal (check if it's not a zero address equivalent)
(define-private (is-valid-principal (principal-to-check principal))
  (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78)))

;; Assign new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-unauth)
    (asserts! (is-valid-principal new-admin) err-invalid-principal)
    (ok (var-set admin new-admin))
  ))

;; View admin
(define-read-only (get-admin)
  (ok (var-get admin)))

;; Mint card
(define-public (mint (design (string-ascii 256)) (fee uint))
  (let ((id (var-get next-id)))
    (asserts! (> (len design) u0) err-bad-data)
    (asserts! (<= fee u1000) err-commission-high)
    (try! (nft-mint? qc-token id tx-sender))
    (map-set vault
      { id: id }
      { owner: tx-sender, minter: tx-sender, design: design, fee: fee }
    )
    (var-set next-id (+ id u1))
    (ok id)
  ))

;; Start auction
(define-public (start-auction (id uint) (amount uint))
  (let ((owner (unwrap! (nft-get-owner? qc-token id) err-card-missing)))
    (asserts! (> amount u0) err-bid-low)
    (asserts! (is-eq tx-sender owner) err-not-owner)
    (map-set floor
      { id: id }
      { amount: amount, host: tx-sender }
    )
    (ok true)
  ))

;; Cancel auction
(define-public (cancel-auction (id uint))
  (let ((auction (unwrap! (map-get? floor { id: id }) err-no-auction)))
    (asserts! (< id (var-get next-id)) err-card-missing)
    (asserts! (is-eq tx-sender (get host auction)) err-not-owner)
    (map-delete floor { id: id })
    (ok true)
  ))

;; Purchase card
(define-public (buy (id uint))
  (let
    (
      (auction (unwrap! (map-get? floor { id: id }) err-no-auction))
      (price (get amount auction))
      (host (get host auction))
      (card (unwrap! (map-get? vault { id: id }) err-card-missing))
      (creator (get minter card))
      (fee (get fee card))
      (royalty (/ (* price fee) u10000))
      (seller-amt (- price royalty))
    )
    (asserts! (< id (var-get next-id)) err-card-missing)
    (try! (stx-transfer? royalty tx-sender creator))
    (try! (stx-transfer? seller-amt tx-sender host))
    (try! (nft-transfer? qc-token id host tx-sender))
    (map-set vault
      { id: id }
      (merge card { owner: tx-sender })
    )
    (map-delete floor { id: id })
    (ok true)
  ))

;; View card
(define-read-only (view (id uint))
  (ok (unwrap! (map-get? vault { id: id }) err-card-missing)))

;; View auction
(define-read-only (view-auction (id uint))
  (ok (unwrap! (map-get? floor { id: id }) err-no-auction)))
