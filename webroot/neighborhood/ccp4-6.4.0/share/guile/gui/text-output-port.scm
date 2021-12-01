
(define-module (gui text-output-port)
  #:use-module (gtk gdk)
  #:use-module (gtk gtk)
  #:export (make-text-output-port
            text-output-font
            text-output-colour))

(define text-output-font (make-fluid))
(define text-output-colour (make-fluid))

(define (make-text-output-port text)
  (let ((output-string (lambda (str)
                         (gtk-text-insert text
                                          (fluid-ref text-output-font)
                                          (fluid-ref text-output-colour)
                                          #f
                                          str
                                          (string-length str)))))
    (make-soft-port (vector (lambda (char)
                              (output-string (string char)))
                            output-string
                            #f
                            #f
                            #f)
                    "w")))
