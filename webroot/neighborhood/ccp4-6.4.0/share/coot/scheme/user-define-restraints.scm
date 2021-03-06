

(define (res-name-from-atom-spec atom-spec)

  (let ((imol (cadr atom-spec)))
    (residue-name imol 
		  (list-ref atom-spec 2)
		  (list-ref atom-spec 3)
		  (list-ref atom-spec 4))))


(define (user-defined-add-single-bond-restraint)

  (add-status-bar-text "Click on 2 atoms to define the additional bond restraint")
  (user-defined-click 2 
		      (lambda (atom-specs)
			(if (= (cadr (list-ref atom-specs 0))
			       (cadr (list-ref atom-specs 1)))
			    (let ((imol (cadr (list-ref atom-specs 0))))
			      (format #t "imol: ~s   spec-1: ~s   spec-2: ~s~% "
				      imol
				      (list-ref atom-specs 0)
				      (list-ref atom-specs 1))
			      
			      (add-extra-bond-restraint imol
							(list-ref (list-ref atom-specs 0) 2)
							(list-ref (list-ref atom-specs 0) 3)
							(list-ref (list-ref atom-specs 0) 4)
							(list-ref (list-ref atom-specs 0) 5)
							(list-ref (list-ref atom-specs 0) 6)
							(list-ref (list-ref atom-specs 1) 2)
							(list-ref (list-ref atom-specs 1) 3)
							(list-ref (list-ref atom-specs 1) 4)
							(list-ref (list-ref atom-specs 1) 5)
							(list-ref (list-ref atom-specs 1) 6)
							1.54 0.05))))))

(define (user-defined-add-arbitrary-length-bond-restraint)
  (generic-single-entry "Add a User-defined extra distance restraint"
			"2.0"
			"OK..."
			(lambda (text) 
			  (let ((s  "Now click on 2 atoms to define the additional bond restraint"))
			    (add-status-bar-text s))
			  (let ((bl (string->number text)))
			    (if (not (number? bl))
				(add-status-bar-text "Must define a number for the bond length")

				(user-defined-click 
				 2 
				 (lambda (atom-specs)
				   (if (= (cadr (list-ref atom-specs 0))
					  (cadr (list-ref atom-specs 1)))
				       (let ((imol (cadr (list-ref atom-specs 0))))
					 (format #t "imol: ~s   spec-1: ~s   spec-2: ~s~% "
						 imol
						 (list-ref atom-specs 0)
						 (list-ref atom-specs 1))
					 
					 (add-extra-bond-restraint 
					  imol
					  (list-ref (list-ref atom-specs 0) 2)
					  (list-ref (list-ref atom-specs 0) 3)
					  (list-ref (list-ref atom-specs 0) 4)
					  (list-ref (list-ref atom-specs 0) 5)
					  (list-ref (list-ref atom-specs 0) 6)
					  (list-ref (list-ref atom-specs 1) 2)
					  (list-ref (list-ref atom-specs 1) 3)
					  (list-ref (list-ref atom-specs 1) 4)
					  (list-ref (list-ref atom-specs 1) 5)
					  (list-ref (list-ref atom-specs 1) 6)
					  bl 0.035))))))))))


(define (add-base-restraint imol spec-1 spec-2 atom-name-1 atom-name-2 dist)
  (format #t "add-base-restraint ~s ~s ~s ~s ~s ~s~%" imol spec-1 spec-2 atom-name-1 atom-name-2 dist)
  (add-extra-bond-restraint imol
			    (list-ref spec-1 2)
			    (list-ref spec-1 3)
			    (list-ref spec-1 4)
			    atom-name-1
			    (list-ref spec-1 6)
			    (list-ref spec-2 2)
			    (list-ref spec-2 3)
			    (list-ref spec-2 4)
			    atom-name-2
			    (list-ref spec-2 6)
			    dist 0.035))

(define (a-u-restraints spec-1 spec-2)

  (let ((imol (cadr spec-1)))
    (add-base-restraint imol spec-1 spec-2 " N6 " " O4 " 3.12)
    (add-base-restraint imol spec-1 spec-2 " N1 " " N3 " 3.05)
    (add-base-restraint imol spec-1 spec-2 " C2 " " O2 " 3.90)
    (add-base-restraint imol spec-1 spec-2 " C2 " " O2 " 3.90)
    (add-base-restraint imol spec-1 spec-2 " N3 " " O2 " 5.12)
    (add-base-restraint imol spec-1 spec-2 " C6 " " O4 " 3.92)
    (add-base-restraint imol spec-1 spec-2 " C4 " " C6 " 8.38)))

(define (g-c-restraints spec-1 spec-2)
    
  (let ((imol (cadr spec-1)))
    (add-base-restraint imol spec-1 spec-2 " O6 " " N4 " 3.08)
    (add-base-restraint imol spec-1 spec-2 " N1 " " N3 " 3.04)
    (add-base-restraint imol spec-1 spec-2 " N2 " " O2 " 3.14)
    (add-base-restraint imol spec-1 spec-2 " C4 " " N1 " 7.73)
    (add-base-restraint imol spec-1 spec-2 " C5 " " C5 " 7.21)))

(define (user-defined-RNA-A-form)
  (user-defined-click 2
		      (lambda (atom-specs)
			(let ((spec-1 (list-ref atom-specs 0))
			      (spec-2 (list-ref atom-specs 1)))
			  (let ((res-name-1 (res-name-from-atom-spec spec-1))
				(res-name-2 (res-name-from-atom-spec spec-2)))

			    (if (and (string=? res-name-1 "G")
				     (string=? res-name-2 "C"))
				(g-c-restraints spec-1 spec-2))

			    (if (and (string=? res-name-1 "C")
				     (string=? res-name-2 "G"))
				(g-c-restraints spec-2 spec-1))

			    (if (and (string=? res-name-1 "A")
				     (string=? res-name-2 "U"))
				(a-u-restraints spec-1 spec-2))

			    (if (and (string=? res-name-1 "U")
				     (string=? res-name-2 "A"))
				(a-u-restraints spec-2 spec-1)))))))

(define (user-defined-add-helix-restraints)
    (user-defined-click 
     2 (lambda (atom-specs)
	 (let* ((spec-1 (list-ref atom-specs 0))
		(spec-2 (list-ref atom-specs 1))
		(chain-id-1 (list-ref spec-1 2))
		(chain-id-2 (list-ref spec-2 2))
		(resno-1 (list-ref spec-1 3))
		(resno-2 (list-ref spec-2 3))
		(imol (cadr spec-1)))


	   (if (string=? chain-id-1 chain-id-2)
	       (begin
		 ;; if backwards, swap them
		 (if (< resno-2 resno-1)
		     (let ((tmp resno-1))
		       (set! resno-1 resno-2)
		       (set! resno-2 tmp)))
		 (let loop ((rn resno-1))
		   (cond
		    ((> (+ rn 3) resno-2) 'done)
		    ((<= (+ rn 4) resno-2)
		     (add-extra-bond-restraint imol 
					       chain-id-1 rn       "" " O  " ""
					       chain-id-1 (+ rn 3) "" " N  " ""
					       3.18 0.035)
		     (add-extra-bond-restraint imol 
					       chain-id-1 rn       "" " O  " ""
					       chain-id-1 (+ rn 4) "" " N  " ""
					       2.91 0.035)
		     (loop (+ rn 1)))
		     (else 
		      (add-extra-bond-restraint imol 
						chain-id-1 rn       "" " O  " ""
						chain-id-1 (+ rn 3) "" " N  " ""
						3.18 0.035)
		      (loop  (+ rn 1)))))))))))



(define (user-defined-delete-restraint)
  (user-defined-click 2 
		      (lambda (atom-specs)
			(let* ((spec-1 (cddr (list-ref atom-specs 0)))
			       (spec-2 (cddr (list-ref atom-specs 1)))
			       (imol (cadr (list-ref atom-specs 0))))
			  (delete-extra-restraint imol (list 'bond spec-1 spec-2))))))

;; exte dist first chain A resi 19 ins . atom  N   second chain A resi 19 ins . atom  OG  value 2.70618 sigma 0.4
;;
(define (extra-restraints->refmac-restraints-file imol file-name)
  (let ((restraints (list-extra-restraints imol)))
    (if (list? restraints)
	(call-with-output-file file-name
	  (lambda (port)
	    (for-each (lambda (restraint)
			(if (eq? (car restraint) 'bond)
			    (begin
			      (let ((chain-id-1 (list-ref (cadr restraint) 1))
				    (resno-1    (list-ref (cadr restraint) 2))
				    (inscode-1  (list-ref (cadr restraint) 3))
				    (atom-1     (list-ref (cadr restraint) 4))
				    (chain-id-2 (list-ref (caddr restraint) 1))
				    (resno-2    (list-ref (caddr restraint) 2))
				    (inscode-2  (list-ref (caddr restraint) 3))
				    (atom-2     (list-ref (caddr restraint) 4))
				    (value      (list-ref restraint 3))
				    (esd        (list-ref restraint 4)))
				
			      (format port "EXTE DIST FIRST CHAIN ~a RESI ~s INS ~a ATOM ~a "
				      (if (or (string=? chain-id-1 " ")
					      (string=? chain-id-1 ""))
					  "."
					  chain-id-1)
				      resno-1
				      (if (or (string=? inscode-1 " ")
					      (string=? inscode-1 ""))
					  "."
					  inscode-1)
				      atom-1)
			      (format port " SECOND CHAIN ~a RESI ~s INS ~a ATOM ~a "
				      (if (or (string=? chain-id-2 " ")
					      (string=? chain-id-2 ""))
					  "."
					  chain-id-2)
				      resno-1
				      (if (or (string=? inscode-2 " ")
					      (string=? inscode-2 ""))
					  "."
					  inscode-2)
				      atom-2)
			      (format port "VALUE ~s SIGMA ~s~%" value esd)))))
		      restraints))))))

;; target is my molecule, ref is the homologous (high-res) model
;; 
(define (run-prosmart imol-target imol-ref)
  (let ((dir-stub "coot-ccp4"))
    (make-directory-maybe dir-stub)
    (let ((target-pdb-file-name (append-dir-file dir-stub 
						 (string-append (molecule-name-stub imol-target 0)
								"-prosmart.pdb")))
	  (reference-pdb-file-name (append-dir-file dir-stub
						    (string-append (molecule-name-stub imol-ref 0)
								   "-prosmart-ref.pdb")))
	  (prosmart-out (append-dir-file "ProSMART_Output"
					 (string-append
					  (coot-replace-string (molecule-name-stub imol-target 0) 
							       " " "_" )
					  "-prosmart.txt"))))
			 
      (write-pdb-file imol-target target-pdb-file-name)
      (write-pdb-file imol-ref reference-pdb-file-name)
      (goosh-command "prosmart" 
		     (list "-p1" target-pdb-file-name
			   "-p2" reference-pdb-file-name)
		     '()
		     (append-dir-file dir-stub "prosmart.log")
		     #f)
      (if (not (file-exists? prosmart-out))
	  (begin
	    (format #t "file not found ~s~%" prosmart-out))
	  (begin 
	    (format #t "Reading ProSMART restraints from ~s~%" prosmart-out)
	    (add-refmac-extra-restraints imol-target prosmart-out))))))


(if (defined? 'coot-main-menubar)

    (let* ((menu (coot-menubar-menu "Extras")))
      
      (add-simple-coot-menu-menuitem 
       menu "Add Simple C-C Single Bond Restraint..."
       user-defined-add-single-bond-restraint)

      (add-simple-coot-menu-menuitem 
       menu "Add Distance Restraint..."
       user-defined-add-arbitrary-length-bond-restraint)

      (add-simple-coot-menu-menuitem 
       menu "Add Helix Restraints..."
       user-defined-add-helix-restraints)

      (add-simple-coot-menu-menuitem
       menu "RNA A form bond restraints..."
       user-defined-RNA-A-form)

      (add-simple-coot-menu-menuitem
       menu "ProSMART..."
       (lambda ()
	 (let ((window (gtk-window-new 'toplevel))
	       (hbox (gtk-hbox-new #f 0))
	       (vbox (gtk-vbox-new #f 0))
	       (h-sep (gtk-hseparator-new))
	       (chooser-hint-text-1 " Target molecule ")
	       (chooser-hint-text-2 " Reference (high-res) molecule ")
	       (go-button (gtk-button-new-with-label " ProSMART "))
	       (cancel-button (gtk-button-new-with-label " Cancel ")))
			  
	   (let ((option-menu-mol-list-pair-tar (generic-molecule-chooser 
						 vbox chooser-hint-text-1))
		 (option-menu-mol-list-pair-ref (generic-molecule-chooser 
						 vbox chooser-hint-text-2)))

	     (gtk-box-pack-start vbox h-sep #f #f 2)
	     (gtk-box-pack-start vbox hbox #f #f 2)
	     (gtk-box-pack-start hbox go-button #f #f 6)
	     (gtk-box-pack-start hbox cancel-button #f #f 6)
	     (gtk-container-add window vbox)

	     (gtk-signal-connect cancel-button "clicked"
				 (lambda ()
				   (gtk-widget-destroy window)))

	     (gtk-signal-connect go-button "clicked"
				 (lambda ()
				   (let ((imol-tar 
					  (apply get-option-menu-active-molecule
						 option-menu-mol-list-pair-tar))
					 (imol-ref
					  (apply get-option-menu-active-molecule
						 option-menu-mol-list-pair-ref)))
				     (run-prosmart imol-tar imol-ref)
				     (gtk-widget-destroy window))))
	     (gtk-widget-show-all window)))))
	 

      (add-simple-coot-menu-menuitem
       menu "Delete an Extra Restraint..."
       user-defined-delete-restraint)

      (add-simple-coot-menu-menuitem
       menu "Delete Restraints for this residue"
       (lambda()
	 (using-active-atom
	  (delete-extra-restraints-for-residue aa-imol aa-chain-id aa-res-no aa-ins-code))))

      (add-simple-coot-menu-menuitem
       menu "Delete Deviant Extra Restraints..."
       (lambda ()
	 (generic-single-entry "Delete Restraints worse than " "4.0" " Delete Outlying Restraints "
			       (lambda (text)
				 (let ((n (string->number text)))
				   (if (number? n)
				       (using-active-atom
					(delete-extra-restraints-worse-than aa-imol n))))))))


      (add-simple-coot-menu-menuitem
       menu "Save as REFMAC restraints..."
       (lambda ()
	 (generic-chooser-and-file-selector "Save REFMAC restraints for molecule " 
					    valid-model-molecule?
					    " Restraints file name:  " 
					    "refmac-restraints.txt"
					    (lambda (imol file-name)
					      (extra-restraints->refmac-restraints-file imol file-name)))))))

;; Now make helix restraints, demonstrate with Bill Weiss, GPCR bent
;; helix

