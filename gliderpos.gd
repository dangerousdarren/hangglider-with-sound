extends Spatial

onready var gliderkinematics = get_node("../gliderkinematics")
onready var pitchcontroller = get_node("../OQ_ARVROrigin/OQ_RightController")
onready var arvrorigin = get_node("../OQ_ARVROrigin")
onready var headcam = get_node("../OQ_ARVROrigin/OQ_ARVRCamera")
onready var label = get_node("../OQ_UILabel")
onready var orgpos = transform.origin
onready var glider = get_node("glider2")
onready var windNoise = get_node("glider2/WindNoise3D")


func _ready():
	gliderkinematics.pos = orgpos
	windNoise.play()

var recarvrorigin = null
var headcamoffset = Vector3(0,0,0)

func _process(delta):
	var camvec = -headcam.global_transform.basis.z
	if is_nan(camvec.x):
		print("nan value in ARVRCamera!")
		return
	
	var controllerdisp = pitchcontroller.global_transform.origin - headcam.global_transform.origin
	var handdist = Vector3(camvec.x, 0, camvec.z).normalized().dot(controllerdisp)	
	if recarvrorigin != null:  # in flight hand disp needs to be in direction of flight or it responds to head turning
		handdist = Vector3(camvec.x, 0, 0).normalized().dot(controllerdisp)
	
	var hvec = Vector3(1,0,0)

	var Lb = 0.9 - handdist
	Lb = (Lb-0.4)*4 + 0.4
	
	var pos = gliderkinematics.stepdt(delta, Lb, hvec)
	if recarvrorigin == null:
		if abs(pos.x - orgpos.x) > abs(orgpos.x)*2:
			gliderkinematics.pos = orgpos
	elif abs(pos.x - orgpos.x) > abs(orgpos.x)*20:
			gliderkinematics.pos = orgpos
		
	#label.set_label_text("Lb=%f\nvelocity=%f" % [Lb, rad2deg(gliderkinematics.Y[4])])

	var bbas = Basis(Vector3(0,0,1), gliderkinematics.Y[3])
	#pos *= 0.01
	#var bpos = Vector3(pos.x - floor(pos.x/xrang)*xrang - xrang/2, pos.y - floor(pos.y/yrang)*yrang - yrang/2, zpos)
	transform = Transform(bbas, pos)
	$pilot.transform.origin = Vector3(gliderkinematics.CGpilot.x, gliderkinematics.CGpilot.y, 0)
	
	if pitchcontroller._button_just_pressed(vr.CONTROLLER_BUTTON.YB):
		if recarvrorigin == null:
			recarvrorigin = arvrorigin.transform.origin
			headcamoffset = headcam.transform.origin
		else:
			arvrorigin.transform.origin = recarvrorigin
			recarvrorigin = null
	if recarvrorigin != null:
		arvrorigin.transform.origin = $pilot.global_transform.origin - headcamoffset
		
	#Link wind noise volume and pitch to glider velocity
	var windVolume = gliderkinematics.Y[4] * 1.5 - 20
	windNoise.unit_db = windVolume #windVolume #-30
	var windPitch = gliderkinematics.Y[4] * 0.05 - 0.4
	windNoise.pitch_scale = windPitch
	label.set_label_text("Lb=%f\nvolume=%f" % [Lb, rad2deg(windVolume)])



#func _on_WindNoise_finished():
	#windNoise.play()

