;; Evolution Protocol Contract
;; Manages quantum identity evolution processes

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-unauthorized (err u203))
(define-constant err-invalid-state (err u204))

;; Evolution states
(define-constant state-initiated u1)
(define-constant state-in-progress u2)
(define-constant state-completed u3)
(define-constant state-failed u4)

;; Data structures
(define-map evolution-sessions uint {
  participant: principal,
  facilitator: principal,
  evolution-type: (string-ascii 50),
  state: uint,
  start-block: uint,
  end-block: (optional uint),
  quantum-signature: (buff 32),
  transformation-data: (string-ascii 500)
})

(define-map participant-evolutions principal (list 50 uint))
(define-data-var session-counter uint u0)

;; Public functions
(define-public (initiate-evolution
  (participant principal)
  (facilitator principal)
  (evolution-type (string-ascii 50))
  (quantum-signature (buff 32)))
  (let ((session-id (+ (var-get session-counter) u1)))
    (asserts! (is-eq tx-sender participant) err-unauthorized)
    (var-set session-counter session-id)
    (map-set evolution-sessions session-id {
      participant: participant,
      facilitator: facilitator,
      evolution-type: evolution-type,
      state: state-initiated,
      start-block: block-height,
      end-block: none,
      quantum-signature: quantum-signature,
      transformation-data: ""
    })
    (map-set participant-evolutions participant
      (unwrap-panic (as-max-len?
        (append (default-to (list) (map-get? participant-evolutions participant)) session-id)
        u50)))
    (ok session-id)
  )
)

(define-public (start-evolution (session-id uint))
  (let ((session (unwrap! (map-get? evolution-sessions session-id) err-not-found)))
    (asserts! (is-eq tx-sender (get facilitator session)) err-unauthorized)
    (asserts! (is-eq (get state session) state-initiated) err-invalid-state)
    (map-set evolution-sessions session-id
      (merge session { state: state-in-progress }))
    (ok true)
  )
)

(define-public (complete-evolution (session-id uint) (transformation-data (string-ascii 500)))
  (let ((session (unwrap! (map-get? evolution-sessions session-id) err-not-found)))
    (asserts! (is-eq tx-sender (get facilitator session)) err-unauthorized)
    (asserts! (is-eq (get state session) state-in-progress) err-invalid-state)
    (map-set evolution-sessions session-id
      (merge session {
        state: state-completed,
        end-block: (some block-height),
        transformation-data: transformation-data
      }))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-evolution-session (session-id uint))
  (map-get? evolution-sessions session-id)
)

(define-read-only (get-participant-evolutions (participant principal))
  (map-get? participant-evolutions participant)
)

(define-read-only (get-session-count)
  (var-get session-counter)
)
