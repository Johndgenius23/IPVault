;; Intellectual Property Rights Management
;; Enables creators to register, manage, and monetize intellectual property rights
;; with transparent licensing, royalty distribution, and usage tracking

;; Define NFT trait locally instead of importing from an external contract
(define-trait token-trait
  (
    ;; Last token ID, limited to uint range
    (get-last-token-id () (response uint uint))
    ;; URI for metadata associated with the token
    (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
    ;; Owner of a specific token
    (get-owner (uint) (response (optional principal) uint))
    ;; Transfer token to a new principal
    (transfer (uint principal principal) (response bool uint))
  )
)

;; Intellectual property registrations
(define-map asset-records
  { asset-id: uint }
  {
    name: (string-utf8 256),
    summary: (string-utf8 1024),
    author: principal,
    timestamp: uint,
    asset-category: (string-ascii 32),     ;; "image", "music", "text", "code", "video", "design", etc.
    content-digest: (buff 64),        ;; Hash of the IP content
    state: (string-ascii 16),      ;; "registered", "disputed", "revoked"
    token-contract: (optional principal),  ;; Optional NFT contract for this IP
    token-id: (optional uint),        ;; Optional NFT ID within the contract
    is-public: bool,            ;; Whether the work is in the public domain
    record-expiry: (optional uint)  ;; Optional block height when registration expires
  }
)

;; IP ownership shares (can be fractional)
(define-map asset-shares
  { asset-id: uint, holder: principal }
  {
    portion: uint,         ;; Out of 10000 (e.g., 5000 = 50%)
    obtained-at: uint,
    obtained-from: (optional principal)
  }
)

;; License templates
(define-map contract-templates
  { template-id: uint }
  {
    title: (string-utf8 64),
    summary: (string-utf8 1024),
    author: principal,
    timestamp: uint,
    permitted-actions: (list 10 (string-ascii 32)),  ;; e.g., "reproduce", "distribute", "derivative", "commercial"
    payment-model: (string-ascii 16),        ;; "one-time", "recurring", "usage-based", "free"
    base-rate: uint,                          ;; Default fee amount
    base-term: (optional uint),          ;; Default duration in blocks
    is-transferable: bool,                         ;; Whether license can be transferred
    allows-exclusivity: bool,                ;; Whether exclusive licenses are available
    has-territory-limits: bool,                 ;; Whether license can be territory-restricted
    legal-document: (string-utf8 256)             ;; URI to the full legal template
  }
)

;; Granted licenses
(define-map active-contracts
  { contract-id: uint }
  {
    asset-id: uint,          ;; The IP being licensed
    template-id: uint,              ;; The license template used
    rights-holder: principal,            ;; Entity granting the license
    rights-user: principal,            ;; Entity receiving the license
    issued-at: uint,
    terminates-at: (optional uint),
    payment-amount: uint,
    region: (optional (string-ascii 64)),
    is-exclusive: bool,
    is-valid: bool,
    usage-count: uint,            ;; Counter for usage-based licensing
    usage-limit: (optional uint),     ;; Max allowed usage
    special-terms: (optional (string-utf8 1024)),
    is-terminated: bool,
    termination-reason: (optional (string-utf8 256))
  }
)

;; Usage logs for IP
(define-map usage-records
  { asset-id: uint, entry-id: uint }
  {
    user: principal,
    contract-id: (optional uint),
    usage-category: (string-ascii 32),
    channel: (string-ascii 64),
    proof-hash: (buff 32),          ;; Hash of usage evidence
    timestamp: uint,
    income-generated: (optional uint),
    is-confirmed: bool,
    confirmer: (optional principal)
  }
)

;; Royalty recipients
(define-map payment-beneficiaries
  { asset-id: uint, beneficiary: principal }
  {
    allocation: uint,         ;; Out of 10000
    role: (string-ascii 16),  ;; "creator", "collaborator", "label", "publisher", etc.
    is-active: bool
  }
)

;; Royalty payments
(define-map revenue-transactions
  { transaction-id: uint }
  {
    asset-id: uint,
    contract-id: (optional uint),
    sender: principal,
    amount: uint,
    timestamp: uint,
    entry-id: (optional uint),
    transaction-type: (string-ascii 16),  ;; "license-fee", "royalty", "settlement"
    is-processed: bool
  }
)

;; Dispute records
(define-map legal-challenges
  { case-id: uint }
  {
    asset-id: uint,
    challenger: principal,
    filed-at: uint,
    claim-basis: (string-utf8 256),
    evidence-hash: (buff 32),
    status: (string-ascii 16),      ;; "pending", "resolved", "rejected", "withdrawn"
    resolution: (optional (string-utf8 256)),
    arbitrator: (optional principal),
    resolved-at: (optional uint)
  }
)

;; Derivative works
(define-map derived-assets
  { source-id: uint, derived-id: uint }
  {
    relation-type: (string-ascii 32),  ;; "adaptation", "translation", "remix", etc.
    is-approved: bool,
    approval-date: (optional uint),
    royalty-rate: uint        ;; How much goes back to original work
  }
)

;; Next available IDs
(define-data-var next-asset-id uint u0)
(define-data-var next-template-id uint u0)
(define-data-var next-contract-id uint u0)
(define-data-var next-case-id uint u0)
(define-data-var next-transaction-id uint u0)
(define-map next-entry-id { asset-id: uint } { id: uint })

;; Protocol configuration
(define-data-var arbitration-address principal tx-sender)
(define-data-var platform-fee-rate uint u250)  ;; 2.5% of transactions
(define-data-var dispute-filing-cost uint u1000000)   ;; 1 STX

;; Validation functions
(define-private (validate-asset-id (asset-id uint))
  (if (< asset-id (var-get next-asset-id))
      (ok asset-id)
      (err u"Invalid registration ID"))
)

(define-private (validate-utf8-256 (text (string-utf8 256)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-64 (text (string-utf8 64)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-1024 (text (string-utf8 1024)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-content-digest (content-digest (buff 64)))
  (if (> (len content-digest) u0)
      (ok content-digest)
      (err u"Content hash cannot be empty"))
)

(define-private (validate-template-id (template-id uint))
  (if (< template-id (var-get next-template-id))
      (ok template-id)
      (err u"Invalid template ID"))
)

(define-private (validate-contract-id (contract-id uint))
  (if (< contract-id (var-get next-contract-id))
      (ok contract-id)
      (err u"Invalid license ID"))
)

(define-private (validate-case-id (case-id uint))
  (if (< case-id (var-get next-case-id))
      (ok case-id)
      (err u"Invalid dispute ID"))
)

(define-private (validate-entry-id (asset-id uint) (entry-id uint))
  (match (map-get? next-entry-id { asset-id: asset-id })
    counter (if (< entry-id (get id counter))
               (ok entry-id)
               (err u"Invalid usage ID"))
    (err u"Registration ID not found"))
)

(define-private (validate-relation-type (relation-type (string-ascii 32)))
  (if (or (is-eq relation-type "adaptation")
          (or (is-eq relation-type "translation")
              (or (is-eq relation-type "remix")
                  (is-eq relation-type "derivative"))))
      (ok relation-type)
      (err u"Invalid relationship type"))
)

(define-private (validate-usage-category (usage-category (string-ascii 32)))
  (if (or (is-eq usage-category "online-display")
          (or (is-eq usage-category "broadcast")
              (or (is-eq usage-category "print")
                  (or (is-eq usage-category "merchandise")
                      (is-eq usage-category "performance")))))
      (ok usage-category)
      (err u"Invalid usage type"))
)

(define-private (validate-role (role (string-ascii 16)))
  (if (or (is-eq role "creator")
          (or (is-eq role "collaborator")
              (or (is-eq role "label")
                  (or (is-eq role "publisher")
                      (is-eq role "distributor")))))
      (ok role)
      (err u"Invalid recipient type"))
)

(define-private (validate-transaction-type (transaction-type (string-ascii 16)))
  (if (or (is-eq transaction-type "license-fee")
          (or (is-eq transaction-type "royalty")
              (is-eq transaction-type "settlement")))
      (ok transaction-type)
      (err u"Invalid payment type"))
)

;; Register new intellectual property
(define-public (register-ip
                (name (string-utf8 256))
                (summary (string-utf8 1024))
                (asset-category (string-ascii 32))
                (content-digest (buff 64))
                (is-public bool)
                (record-expiry (optional uint)))
  (let
    ((validated-name-resp (validate-utf8-256 name))
     (validated-summary-resp (validate-utf8-1024 summary))
     (validated-content-digest-resp (validate-content-digest content-digest))
     (asset-id (var-get next-asset-id)))
    
    ;; Validate parameters
    (asserts! (is-valid-asset-category asset-category) (err u"Invalid IP type"))
    (asserts! (is-ok validated-name-resp) (err (unwrap-err! validated-name-resp (err u"Title validation failed"))))
    (asserts! (is-ok validated-summary-resp) (err (unwrap-err! validated-summary-resp (err u"Description validation failed"))))
    (asserts! (is-ok validated-content-digest-resp) (err (unwrap-err! validated-content-digest-resp (err u"Content hash validation failed"))))
    
    ;; Create the registration
    (map-set asset-records
      { asset-id: asset-id }
      {
        name: (unwrap-panic validated-name-resp),
        summary: (unwrap-panic validated-summary-resp),
        author: tx-sender,
        timestamp: block-height,
        asset-category: asset-category,
        content-digest: (unwrap-panic validated-content-digest-resp),
        state: "registered",
        token-contract: none,
        token-id: none,
        is-public: is-public,
        record-expiry: record-expiry
      }
    )
    
    ;; Set initial ownership
    (map-set asset-shares
      { asset-id: asset-id, holder: tx-sender }
      {
        portion: u10000,     ;; 100%
        obtained-at: block-height,
        obtained-from: none
      }
    )
    
    ;; Initialize usage counter
    (map-set next-entry-id
      { asset-id: asset-id }
      { id: u0 }
    )
    
    ;; Increment registration ID counter
    (var-set next-asset-id (+ asset-id u1))
    
    (ok asset-id)
  )
)

;; Check if IP type is valid
(define-private (is-valid-asset-category (asset-category (string-ascii 32)))
  (or (is-eq asset-category "image")
      (or (is-eq asset-category "music")
          (or (is-eq asset-category "text")
              (or (is-eq asset-category "code")
                  (or (is-eq asset-category "video")
                      (is-eq asset-category "design"))))))
)

;; Link an NFT to an IP registration
(define-public (link-nft-to-ip
                (asset-id uint)
                (token-contract principal)
                (token-id uint))
  (let
    ((validated-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID is valid
    (asserts! (is-ok validated-id-resp) 
              (err (unwrap-err! validated-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-id (unwrap-panic validated-id-resp)))
      ;; Get the registration
      (let ((asset-record (unwrap! (map-get? asset-records { asset-id: validated-id }) 
                                  (err u"Registration not found"))))
        ;; Validate
        (asserts! (is-eq tx-sender (get author asset-record)) 
                  (err u"Only creator can link NFT"))
        (asserts! (is-eq (get state asset-record) "registered") 
                  (err u"Registration not in valid state"))
        
        ;; TODO: In a real implementation, verify NFT ownership
        
        ;; Update registration with NFT info
        (map-set asset-records
          { asset-id: validated-id }
          (merge asset-record 
            { 
              token-contract: (some token-contract),
              token-id: (some token-id)
            }
          )
        )
        
        (ok true)
      )
    )
  )
)

;; Create a license template
(define-public (create-license-template
                (title (string-utf8 64))
                (summary (string-utf8 1024))
                (permitted-actions (list 10 (string-ascii 32)))
                (payment-model (string-ascii 16))
                (base-rate uint)
                (base-term (optional uint))
                (is-transferable bool)
                (allows-exclusivity bool)
                (has-territory-limits bool)
                (legal-document (string-utf8 256)))
  (let
    ((validated-title-resp (validate-utf8-64 title))
     (validated-summary-resp (validate-utf8-1024 summary))
     (template-id (var-get next-template-id)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-title-resp) 
              (err (unwrap-err! validated-title-resp (err u"Name validation failed"))))
    (asserts! (is-ok validated-summary-resp) 
              (err (unwrap-err! validated-summary-resp (err u"Description validation failed"))))
    (asserts! (is-valid-payment-model payment-model) (err u"Invalid fee type"))
    (asserts! (> (len permitted-actions) u0) (err u"Must provide at least one usage right"))
    
    (let
      ((validated-title (unwrap-panic validated-title-resp))
       (validated-summary (unwrap-panic validated-summary-resp)))
      
      ;; Create the template
      (map-set contract-templates
        { template-id: template-id }
        {
          title: validated-title,
          summary: validated-summary,
          author: tx-sender,
          timestamp: block-height,
          permitted-actions: permitted-actions,
          payment-model: payment-model,
          base-rate: base-rate,
          base-term: base-term,
          is-transferable: is-transferable,
          allows-exclusivity: allows-exclusivity,
          has-territory-limits: has-territory-limits,
          legal-document: legal-document
        }
      )
      
      ;; Increment template ID counter
      (var-set next-template-id (+ template-id u1))
      
      (ok template-id)
    )
  )
)

;; Check if fee type is valid
(define-private (is-valid-payment-model (payment-model (string-ascii 16)))
  (or (is-eq payment-model "one-time")
      (or (is-eq payment-model "recurring")
          (or (is-eq payment-model "usage-based")
              (is-eq payment-model "free"))))
)

;; Grant a license to use IP - split into free and paid versions
;; This version is for free licenses (fee = 0)
(define-public (grant-free-license
                (asset-id uint)
                (template-id uint)
                (rights-user principal)
                (duration (optional uint))
                (region (optional (string-ascii 64)))
                (is-exclusive bool)
                (usage-limit (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-template-id-resp (validate-template-id template-id)))
    
    ;; Check validation results
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp) 
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((asset-record (unwrap! (map-get? asset-records { asset-id: validated-asset-id }) 
                                 (err u"Registration not found")))
            (template (unwrap! (map-get? contract-templates { template-id: validated-template-id }) 
                             (err u"Template not found")))
            (ownership (unwrap! (map-get? asset-shares 
                               { asset-id: validated-asset-id, holder: tx-sender })
                              (err u"Not an owner of this IP")))
            (contract-id (var-get next-contract-id)))
        
        ;; Validate
        (asserts! (is-eq (get state asset-record) "registered") 
                  (err u"Registration not in valid state"))
        (asserts! (not (get is-public asset-record)) 
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not is-exclusive) (get allows-exclusivity template)) 
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none region) (get has-territory-limits template)) 
                  (err u"Territory restrictions not available for this template"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get base-term template))))
          
          ;; Create the license grant
          (map-set active-contracts
            { contract-id: contract-id }
            {
              asset-id: validated-asset-id,
              template-id: validated-template-id,
              rights-holder: tx-sender,
              rights-user: rights-user,
              issued-at: block-height,
              terminates-at: expiry,
              payment-amount: u0,  ;; Free license
              region: region,
              is-exclusive: is-exclusive,
              is-valid: true,
              usage-count: u0,
              usage-limit: usage-limit,
              special-terms: special-terms,
              is-terminated: false,
              termination-reason: none
            }
          )
          
          ;; Increment license ID counter
          (var-set next-contract-id (+ contract-id u1))
          
          (ok contract-id)
        )
      )
    )
  )
)

;; Grant a license with payment
(define-public (grant-paid-license
                (asset-id uint)
                (template-id uint)
                (rights-user principal)
                (fee uint)  ;; Must be > 0
                (duration (optional uint))
                (region (optional (string-ascii 64)))
                (is-exclusive bool)
                (usage-limit (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-template-id-resp (validate-template-id template-id)))
    
    ;; Check validation results
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp) 
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((asset-record (unwrap! (map-get? asset-records { asset-id: validated-asset-id }) 
                                 (err u"Registration not found")))
            (template (unwrap! (map-get? contract-templates { template-id: validated-template-id }) 
                             (err u"Template not found")))
            (ownership (unwrap! (map-get? asset-shares 
                               { asset-id: validated-asset-id, holder: tx-sender })
                              (err u"Not an owner of this IP")))
            (contract-id (var-get next-contract-id))
            (platform-fee (/ (* fee (var-get platform-fee-rate)) u10000)))
        
        ;; Validate
        (asserts! (is-eq (get state asset-record) "registered") 
                  (err u"Registration not in valid state"))
        (asserts! (not (get is-public asset-record)) 
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not is-exclusive) (get allows-exclusivity template)) 
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none region) (get has-territory-limits template)) 
                  (err u"Territory restrictions not available for this template"))
        (asserts! (> fee u0) (err u"Fee must be greater than 0"))
        
        ;; Transfer fee from licensee
        (asserts! (is-ok (stx-transfer? fee rights-user (as-contract tx-sender))) 
                  (err u"License fee transfer failed"))
        
        ;; Transfer protocol fee
        (asserts! (is-ok (as-contract (stx-transfer? platform-fee tx-sender (var-get arbitration-address))))
                  (err u"Protocol fee transfer failed"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get base-term template))))
          
          ;; Create the license grant
          (map-set active-contracts
            { contract-id: contract-id }
            {
              asset-id: validated-asset-id,
              template-id: validated-template-id,
              rights-holder: tx-sender,
              rights-user: rights-user,
              issued-at: block-height,
              terminates-at: expiry,
              payment-amount: fee,
              region: region,
              is-exclusive: is-exclusive,
              is-valid: true,
              usage-count: u0,
              usage-limit: usage-limit,
              special-terms: special-terms,
              is-terminated: false,
              termination-reason: none
            }
          )
          
          ;; Record payment
          (let ((transaction-id (var-get next-transaction-id)))
            ;; Create payment record
            (map-set revenue-transactions
              { transaction-id: transaction-id }
              {
                asset-id: validated-asset-id,
                contract-id: (some contract-id),
                sender: rights-user,
                amount: fee,
                timestamp: block-height,
                entry-id: none,
                transaction-type: "license-fee",
                is-processed: true  ;; Simplified for this example
              }
            )
            
            ;; Increment payment ID counter
            (var-set next-transaction-id (+ transaction-id u1))
          )
          
          ;; Increment license ID counter
          (var-set next-contract-id (+ contract-id u1))
          
          (ok contract-id)
        )
      )
    )
  )
)

;; Record IP usage
(define-public (record-ip-usage
                (asset-id uint)
                (contract-id (optional uint))
                (usage-category (string-ascii 32))
                (channel (string-ascii 64))
                (proof-hash (buff 32))
                (income-generated (optional uint)))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-usage-category-resp (validate-usage-category usage-category)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-usage-category-resp) 
              (err (unwrap-err! validated-usage-category-resp (err u"Invalid usage type"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-usage-category (unwrap-panic validated-usage-category-resp)))
      
      ;; Get registration and usage counter
      (let ((asset-record (unwrap! (map-get? asset-records 
                                 { asset-id: validated-asset-id }) 
                                (err u"Registration not found")))
            (usage-counter (unwrap! (map-get? next-entry-id 
                                  { asset-id: validated-asset-id }) 
                                   (err u"Counter not found")))
            (entry-id (get id usage-counter)))
        
        ;; Validate license if provided
        (if (is-some contract-id)
            (let ((contract-id-value (unwrap-panic contract-id))
                  (validated-contract-id-resp (validate-contract-id (unwrap-panic contract-id))))
              
              (asserts! (is-ok validated-contract-id-resp)
                        (err (unwrap-err! validated-contract-id-resp (err u"Invalid license ID"))))
              
              (let ((validated-contract-id (unwrap-panic validated-contract-id-resp))
                    (license (unwrap! (map-get? active-contracts 
                                     { contract-id: validated-contract-id })
                                    (err u"License not found"))))
                ;; Check license validity
                (asserts! (and (is-eq (get asset-id license) validated-asset-id)
                              (is-eq (get rights-user license) tx-sender))
                          (err u"Invalid license for this usage"))
                (asserts! (get is-valid license) (err u"License not active"))
                (asserts! (not (get is-terminated license)) (err u"License revoked"))
                
                ;; Check license expiration
                (if (is-some (get terminates-at license))
                    (asserts! (< block-height (unwrap-panic (get terminates-at license))) 
                              (err u"License expired"))
                    true)
                
                ;; Check usage limits
                (if (is-some (get usage-limit license))
                    (asserts! (< (get usage-count license) (unwrap-panic (get usage-limit license)))
                              (err u"Usage limit exceeded"))
                    true)
                
                ;; Update usage counter for license
                (map-set active-contracts
                  { contract-id: validated-contract-id }
                  (merge license { usage-count: (+ (get usage-count license) u1) })
                )
              )
            )
            ;; If no license provided, ensure the work is public domain
            (asserts! (get is-public asset-record) (err u"Non-public domain works require a license"))
        )
        
        ;; Create the usage record
        (map-set usage-records
          { asset-id: validated-asset-id, entry-id: entry-id }
          {
            user: tx-sender,
            contract-id: contract-id,
            usage-category: validated-usage-category,
            channel: channel,
            proof-hash: proof-hash,
            timestamp: block-height,
            income-generated: income-generated,
            is-confirmed: false,
            confirmer: none
          }
        )
        
        ;; Increment usage counter
        (map-set next-entry-id
          { asset-id: validated-asset-id }
          { id: (+ entry-id u1) }
        )
        
        ;; If revenue was generated, process royalty payment
        (if (and (is-some income-generated) (> (unwrap-panic income-generated) u0))
            (record-usage-royalty validated-asset-id entry-id (unwrap-panic income-generated))
            (ok entry-id))
      )
    )
  )
)

;; Record royalty from usage revenue
(define-public (record-usage-royalty (asset-id uint) (entry-id uint) (revenue uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-entry-id-resp (validate-entry-id validated-asset-id entry-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-entry-id-resp)
                  (err (unwrap-err! validated-entry-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-entry-id (unwrap-panic validated-entry-id-resp))
              (standard-royalty-rate u1000)  ;; 10% standard rate
              (royalty-amount (/ (* revenue standard-royalty-rate) u10000))
              (transaction-id (var-get next-transaction-id)))
          
          ;; Create payment record
          (map-set revenue-transactions
            { transaction-id: transaction-id }
            {
              asset-id: validated-asset-id,
              contract-id: none,
              sender: tx-sender,
              amount: royalty-amount,
              timestamp: block-height,
              entry-id: (some validated-entry-id),
              transaction-type: "royalty",
              is-processed: false
            }
          )
          
          ;; Increment payment ID counter
          (var-set next-transaction-id (+ transaction-id u1))
          
          ;; Transfer royalty payment
          (asserts! (is-ok (stx-transfer? royalty-amount tx-sender (as-contract tx-sender)))
                    (err u"Royalty payment transfer failed"))
          
          ;; Mark as distributed
          (map-set revenue-transactions
            { transaction-id: transaction-id }
            (merge (unwrap-panic (map-get? revenue-transactions { transaction-id: transaction-id }))
              { is-processed: true })
          )
          
          (ok transaction-id)
        )
      )
    )
  )
)

;; Verify IP usage
(define-public (verify-ip-usage (asset-id uint) (entry-id uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-entry-id-resp (validate-entry-id validated-asset-id entry-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-entry-id-resp)
                  (err (unwrap-err! validated-entry-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-entry-id (unwrap-panic validated-entry-id-resp))
              (asset-record (unwrap! (map-get? asset-records 
                                     { asset-id: validated-asset-id }) 
                                    (err u"Registration not found")))
              (usage (unwrap! (map-get? usage-records 
                             { asset-id: validated-asset-id, entry-id: validated-entry-id })
                            (err u"Usage not found"))))
          
          ;; Validate
          (asserts! (or (is-eq tx-sender (get author asset-record))
                       (is-asset-owner validated-asset-id tx-sender))
                    (err u"Not authorized to verify usage"))
          
          ;; Update usage verification
          (map-set usage-records
            { asset-id: validated-asset-id, entry-id: validated-entry-id }
            (merge usage { 
              is-confirmed: true,
              confirmer: (some tx-sender)
            })
          )
          
          (ok true)
        )
      )
    )
  )
)

;; Check if principal is an IP owner
(define-private (is-asset-owner (asset-id uint) (user principal))
  (is-some (map-get? asset-shares { asset-id: asset-id, holder: user }))
)

;; Transfer IP ownership shares
(define-public (transfer-ip-shares
                (asset-id uint)
                (recipient principal)
                (share-percentage uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (asset-record (unwrap! (map-get? asset-records 
                               { asset-id: (unwrap-panic validated-asset-id-resp) }) 
                              (err u"Registration not found")))
          (sender-ownership (unwrap! (map-get? asset-shares 
                                   { asset-id: (unwrap-panic validated-asset-id-resp), holder: tx-sender })
                                  (err u"No ownership found")))
          (recipient-ownership (map-get? asset-shares 
                              { asset-id: (unwrap-panic validated-asset-id-resp), holder: recipient })))
      
      ;; Validate
      (asserts! (is-eq (get state asset-record) "registered") 
                (err u"Registration not in valid state"))
      (asserts! (<= share-percentage (get portion sender-ownership)) 
                (err u"Insufficient ownership shares"))
      (asserts! (> share-percentage u0) 
                (err u"Share percentage must be greater than zero"))
      
      ;; Update sender's ownership
      (map-set asset-shares
        { asset-id: validated-asset-id, holder: tx-sender }
        (merge sender-ownership 
          { portion: (- (get portion sender-ownership) share-percentage) }
        )
      )
      
      ;; Update or create recipient's ownership
      (if (is-some recipient-ownership)
          (map-set asset-shares
            { asset-id: validated-asset-id, holder: recipient }
            (merge (unwrap-panic recipient-ownership)
              { 
                portion: (+ (get portion (unwrap-panic recipient-ownership)) 
                                   share-percentage),
                obtained-at: block-height,
                obtained-from: (some tx-sender)
              }
            )
          )
          (map-set asset-shares
            { asset-id: validated-asset-id, holder: recipient }
            {
              portion: share-percentage,
              obtained-at: block-height,
              obtained-from: (some tx-sender)
            }
          )
      )
      
      (ok true)
    )
  )
)