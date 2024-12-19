;; Supply Chain Contract

(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))

(define-map supply-chain-participants
  principal
  {
    name: (string-utf8 100),
    role: (string-ascii 20),
    verified: bool
  }
)

(define-public (register-participant (name (string-utf8 100)) (role (string-ascii 20)))
  (let
    ((participant-data { name: name, role: role, verified: false }))
    (ok (map-set supply-chain-participants tx-sender participant-data))
  )
)

(define-public (verify-participant (participant principal))
  (let
    ((participant-data (unwrap! (map-get? supply-chain-participants participant) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender contract-caller) ERR_UNAUTHORIZED)
    (ok (map-set supply-chain-participants
      participant
      (merge participant-data { verified: true })
    ))
  )
)

(define-read-only (get-participant-info (participant principal))
  (ok (unwrap! (map-get? supply-chain-participants participant) ERR_NOT_FOUND))
)

(define-read-only (is-verified-participant (participant principal))
  (ok (default-to false (get verified (map-get? supply-chain-participants participant))))
)

;; This function would be called to record each step in the supply chain
(define-public (record-supply-chain-step (drug-id uint) (step (string-ascii 20)))
  (let
    ((participant-data (unwrap! (map-get? supply-chain-participants tx-sender) ERR_NOT_FOUND)))
    (asserts! (get verified participant-data) ERR_UNAUTHORIZED)
    (ok true)
  )
)

