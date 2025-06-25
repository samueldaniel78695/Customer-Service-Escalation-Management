;; Process Improvement Contract
;; Tracks and implements process improvements

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INVALID_IMPROVEMENT (err u501))

;; Data maps
(define-map improvements uint {
    title: (string-ascii 100),
    description: (string-ascii 300),
    proposed-by: principal,
    impact-score: uint,
    implementation-cost: uint,
    status: (string-ascii 20),
    created-at: uint,
    implemented-at: (optional uint)
})

(define-map improvement-votes uint (list 10 principal))
(define-data-var next-improvement-id uint u1)

;; Read-only functions
(define-read-only (get-improvement (improvement-id uint))
    (map-get? improvements improvement-id)
)

(define-read-only (get-improvement-votes (improvement-id uint))
    (default-to (list) (map-get? improvement-votes improvement-id))
)

;; Public functions
(define-public (propose-improvement (title (string-ascii 100)) (description (string-ascii 300)) (impact-score uint) (cost uint))
    (let ((improvement-id (var-get next-improvement-id)))
        (map-set improvements improvement-id {
            title: title,
            description: description,
            proposed-by: tx-sender,
            impact-score: impact-score,
            implementation-cost: cost,
            status: "proposed",
            created-at: block-height,
            implemented-at: none
        })
        (var-set next-improvement-id (+ improvement-id u1))
        (ok improvement-id)
    )
)

(define-public (vote-for-improvement (improvement-id uint))
    (let ((current-votes (get-improvement-votes improvement-id)))
        (asserts! (is-none (index-of current-votes tx-sender)) (err u502))
        (map-set improvement-votes improvement-id
            (unwrap! (as-max-len? (append current-votes tx-sender) u10) (err u503)))
        (ok true)
    )
)

(define-public (implement-improvement (improvement-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (match (map-get? improvements improvement-id)
            improvement (begin
                (map-set improvements improvement-id (merge improvement {
                    status: "implemented",
                    implemented-at: (some block-height)
                }))
                (ok true)
            )
            ERR_INVALID_IMPROVEMENT
        )
    )
)

(define-public (reject-improvement (improvement-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (match (map-get? improvements improvement-id)
            improvement (begin
                (map-set improvements improvement-id (merge improvement {
                    status: "rejected"
                }))
                (ok true)
            )
            ERR_INVALID_IMPROVEMENT
        )
    )
)
