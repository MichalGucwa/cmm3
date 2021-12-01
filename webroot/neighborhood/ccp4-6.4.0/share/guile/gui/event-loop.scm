
(define-module (gui event-loop)
  #:use-module (gtk gtk)
  #:export (callback
            event-loop
            gtk-signal-connect-delayed))

(define callback #f)

(define (event-loop)
  (let ((c callback))
    (set! callback #f)
    (if c (c)))
  (gtk-main-iteration)
  (event-loop))

(define (gtk-signal-connect-delayed obj sig proc)
  (gtk-signal-connect obj sig 
		      (lambda args (set! callback 
                                         (lambda ()
                                           (apply proc args))))))
