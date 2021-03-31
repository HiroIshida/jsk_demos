;; from main.l
(ros::roseus "demo_main")
(ros::roseus-add-msgs "pr2_gripper_sensor_msgs")

(defvar *use-voicetext* t)
(defvar *use-english* nil)
(defvar *logging* nil)
(defvar *debug-view* (ros::get-param "~debug_view" t))

(setq *use-arm-navigation* nil)

(require :pr2-interface "package://pr2eus/pr2-interface.l")

;; these functions are fetched from jsk_demo_common/euslisp/pr2-move.l
(load "package://jsk_maps/src/eng2-scene.l")
(unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))

(warn "goto-front-of-fridge~%")
(defun base-go-to-fridge (&key (wait t))
  (let ((co (send *scene* :spot "/eng2/7f/room73B2-fridge-front")))
    (send co :translate (float-vector 200 250 0) :world)
    (send co :rotate -0.3 :z :world)
    (if (send *ri* :simulation-modep)
        (setq co (send *room73b2* :spot "fridge-front-spot")))
    (cond
     ((equal wait t)
      (send *ri* :move-to co)
      )
     (t
      (send *ri* :move-to-send co)
      ))
    t
    ))

(defun base-go-to-fridge-init-pose (&key (wait t) (torso-lift 130) (head-pitch 0))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :angle-vector (float-vector 0 head-pitch))
  (send *pr2* :torso :angle-vector (float-vector torso-lift))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (if wait
      (send *ri* :wait-interpolation))
  t
  )

(defun goto-front-of-fridge (&key (torso-lift 130) (head-pitch 0) (wait t))
  (base-go-to-fridge :wait wait)
  (base-go-to-fridge-init-pose :torso-lift torso-lift :head-pitch head-pitch :wait wait)
  )

;; fetched from euslisp/main.l
(defun init-for-perception ()
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
  (unless (boundp '*tfb*)
    (setq *tfb* (instance ros::transform-broadcaster :init)))
  (if (and x::*display* (/= x::*display* 0) *debug-view*) (make-irtviewer))
  (setq *obj* (make-sphere 100)) ;; dummy object
  (setq *target-name* nil)
  (ros::spin-once)
  )

(defun init-for-robot ()
  #|
  (unless (boundp '*pr2*) (pr2))
  (unless (boundp '*ri*) (setq *ri* (instance pr2-interface :init)))
  (send *ri* :spin-once)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  |#
  (pr2-init *debug-view*)
  (when *use-arm-navigation*
    (setq *plan-env* (instance arm_planning_environment :init :robot *pr2*)))
  )

(defun init ()
  (init-for-perception)
  (init-for-robot)
  (defparameter *detection-topic* "/kinect_head/rgb/ObjectDetection")
  ;;(defparameter *base-frame-id* "/base_footprint")
  (require :detection-interface "package://jsk_perception/euslisp/detection_interface.l");;
  ;;(send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  ;;(objects (list *pr2*))
  (if (send *ri* :simulation-modep)
      (progn
        (load "models/room73b2-scene.l")
        (room73b2)
        (send *ri* :objects (send *room73b2* :objects))
        ))
  )

(init)
(warn ";; (goto-front-of-fridge)~%")
