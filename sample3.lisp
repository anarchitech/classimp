;; version of simple-sample with some animation, materials
;;
;; (note that the animation and drawing code are very inefficient, so
;;  shouldn't be used directly...)
(in-package #:classimp-sample)

(defclass ai-sample3-window (glut:window)
  ((file :accessor file :initarg :file)
   (scene :accessor scene :initarg :scene)
   (bounds-min :accessor bounds-min)
   (bounds-max :accessor bounds-max)
   (scene-center :accessor scene-center :initform #(0.0 0.0 0.0))
   (scene-scale :accessor scene-scale :initform 1.0)
   (angle :accessor angle :initform 0.0))

  (:default-initargs :width 640 :height 480 :title (lisp-implementation-type)
                     :mode '(:double :rgb :depth :multisample)))

(defmethod update-bounds ((window ai-sample3-window))
  (setf (values (bounds-min window) (bounds-max window))
        (scene-bounds (scene window)))
  (let* ((min (bounds-min window))
         (max (bounds-max window))
         (d (sb-cga:vec- max min))
         (s (/ 1.0 (max (aref d 0) (aref d 1) (aref d 2))))
         (c (sb-cga:vec/ (sb-cga:vec+ min max) 2.0)))
    (setf (scene-scale window) (* 0.95 s))
    (setf (scene-center window) c)))

(defmethod glut:display-window :before ((window ai-sample3-window))
  (update-bounds window)
  (reload-textures window)
  (gl:polygon-mode :front :fill)
  (gl:polygon-mode :back :line)
  (gl:clear-color 0.1 0.1 0.1 1.0)
  (il:init)
  (ilut:init)
  (ilut:renderer :opengl)
  (ilut:enable :opengl-conv)
  (gl:enable :depth-test :multisample))

(defparameter *flip-yz* nil)
(defparameter *tris* 0)
(defparameter *spin* nil)
(defparameter *anim-speed* 0.2)
(defparameter *wire* t)
(defparameter *dump* nil)

(defparameter *bone-transforms* nil)
(defparameter *node-transforms* nil)
(defparameter *current-bone-transform* sb-cga:+identity-matrix+)


(defmethod animate-bones ((w ai-sample3-window))
  ;; update node transform (probably should just do this one at load)
  (labels ((nx (n)
             (let* ((m (ai:transform n))
                    (*current-bone-transform*
                     (sb-cga:matrix* m *current-bone-transform*)))
               (setf (gethash (ai:name n) *node-transforms*)
                     *current-bone-transform*)
               (loop for child across (ai:children n)
                  do (nx child)))))
    (nx (ai:root-node (scene w))))
  (unless (zerop (length (ai:animations (scene w))))
    (loop
      with anims = (ai:animations (scene w))
      with a = (unless (zerop (length anims)) (aref anims 0))
      with time = (if (and a (not (zerop (ai:duration a))))
                      (mod (* *anim-speed*
                              (/ (get-internal-real-time)
                                 (float internal-time-units-per-second 1f0)))
                           (ai:duration a))
                      0.0)
      for na across (ai:channels a)
      do
      ;; fixme: something should check for anims with no keys at all,
      ;; not sure if that should be here or if we should just drop the
      ;; whole node-anim in translators?
       ;; fixme: clean up interpolation stuff, cache current keyframe, etc
      (let ((r (ai:value (aref (ai:rotation-keys na) 0)))
            (s (aref (ai:scaling-keys na) 0))
            (x (ai:value (aref (ai:position-keys na) 0))))
        (loop
           for i across (ai:rotation-keys na)
           for j from -1
           until (> (ai:key-time i) time)
           do (setf r (ai:value i))
           finally (when (and (>= j 0) (> (ai:key-time i) time))
                     (let ((prev (aref (ai:rotation-keys na) j)))
                       (setf r (nqlerp (ai:value prev) (ai:value i)
                                     (/ (- time (ai:key-time prev))
                                        (- (ai:key-time i)
                                           (ai:key-time prev))))))))
        (loop for i across (ai:scaling-keys na)
           while (<= (ai:key-time i) time)
           do (setf s i))
        (loop for i across (ai:position-keys na)
           for j from -1
           while (<= (ai:key-time i) time)
           do (setf x (ai:value i))
           finally (when (and (>= j 0) (> (ai:key-time i) time))
                     (let* ((prev (aref (ai:position-keys na) j))
                            (dt (float
                                 (/ (- time (ai:key-time prev))
                                    (- (ai:key-time i) (ai:key-time prev)))
                                 1f0)))
                       (setf x (sb-cga:vec-lerp (ai:value prev) (ai:value i) dt)))))
        (setf (gethash (ai:node-name na) *bone-transforms*)
              (sb-cga:matrix* (sb-cga:translate x)
                              (quat->matrix r)
                              (sb-cga:scale (ai:value s)))))))
  (labels ((ax (n)
             (let* ((m (or (gethash (ai:name n) *bone-transforms*)
                           (gethash (ai:name n) *node-transforms*)))
                    (*current-bone-transform*
                     (sb-cga:matrix* *current-bone-transform* m)))
               (setf (gethash (ai:name n) *bone-transforms*)
                     *current-bone-transform*)
               (loop for child across (ai:children n)
                  do (ax child)))))
    (ax (ai:root-node (scene w)))))


(defmethod set-up-material ((w ai-sample3-window) material)
  (flet ((material (param value)
           (when value
             (when (eq param :shininess)
               (setf value (max 0.0 (min 128.0 value))))
             (if (or (numberp value) (= (length value) 4))
                 (gl:material :front param value)
                 (gl:material :front param (map-into (vector 1.0 1.0 1.0 1.0) #'identity value)))
             (when (eq param :diffuse)
               (if (= (length value) 3)
                   (gl:color (aref value 0) (aref value 1) (aref value 2))
                   (gl:color (aref value 0) (aref value 1) (aref value 2) (aref value 3)))))))
    (material :ambient (gethash "$clr.ambient" material))
    (material :diffuse (gethash "$clr.diffuse" material))
    (material :specular(gethash "$clr.specular" material))
    (material :emission (gethash "$clr.emissive" material))
    (material :shininess (gethash "$mat.shininess" material))
    (material :emission (gethash "$clr.emissive" material))
    (let* ((tex (gethash "$tex.file" material))
           (tex-name (getf (cdddr (assoc :ai-texture-type-diffuse tex))
                           :texture-name)))
      (when *dump* (format t "tex = ~s / ~s~%" tex tex-name))
      (if tex-name
          (progn
            (gl:enable :texture-2d)
            (gl:bind-texture :texture-2d tex-name)
            (let ((uvx (car (gethash "$tex.uvtrafo" material))))
              (gl:matrix-mode :texture)
              (gl:load-identity)
              (when uvx
                  (destructuring-bind (type index (x s r)) uvx
                    (declare (ignore type index))
                    (gl:translate (aref x 0) (aref x 1) 0.0)
                    (gl:scale (aref s 0) (aref s 1) 1.0)
                    (gl:rotate (* (/ 180 pi) r) 0.0 0.0 1.0)
                    ))
              (gl:matrix-mode :modelview)))
          (gl:disable :texture-2d)))))

(defmethod recursive-render ((w ai-sample3-window))
  (labels
      ((r (scene node)
         (gl:with-pushed-matrix
           (when (gethash (ai:name node) *node-transforms*)
             (gl:with-pushed-matrix
               (gl:mult-transpose-matrix (gethash (ai:name node)
                                                  *node-transforms*))
               (gl:color 0.5 0.4 1.0 1.0)
               (axes (* (scene-scale w) 0.05))))
           (when (gethash (ai:name node) *bone-transforms*)
             (gl:with-pushed-matrix
               (gl:mult-matrix (gethash (ai:name node) *bone-transforms*))
               (gl:color 1.5 0.4 0.0 1.0)
               (axes (* (scene-scale w) 0.1))))
           (loop
              with node-meshes = (ai:meshes node)
              with scene-meshes = (ai:meshes scene)
              for mesh-index across node-meshes
              for mesh = (aref scene-meshes mesh-index)
              for faces = (ai:faces mesh)
              for vertices = (ai:vertices mesh)
              for bones = (ai:bones mesh)
              when bones
              do (loop
                    with skinned-vertices = (map-into
                                             (make-array (length vertices))
                                             (lambda ()
                                               (sb-cga:vec 0.0 0.0 0.0)))
                    for bone across bones
                    for ofs = (ai:offset-matrix bone)
                    for bx = (gethash (ai:name bone) *bone-transforms*)
                    for nx = (gethash (ai:name bone) *node-transforms*)
                    for mm = (if (and ofs bx )
                                 (sb-cga:matrix* bx (sb-cga:transpose-matrix ofs))
                                 (or ofs bx))
                    do (when mm
                         (loop for w across (ai:weights bone)
                            for id = (ai:id w)
                            for weight = (ai:weight w)
                            do
                            (setf (aref skinned-vertices id)
                                  (sb-cga:vec+ (aref skinned-vertices id)
                                               (sb-cga:vec*
                                                (sb-cga:transform-point
                                                 (aref vertices id)
                                                 mm)
                                                weight)))))
                    finally (setf vertices skinned-vertices))
              do
                (gl:material :front :ambient #(0.2 0.2 0.2 1.0))
                (gl:material :front :diffuse #(0.8 0.8 0.8 1.0))
                (gl:material :front :emission #(0.0 0.0 0.0 1.0))
                (gl:material :front :specular #(1.0 0.0 0.0 1.0))
                (gl:material :front :shininess 120.0)
                (gl:color 1.0 1.0 1.0 1.0)
                (if (ai:material-index mesh)
                  (set-up-material w (aref (ai:materials scene)
                                           (ai:material-index mesh))))
                (gl:with-primitives :triangles
                  (loop
                      for face across faces
                      do
                      (incf *tris*)
                      (loop
                         for i across face
                         for v = (aref vertices i)
                         do
                           (when (ai:normals mesh)
                             (let ((n (sb-cga:normalize (aref (ai:normals mesh)
                                                              i))))
                             (gl:normal (aref n 0) (aref n 1) (aref n 2))))
                           (when (and (ai:colors mesh)
                                      (> (length (ai:colors mesh)) 0))
                             (let ((c (aref (ai:colors mesh) 0)))
                               (when (setf c (aref c i)))
                               (when c (gl:color (aref c 0)
                                                 (aref c 1)
                                                 (aref c 2)))))
                           (when (and (ai:texture-coords mesh)
                                      (> (length (ai:texture-coords mesh)) 0))
                             (let ((tc (aref (ai:texture-coords mesh) 0)))
                               (when tc
                                 (gl:tex-coord (aref (aref tc i) 0)
                                               (aref (aref tc i) 1)
                                               (aref (aref tc i) 2)))))
                         (gl:vertex (aref v 0) (aref v 1) (aref v 2))))))
           (loop for child across (ai:children node)
              do (r scene child)))))
    (r (scene w) (ai:root-node (scene w)))))

(defmethod xform ((w ai-sample3-window))
  (if *wire*
      (gl:polygon-mode :front :line)
      (gl:polygon-mode :front :fill))
  (gl:disable :cull-face)
  (gl:enable :normalize :color-material :lighting :light0)
  (gl:color-material :front-and-back :ambient-and-diffuse)
  (gl:matrix-mode :modelview)
  (gl:load-identity)
  (gl:light :light0 :position '(2.0 1.0 0.5 0.0))
  (glu:look-at 0.0 0.5 3.0
               0.0 0.0 0.0
               0.0 1.0 0.0)
  (let ((s (scene-scale w))
        (c (scene-center w)))
    (when *spin*
      (if (numberp *spin*)
          (gl:rotate (float *spin* 1.0) 0.0 1.0 0.0)
          (gl:rotate (spin) 0.0 1.0 0.0)))
    (when *flip-yz*
      (gl:rotate -90.0 1.0 0.0 0.0))
    (gl:scale s s s)
    (gl:translate (- (aref c 0)) (- (aref c 1)) (- (aref c 2)))))

(defmethod glut:display ((w ai-sample3-window))
  (gl:clear :color-buffer-bit :depth-buffer-bit)
  (when (and (slot-boundp w 'scene)
             (scene w))
    (xform w)
    (let ((*tris* 0))
      (let ((*bone-transforms* (make-hash-table :test 'equal))
            (*node-transforms* (make-hash-table :test 'equal)))
        (animate-bones w)
        (recursive-render w))
      (when *dump*
        (setf *dump* nil)
        (format t "drew ~s tris~%" *tris*))))
  (glut:swap-buffers))

(defmethod glut:idle ((window ai-sample3-window))
  (glut:post-redisplay))

(defmethod glut:reshape ((window ai-sample3-window) width height)
  (setf (glut:width window) width
        (glut:height window) height)
  (gl:matrix-mode :projection)
  (gl:load-identity)
  (gl:ortho -1 1 -1 1 -10 10)
  (gl:viewport 0 0 width height)
  (gl:matrix-mode :modelview))

(defmethod glut:keyboard ((window ai-sample3-window) key x y)
  (declare (ignore x y))
  ;; fixme: use cond or case or something :p
  (when (eql key #\Esc)
    (glut:destroy-current-window))
  (when (eql key #\d)
    (setf *dump* t))
  (when (eql key #\w)
    (setf *wire* (not *wire*)))
  (when (eql key #\z)
    (setf *flip-yz*(not *flip-yz*)))

  (when (eql key #\p)
    (next-file-key window -1))
  (when (eql key #\n)
    (next-file-key window))

  (when (eql key #\space)
    (reload-scene window))

  (when (eql key #\Backspace)
    (setf *anim-speed* 1.0))
  (when (or (eql key #\+) (eql key #\=))
    (setf *anim-speed* (* *anim-speed* 1.1)))
  (when (eql key #\-)
    (setf *anim-speed* (/ *anim-speed* 1.1)))

  (when (eql key #\r)
    (setf *spin* (if (numberp *spin*) nil (if *spin* (spin) t))))
  (when (eql key #\[)
    (setf *spin* (if (numberp *spin*)
                     (1- *spin*)
                     (spin))))
  (when (eql key #\])
    (setf *spin* (if (numberp *spin*)
                     (1+ *spin*)
                     (spin)))))

(defun ai-sample3 (&optional (file (merge-pathnames
                                    "cube.dae" #.(or *compile-file-pathname*
                                                     *load-pathname*))))
  (format t "loading ~s (~s) ~%" file (probe-file file))
  (ai:with-log-to-stdout ()
    (let* ((*filename*  (namestring (truename file)))
           (scene (reload-scene)))
      (when scene (glut:display-window (make-instance 'ai-sample3-window
                                                      :scene scene))))))

;(ai-sample3)
;(ai-sample3 (cffi-sys:native-namestring (merge-pathnames "src/assimp/test/models/B3D/dwarf2.b3d" (user-homedir-pathname))))
;(cl-glut:main-loop)
