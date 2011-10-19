(library
 (harlan generate-kernel-calls)
 (export
  generate-kernel-calls)
 (import
  (rnrs)
  (only (print-c) format-ident)
  (util helpers)
  (util match))

  (define-match (generate-kernel-calls)
   ((module ,[Decl -> decl*] ...)
    `(module . ,decl*)))

 (define-match (Decl)
   ((fn ,name ,args ,type ,[Stmt -> stmt*] ...)
    `(fn ,name ,args ,type . ,stmt*))
   (,else else))

 (define (get-arg-length a)
   (match (type-of a)
     ((vector ,t ,n) n)
     (,else (error 'get-arg-length "Invalid kernel argument" a))))
 
 (define Stmt
   (lambda (stmt)
     (match stmt
       ((apply-kernel ,k ,arg* ...)
        (let ((kernel (gensym k)))
          `(block
            (let ,kernel cl::kernel (call cl::kernel
                                          (field (var cl::program g_prog)
                                                 createKernel)
                                          (str ,(symbol->string k))))
            (do ,@(map (lambda (arg i)
                         `(call void
                                (field (var cl::kernel ,kernel) setArg)
                                (int ,i)
                                ,arg))
                       arg* (iota (length arg*)))
                (call void (field (var cl::queue g_queue) execute)
                      (var cl::kernel ,kernel)
                      (int ,(get-arg-length (car arg*))) ;; global size
                      (int 1)))))) ;; local size
       ((for (,i ,start ,end) ,[stmt*] ...)
        `(for (,i ,start ,end) ,stmt* ...))
       (,else else))))

 (define (unpack-arg x)
   (match x
     ((var ,t ,x^) x^)
     (,x^ (guard (symbol? x^)) x^)
     (,else (error 'unpack-arg "invalid kernel argument" else))))

;; end library
 )