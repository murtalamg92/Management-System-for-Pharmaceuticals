;; Drug NFT Contract

(define-non-fungible-token drug-unit uint)

(define-constant contract-owner tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-data-var drug-id-nonce uint u0)

(define-map drug-units
  uint
  {
    manufacturer: principal,
    drug-name: (string-ascii 50),
    batch-number: (string-ascii 20),
    manufacture-date: uint,
    expiry-date: uint,
    current-owner: principal,
    current-stage: (string-ascii 20)
  }
)

(define-public (manufacture-drug
    (drug-name (string-ascii 50))
    (batch-number (string-ascii 20))
    (manufacture-date uint)
    (expiry-date uint))
  (let
    ((drug-id (+ (var-get drug-id-nonce) u1)))
    (asserts! (is-eq tx-sender contract-owner) ERR_UNAUTHORIZED)
    (try! (nft-mint? drug-unit drug-id tx-sender))
    (map-set drug-units
      drug-id
      {
        manufacturer: tx-sender,
        drug-name: drug-name,
        batch-number: batch-number,
        manufacture-date: manufacture-date,
        expiry-date: expiry-date,
        current-owner: tx-sender,
        current-stage: "manufactured"
      }
    )
    (var-set drug-id-nonce drug-id)
    (ok drug-id)
  )
)

(define-public (transfer-drug (drug-id uint) (recipient principal))
  (let
    ((drug-owner (unwrap! (nft-get-owner? drug-unit drug-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender drug-owner) ERR_UNAUTHORIZED)
    (try! (nft-transfer? drug-unit drug-id tx-sender recipient))
    (ok (map-set drug-units
      drug-id
      (merge (unwrap! (map-get? drug-units drug-id) ERR_NOT_FOUND)
             { current-owner: recipient })
    ))
  )
)

(define-public (update-drug-stage (drug-id uint) (new-stage (string-ascii 20)))
  (let
    ((drug-data (unwrap! (map-get? drug-units drug-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get current-owner drug-data)) ERR_UNAUTHORIZED)
    (ok (map-set drug-units
      drug-id
      (merge drug-data { current-stage: new-stage })
    ))
  )
)

(define-read-only (get-drug-info (drug-id uint))
  (ok (unwrap! (map-get? drug-units drug-id) ERR_NOT_FOUND))
)

(define-read-only (verify-drug (drug-id uint))
  (let
    ((drug-data (unwrap! (map-get? drug-units drug-id) ERR_NOT_FOUND)))
    (ok {
      is-authentic: (is-some (nft-get-owner? drug-unit drug-id)),
      manufacturer: (get manufacturer drug-data),
      drug-name: (get drug-name drug-data),
      batch-number: (get batch-number drug-data),
      manufacture-date: (get manufacture-date drug-data),
      expiry-date: (get expiry-date drug-data),
      current-owner: (get current-owner drug-data),
      current-stage: (get current-stage drug-data)
    })
  )
)

