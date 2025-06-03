;; Facilitator Verification Contract
;; Validates quantum identity evolution facilitators

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map facilitators principal {
  verified: bool,
  reputation-score: uint,
  specializations: (list 10 (string-ascii 50)),
  verification-date: uint,
  active: bool
})

(define-map facilitator-stats principal {
  total-sessions: uint,
  successful-transformations: uint,
  average-rating: uint
})

;; Public functions
(define-public (register-facilitator (facilitator principal) (specializations (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? facilitators facilitator)) err-already-exists)
    (map-set facilitators facilitator {
      verified: true,
      reputation-score: u100,
      specializations: specializations,
      verification-date: block-height,
      active: true
    })
    (map-set facilitator-stats facilitator {
      total-sessions: u0,
      successful-transformations: u0,
      average-rating: u0
    })
    (ok true)
  )
)

(define-public (update-facilitator-reputation (facilitator principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? facilitators facilitator)) err-not-found)
    (map-set facilitators facilitator
      (merge (unwrap-panic (map-get? facilitators facilitator))
             { reputation-score: new-score }))
    (ok true)
  )
)

(define-public (deactivate-facilitator (facilitator principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? facilitators facilitator)) err-not-found)
    (map-set facilitators facilitator
      (merge (unwrap-panic (map-get? facilitators facilitator))
             { active: false }))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-facilitator-info (facilitator principal))
  (map-get? facilitators facilitator)
)

(define-read-only (get-facilitator-stats (facilitator principal))
  (map-get? facilitator-stats facilitator)
)

(define-read-only (is-verified-facilitator (facilitator principal))
  (match (map-get? facilitators facilitator)
    facilitator-data (and (get verified facilitator-data) (get active facilitator-data))
    false
  )
)
