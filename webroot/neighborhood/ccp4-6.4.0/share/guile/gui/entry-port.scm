
(define-module (gui entry-port)
  #:use-module (ice-9 buffered-input)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 optargs)
  #:use-module (gtk gdk)
  #:use-module (gtk gtk)
  #:use-module (gui event-loop)
  #:use-module (gui paren-match)
  #:export (make-entry-port
            entry-new-read-hook
            entry-read-complete-hook))

(define XK_Up      #xFF52)
(define XK_Down    #xFF54)
(define XK_KP_Up   #xFF97)
(define XK_KP_Down #xFF99)

(define entry-new-read-hook (make-object-property))
(define entry-read-complete-hook (make-object-property))
    
(define (install-paren-matching-handlers entry paren-matching-style)
  (letrec ((saved-pos #f)
           (restore-text (lambda args
                           (if saved-pos
                               (begin
                                 (gtk-entry-select-region entry 0 0)
                                 (gtk-entry-set-position entry saved-pos)
                                 (set! saved-pos #f)))
                           #f)))

    ;; This handler runs after insertion and checks whether the last
    ;; inserted character was a closing parenthesis.  If so, it moves
    ;; the cursor and/or highlights the matching region, and installs
    ;; a timeout to restore the entry contents after half a second.
    (gtk-signal-connect-delayed entry
                                "insert-text"
                                (lambda args
                                  (let ((str (gtk-entry-get-text entry))
                                        (pos (gtk-editable-get-position entry)))
                                    (if (and (> pos 0)
                                             (<= pos (string-length str))
                                             (char=? (string-ref str (- pos 1)) #\)))
                                        (let ((open-pos (find-matching-open str (- pos 1))))
                                          (if open-pos
                                              (begin
                                                (set! saved-pos pos)
                                                (if (memq 'move-cursor paren-matching-style)
                                                    (gtk-entry-set-position entry open-pos))
                                                (if (memq 'highlight-region paren-matching-style)
                                                    (gtk-entry-select-region entry open-pos pos))
                                                (gtk-timeout-add 500 restore-text))))))
				  #f))

    ;; This handler restores the entry contents early in the event of
    ;; a key press occurring before the above timer pops.
    (gtk-signal-connect entry "key-press-event" restore-text)))

(define (install-history-handlers entry)
  (let ((history '())
        (position -1)
        (non-history-line "--should never see this--")
        (handler #f))

    (define (history-up)
      (if (< (+ position 1) (length history))
          (begin
            (or (>= position 0)
                (set! non-history-line (gtk-entry-get-text entry)))
            (set! position (+ position 1))
            (gtk-entry-set-text entry (list-ref history position)))))

    (define (history-down)
      (if (>= position 0)
          (begin
            (set! position (- position 1))
            (gtk-entry-set-text entry
                                (if (>= position 0)
                                    (list-ref history position)
                                    non-history-line)))))

    (gtk-signal-connect entry
                        "key-press-event"
                        (lambda (event)
                          (let ((keyval (gdk-event-keyval event)))
                            (set! callback
                                  (cond ((or (= keyval XK_Up)
                                             (= keyval XK_KP_Up))
                                         history-up)
                                        ((or (= keyval XK_Down)
                                             (= keyval XK_KP_Down))
                                         history-down)
                                        (else #f)))
                            (if callback
				(begin
				  (gtk-signal-emit-stop-by-name entry "key-press-event")
				  #t)
				#f))))

    (add-hook! (entry-new-read-hook entry)
               (lambda ()
                 (let ((saved-handler handler)
                       (saved-position (if (>= position 0)
                                           (- (length history) position)
                                           position))
                       (saved-non-history-line non-history-line))
		   (set! position -1)
                   (set! handler
                         (lambda ()
                           (set! handler saved-handler)
                           (set! position (if (>= position 0)
                                              (- (length history) saved-position)
                                              saved-position))
                           (set! non-history-line saved-non-history-line))))))

    (add-hook! (entry-read-complete-hook entry)
               (lambda (str)
                 (or (string=? str "")
                     (and (not (null? history))
                          (string=? str (car history)))
                     (set! history (cons str history)))
                 (handler)))))

(define* (make-entry-port entry
                          #:key
                          (paren-matching-style '(move-cursor)))
  (letrec ((handler #f)
           (port (make-line-buffered-input-port
                   (lambda (continuation?)
                     (call-with-current-continuation
                      (lambda (cont)
                        (run-hook (entry-new-read-hook entry))
                        (let ((saved-handler handler)
                              (saved-text (gtk-entry-get-text entry))
                              (saved-position (gtk-editable-get-position entry)))
                          (set! handler
                                (lambda (str)
                                  (set! handler saved-handler)
                                  (gtk-entry-set-text entry saved-text)
                                  (gtk-entry-set-position entry saved-position)
                                  (or handler
                                      (gtk-widget-set-sensitive entry #f))
                                  (cont str))))
                        (event-loop)))))))

    ;; Attach hooks to the entry widget.  new-read hook procedures are
    ;; called with no arguments.  read-complete hook procedures are
    ;; called with the read string.
    (set! (entry-new-read-hook entry) (make-hook))
    (set! (entry-read-complete-hook entry) (make-hook 1))

    ;; Define a new-read hook procedure that saves the current
    ;; contents and cursor position of the entry and sets up handler
    ;; to restore them when the read completes.
    (add-hook! (entry-new-read-hook entry)
               (lambda ()
                 (gtk-widget-set-sensitive entry #t)
                 (gtk-widget-grab-focus entry)
                 (gtk-entry-set-text entry "")))

    ;; Define a read-complete hook procedure that clears the entry
    ;; field and invokes the current handler.
    (add-hook! (entry-read-complete-hook entry)
               (lambda (str)
                 (gtk-entry-set-text entry "")))

    ;; Run the read-complete hook when the user presses RETURN.
    (gtk-signal-connect-delayed entry
                                "activate"
                                (lambda ()
                                  (let ((str (gtk-entry-get-text entry)))
                                    (run-hook (entry-read-complete-hook entry) str)
                                    (handler str))))

    (install-paren-matching-handlers entry paren-matching-style)

    (install-history-handlers entry)

    port))
