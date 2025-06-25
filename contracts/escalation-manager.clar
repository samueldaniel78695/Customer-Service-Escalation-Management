;; Escalation Manager Verification Contract
;; Manages and verifies customer service escalation managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_MANAGER (err u101))
(define-constant ERR_NOT_MANAGER (err u102))

;; Data maps
(define-map escalation-managers principal bool)
(define-map manager-details principal {
    name: (string-ascii 50),
    department: (string-ascii 30),
    level: uint,
    active: bool
})

;; Read-only functions
(define-read-only (is-escalation-manager (manager principal))
    (default-to false (map-get? escalation-managers manager))
)

(define-read-only (get-manager-details (manager principal))
    (map-get? manager-details manager)
)

;; Public functions
(define-public (add-escalation-manager (manager principal) (name (string-ascii 50)) (department (string-ascii 30)) (level uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-escalation-manager manager)) ERR_ALREADY_MANAGER)
        (map-set escalation-managers manager true)
        (map-set manager-details manager {
            name: name,
            department: department,
            level: level,
            active: true
        })
        (ok true)
    )
)

(define-public (remove-escalation-manager (manager principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-escalation-manager manager) ERR_NOT_MANAGER)
        (map-delete escalation-managers manager)
        (map-delete manager-details manager)
        (ok true)
    )
)

(define-public (update-manager-status (manager principal) (active bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-escalation-manager manager) ERR_NOT_MANAGER)
        (match (map-get? manager-details manager)
            details (begin
                (map-set manager-details manager (merge details { active: active }))
                (ok true)
            )
            ERR_NOT_MANAGER
        )
    )
)
