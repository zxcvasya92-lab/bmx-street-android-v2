extends Node3D
# BMX Street — порт прототипа 0.6 на Godot 4 (GDScript).
# Сцена, байк и интерфейс строятся кодом. Редактор открывать для настройки не нужно.

var G := 9.81
const FIXED := 1.0 / 120.0
var MAXS := 13.0
const LIM := 190.0
const GROUND := 0
const AIR := 1
const BAIL := 2
const GRIND := 3
const SPAWN_X := -18.0
const SPAWN_Z := -27.0
const SPAWN_B := PI / 2.0

# ---- НОВАЯ МЕХАНИКА: толчок ногами (педали L и R при отведённом назад весе) ----
const PUSH_MAX := 3.0     # сколько «заряда» копится (чередующееся нажатие = 1.3, то же самое = 0.3)
var PUSH_BOOST := 1.7   # добавка к вертикальной скорости прыжка при полном заряде, м/с
var PUSH_DECAY := 0.5   # заряд утекает со скоростью, ед/с (толчок должен быть «свежим»)

const HELP_TEXT := "СХЕМА УПРАВЛЕНИЯ\nЛевый стик/крестовина — руль и вес: вниз — назад (нос вверх), вверх — вперёд.\nПравый стик — вращения: влево/вправо — 180, 360 и больше; вверх/вниз до упора и удержать — фронтфлип/бэкфлип (в воздухе).\nL и R — модификаторы трюков. L, зажатая в воздухе — поджатие байка: прыжок чуть выше, приземляться поджатым можно.\nКрест: долбить — разгон. Стик вниз-вверх + Крест — высокий банихоп (скорость при банихопе не растёт). Стик вниз-вверх + долбёжка Креста — «акселерейт» (трюк в комбо). Стик вниз-вверх без Креста — обычный банихоп.\nТормоз — Треугольник. Если едешь фейки и жмёшь Треугольник: руль на 90 градусов и слайд. Повернёшь руль в слайде — выйдешь «фейки слайдом» и уедешь вперёд.\nПриземление с недокрученным 360 (примерно 270–340 градусов) при зажатом Треугольнике и правом стике в сторону вращения — персонаж докрутит 360 слайдом. Для 180 и 540 не работает.\nПриземление на мануал: в момент приземления утягивай левый стик вниз (мануал) или вверх (ноуз-мануал); без стика сильный наклон — бейл, небольшой выравнивается сам.\nПри бейле райдер слетает с байка и падает отдельно.\n\nСТОЙКА\nStart → «Стойка»: правая или левая нога вперёд. Родное вращение — в сторону задней ноги (правая нога вперёд — вращение влево, левая нога вперёд — вправо). Вращение в другую сторону называется «Опо» (+25% очков). Трюки, у которых отрыв был задом наперёд (фейки), называются «Свитч» (+15%).\n\nТРЮКИ\nВ воздухе: L + Крест — кренкфлип. L + Круг — вип (рама крутится вокруг руля, руки держат руль) в родную сторону по стойке, L + Квадрат — опо вип (в обратную). R + Круг — бар, R + Квадрат — опо бар. R + Крест — икс-ап.\nСтили мануала: на мануале зажми L — рокет менуал (ноги на заднем пеге); на ноуз-мануале зажми L — hang 5 (ноги на переднем пеге).\nНа рейле (пег-гринд): L + левый стик вниз — айс пик (только задний пег, нос вверх), L + стик вверх — туз пик (только передний пег). Можно менять прямо в гринде.\nФутджем вип (на земле): вес вперёд (стик вверх) + L + Круг — встаёшь ногой на переднее колесо, прокручиваешь раму и укатываешь фейки.\nЧикенбар: подними переднее колесо (мануал) и нажми R + Круг — руль крутится на земле.\n\nГРИНД\nПеги у байка только справа, поэтому рейла должна быть справа по ходу. Подпрыгни так, чтобы правые пеги легли на рейлу вдоль неё — байк захватит её. Работает и на фейки (едешь задом — получится фейки гринд). Гринд на каретке: рейла оказывается под кареткой (центром байка). Заходи под любым углом, но с движением вдоль рейлы — байк не выравнивается по рейле и скользит с тем углом, с которым зашёл. Сойти: Крест (прыжок), стик вниз-вверх или конец рейлы. Рейлы на карте города: плоский на площади у точки (8; −0,3) и 8 коротких на лестницах (текущая позиция — в диагностике, строка «Поз»). Карта — город 250 × 300 м, старт на главном перекрёстке.\n\nStart — меню (кнопки, стойка, физика, диагностика), Select — сброс.\nКлавиатура: WASD — левый стик, стрелки — правый, Q — L, E — R, Space — Крест, X — Круг, C — Треугольник, Z — Квадрат, R — сброс, Esc — меню."

# --- скелет райдера, запечённый из ryder_standing.glb (не зависит от импортёра движка) ---
const BONE_NAMES := ["Root", "Pelvis", "Spine", "Spine1", "Neck", "Head", "Jaw", "L_Brow", "R_Brow", "Bip01_L_Clavicle", "L_UpperArm", "L_ForeArm", "L_Hand", "L_Finger", "L_Finger01", "Bip01_R_Clavicle", "R_UpperArm", "R_ForeArm", "R_Hand", "R_Finger", "R_Finger01", "L_breast", "R_breast", "Belly", "L_Thigh", "L_Calf", "L_Foot", "L_Toe0", "R_Thigh", "R_Calf", "R_Foot", "R_Toe0"]
const BONE_PARENT := [-1, 0, 1, 2, 3, 4, 5, 5, 5, 4, 9, 10, 11, 12, 13, 4, 15, 16, 17, 18, 19, 3, 3, 2, 1, 24, 25, 26, 1, 28, 29, 30]
const BONE_REST := [
	[0, 0, 0, 0.501934, -0.501934, 0.498058, 0.498059, 1, 1, 1],
	[0.29379, 9.8421e-07, -0.802301, -0.546665, 0.546669, -0.448507, 0.448499, 1, 0.999997, 0.999996],
	[0.00104109, -0.00101032, 0.000151605, -0.293475, -3.01632e-05, -0.00028888, 0.955967, 0.999991, 0.999998, 0.999998],
	[-0.000107838, 0.190402, 0.000185738, -0.134851, -7.64245e-05, -1.67798e-05, 0.990866, 1.00001, 1.00001, 1.00001],
	[-0.000147011, 0.289614, -6.59171e-05, 0.0313713, -4.83988e-05, 0.000285645, 0.999508, 1.00001, 0.999999, 1.00001],
	[0.0019447, 0.107942, -0.0171689, 0.314955, -0.0315669, -0.0104822, 0.948524, 0.99999, 0.999989, 1],
	[-0.00106025, 0.0112741, -0.0154457, -0.823641, -4.42908e-06, 2.71293e-06, 0.567112, 1, 1.00001, 0.999994],
	[-0.0219087, 0.083691, 0.0171231, -0.650175, 0.0421994, 0.0669234, 0.755654, 1, 1.00001, 0.999995],
	[0.0168183, 0.0827914, 0.0179832, -0.651959, -0.0175074, -0.0625275, 0.755469, 1, 1.00001, 0.999994],
	[-1.56014e-05, 8.94093e-08, 2.04893e-08, 0.754581, -0.647917, -0.0677386, -0.0788885, 0.999997, 1, 1],
	[0.00061544, 0.194348, 0.019498, 0.196679, -0.268843, -0.367077, 0.868502, 0.999968, 1.00003, 0.999984],
	[0.0158571, 0.274342, 0.00687544, 0.295906, -0.0680146, -0.366372, 0.879537, 0.999928, 1.00005, 1.00002],
	[0.0035493, 0.284161, -0.0301855, 0.264225, -0.683621, -0.0791326, 0.675711, 0.999761, 1.00019, 1.00005],
	[-0.00108282, 0.0832908, -0.00459029, -0.0200605, -0.00267564, 0.0017294, 0.999794, 1.0002, 1.00011, 0.999708],
	[0.00212463, 0.0421376, -0.00721954, 0.00727837, -0.0474286, -0.0289027, 0.99843, 1.00154, 0.999492, 0.99898],
	[-1.56685e-05, -9.2387e-07, -3.14787e-07, 0.754582, 0.647916, 0.0677345, -0.0788888, 1, 0.999995, 1],
	[-0.000618586, 0.194335, -0.0129982, 0.219396, 0.23925, 0.432376, 0.841235, 0.999978, 1.00003, 0.999985],
	[0.00117227, 0.273303, 0.036815, 0.283879, 0.0363692, 0.249425, 0.925136, 0.999992, 1.00003, 1],
	[-0.00365766, 0.287904, -0.0187181, 0.249001, 0.674965, 0.125582, 0.683117, 0.99978, 1.00013, 1.00009],
	[0.0006361, 0.0819212, -0.000771482, -0.0307683, 0.0245856, -0.0110731, 0.999163, 0.999835, 0.999856, 1.0003],
	[-0.000205876, 0.0457468, -0.000819918, -0.163756, 0.0753197, -0.0917054, 0.979337, 0.999156, 1.00025, 1.00059],
	[-0.103297, 0.129056, 0.0683218, -0.645537, 0.110453, -0.0730332, 0.752162, 0.999997, 1, 0.999999],
	[0.107535, 0.145642, 0.0685426, -0.670522, -0.0513206, 0.0225056, 0.73977, 1, 0.999999, 0.999998],
	[0.000309979, 0.173978, 0.0699221, -0.695518, -0.0002366, 0.000162329, 0.718508, 1.00001, 1, 1],
	[-0.112472, -1.73139e-06, 1.03608e-06, 0.00761104, -0.133703, 0.988438, 0.0710984, 1, 1, 1],
	[-0.000340783, 0.455262, -0.000129826, 0.313625, 0.0116235, 0.0804387, 0.946062, 0.999998, 1, 1],
	[0.000405225, 0.483433, -0.000156724, -0.275173, 0.010085, -0.00653881, 0.961319, 1, 1.00001, 1],
	[2.3187e-07, 0.102001, -0.154, -0.707105, -5.37377e-07, 2.48665e-06, 0.707109, 1, 1, 0.999999],
	[0.112472, -1.08865e-06, 1.38802e-06, -0.00882646, -0.337886, 0.937874, -0.0784054, 1, 1, 1],
	[0.000344157, 0.455262, -0.000135527, 0.376546, -0.0062445, -0.0925804, 0.921739, 1, 1, 1],
	[-0.000402448, 0.483435, -0.00015865, -0.134951, -0.00511519, -0.00800904, 0.990807, 1, 0.999999, 1],
	[-6.12322e-07, 0.102002, -0.154079, -0.707106, 9.11426e-07, -2.48666e-06, 0.707107, 1, 0.999999, 0.999999],
]
const BONE_IBM := [
	[8.92842e-07, -1, -8.99789e-07, -0.00775111, 8.92842e-07, -0.99997, 0.99997, 8.99789e-07, -0.00775111, 0, -0, -0],
	[1, 3.0561e-06, 1.39166e-05, -5.61629e-06, 0.982216, 0.187773, -1.30951e-05, -0.187773, 0.982217, 8.42157e-06, -0.729441, -0.444883],
	[1.00001, 0.000564748, 0.000125123, -0.00048806, 0.707665, 0.706555, 0.00031048, -0.706555, 0.707666, -0.000744371, -0.353244, -0.777102],
	[0.999996, 0.000569093, 0.00012277, -0.000387454, 0.493107, 0.86997, 0.000425021, -0.869962, 0.493104, -0.000749484, -0.316153, -0.894298],
	[0.999983, 2.77259e-06, 1.50074e-05, -1.33625e-06, 0.546686, 0.837321, -9.28472e-06, -0.837333, 0.546693, -0.00105555, -0.660645, -0.854468],
	[0.997782, 7.5301e-07, -0.0664763, 0.0228603, 0.938958, 0.343262, 0.0624157, -0.344028, 0.936881, -0.0170287, -1.11678, -0.210611],
	[0.997778, 0.0621033, 0.0237191, 0.0228618, -0.655653, 0.754702, 0.0624056, -0.752489, -0.655647, -0.0159722, 0.584762, -0.984189],
	[0.99531, -0.0907237, -0.0332238, 0.0142539, -0.202214, 0.979236, -0.0955743, -0.97512, -0.2, -0.016384, 0.0469453, -1.22088],
	[0.982188, 0.18238, 0.0450459, -0.00754018, -0.201286, 0.979502, 0.187694, -0.962396, -0.19635, 0.0276982, 0.0502637, -1.22028],
	[0.151235, -0.988484, -1.56409e-05, -0.699905, -0.107068, -0.706137, 0.698033, 0.10679, -0.70806, 0.813467, 0.125493, 0.699343],
	[0.823426, -0.565166, 0.0501097, -0.558353, -0.822778, -0.106101, 0.101241, 0.0593328, -0.993107, 0.746833, 0.753778, 0.0419663],
	[0.976972, 0.211733, 0.0297402, 0.17024, -0.855623, 0.48851, 0.128989, -0.472222, -0.872029, 0.196443, 0.728427, -0.442953],
	[-0.0213287, -0.0551787, -0.998295, 0.840626, -0.541266, 0.0122465, -0.541474, -0.838784, 0.0578786, -0.562021, 0.13547, -0.266134],
	[-0.0267917, -0.0149682, -0.999866, 0.83833, -0.543691, -0.013991, -0.544423, -0.838768, 0.0271741, -0.561979, 0.0642593, -0.256282],
	[-0.118323, -0.0314247, -0.993284, 0.862419, -0.495066, -0.0876649, -0.488872, -0.868594, 0.0916248, -0.584204, -0.0140317, -0.193704],
	[0.151228, 0.988484, -4.20054e-06, 0.69991, -0.107096, -0.706141, -0.698023, 0.106782, -0.708058, -0.813785, 0.123465, 0.699348],
	[0.900237, 0.429572, -0.0708152, 0.419237, -0.899154, -0.125455, -0.117562, 0.0831838, -0.989576, -0.626651, 0.878936, 0.0921513],
	[0.987706, -0.128457, -0.0889367, -0.0768318, -0.895317, 0.438602, -0.13611, -0.426477, -0.894234, -0.251977, 0.739483, -0.391989],
	[0.0680163, 0.00881673, 0.99758, -0.83604, -0.544955, 0.0615447, 0.544689, -0.838313, -0.0294872, 0.535942, 0.150095, -0.308295],
	[0.0193947, -0.0519554, 0.998123, -0.82511, -0.564982, -0.0133603, 0.565162, -0.823524, -0.0531056, 0.547909, 0.0982685, -0.275684],
	[-0.0877523, -0.379337, 0.920292, -0.685691, -0.648406, -0.332236, 0.724129, -0.659871, -0.201609, 0.554728, 0.225751, -0.143387],
	[0.96478, -0.0327752, 0.261013, -0.187392, -0.781977, 0.594481, 0.184606, -0.622439, -0.760566, 0.280536, 0.877565, -0.535304],
	[0.99378, 0.0354604, -0.105536, 0.0897718, -0.815883, 0.571208, -0.0658594, -0.577127, -0.813988, -0.198812, 0.907495, -0.537557],
	[1, -1.08438e-05, 2.7151e-06, -9.40124e-06, -0.683175, 0.730259, -6.07175e-06, -0.730261, -0.683176, -0.00144756, 0.829436, -0.554477],
	[-0.989773, -0.142595, -0.00395348, 0.142454, -0.986593, -0.0796393, 0.00745564, -0.0793883, 0.996817, -0.227522, 0.797053, -0.235781],
	[-0.999554, 0.0283758, 0.00946914, -0.019047, -0.847794, 0.529987, 0.0230669, 0.529567, 0.847954, -0.176375, 0.162771, -0.407875],
	[-0.999927, 0.0120468, 6.38398e-05, -0.0120466, -0.999921, 0.000754976, 7.30625e-05, 0.000759339, 0.999995, -0.164479, -0.0575554, -0.519558],
	[-0.999924, -5.94984e-05, 0.0120625, -0.0120525, -0.000754116, -0.999922, 8.17392e-05, -0.999991, 0.000772928, -0.164483, 0.365558, -0.159559],
	[-0.987551, 0.153022, 0.0364372, -0.151647, -0.864614, -0.479008, -0.0417949, -0.478569, 0.877055, 0.244927, 0.81805, 0.115991],
	[-0.999502, -0.0315602, 0.000279214, 0.0304774, -0.962836, 0.268356, -0.00820052, 0.268234, 0.963319, 0.169989, 0.375028, -0.188092],
	[-0.99886, -0.0477241, -0.000202684, 0.0477239, -0.99886, 0.000762925, -0.000238995, 0.000757064, 1, 0.16962, -0.0512638, -0.211436],
	[-0.99886, 0.00020045, -0.047729, 0.0477286, -0.000765034, -0.998861, -0.000236882, -1, 0.000758222, 0.169621, 0.0573577, -0.153265],
]

class Box:
	var x0 := 0.0
	var x1 := 0.0
	var z0 := 0.0
	var z1 := 0.0
	var h := 0.0

class Ramp:
	var cx := 0.0
	var cz := 0.0
	var rot := 0.0
	var L := 1.0
	var w := 1.0
	var H := 1.0
	var quarter := false
	var pw := 1.8
	var c := 1.0
	var s := 0.0

var boxes: Array[Box] = []
var ramps: Array[Ramp] = []

class Rail:
	var ax := 0.0
	var ay := 0.0
	var az := 0.0
	var by := 0.0
	var dx := 0.0
	var dz := 0.0
	var rlen := 1.0

var rails: Array[Rail] = []

# ---- состояние байка ----
var px := SPAWN_X
var pz := SPAWN_Z
var py := 0.0
var yaw := SPAWN_B
var spd := 0.0
var vy := 0.0
var wvx := 0.0
var wvz := 0.0
var mode := GROUND
var th := 0.0
var om := 0.0
var pitch := 0.0
var gp := 0.0
var roll := 0.0
var vy_g := 0.0
var ws := 0.0
var crank := 0.0
var wheel_a := 0.0
var spin_w := 0.0
var spin_acc := 0.0
var nose_acc := 0.0
var air_t := 0.0
var hop_t := 999.0
var mair := SPAWN_B
var take_y := 0.0
var bar_angle := 0.0
var bar_rem := 0.0
var bar_dir := 1.0
var bar_count := 0
var bar_cool := 0.0
var bail_t := 0.0
var tumble := 0.0
var tum_dir := 1.0
var safe_x := SPAWN_X
var safe_z := SPAWN_Z
var safe_b := SPAWN_B
var safe_t := 0.0

# банихоп и толчок ногами
var hop_armed := false
var hop_since := 9.0
var hop_peak := 0.0
var hop_push := 0.0
var kb_hop := false

# руки, тормоз, руление
var WHEELBASE := 0.97
var steer_ang := 0.0
var pitch_w := 0.0
var hand_l_off := false
var hand_r_off := false
var brake_held := false
var hl_amt := 0.0
var hr_amt := 0.0
var noh_t := 0.0
var oneh_t := 0.0
var hint_t := 14.0
var pad_a := false
var pad_start := false
var pad_back := false
var kesc := false

# карта города (city_map.glb) и её карта высот (city_height.bin: uint16, 0.25 м на клетку)
const CITY_SCENE := "res://models/city_map/city_map.glb"
const CITY_HF := "res://models/city_map/city_height.bin"
const HF_X0 := -150.0
const HF_Z0 := -175.0
const HF_CELL := 0.25
const HF_W := 1200
const HF_H := 1400
const HF_BASE := -10.0
const HF_SCALE := 0.01
var hf_ok := false
var hf_data := PackedByteArray()
var city_inst: Node3D

# стили мануала на L (рокет / hang 5), айс пик / туз пик, опо вип / бар
var has_rocket := false
var has_hang5 := false
var rock_amt := 0.0
var hang_amt := 0.0
var gr_style := 0
var tw_opo_count := 0
var bar_opo_count := 0

# экраны меню: 0 главное, 1 настройки, 2 справка
var menu_screen := 0
var settings_panel: PanelContainer
var help_panel: PanelContainer

# камера: сдвиг влево и высота
var k_cam_side := 1.0
var k_cam_h := 1.4

# стойка, свитч/опо, заготовки для рамы и руля
var stance := 1
var stance_btn: Button
var takeoff_fakie := false
var rig_man := 0.0
var whip_amt := 0.0
var steer_axis_M := Vector3(0.0, 0.92, 0.38)
var axis_fork := Vector3(0.0, 1.0, 0.0)
var axis_bars := Vector3(0.0, 1.0, 0.0)
var n_chassis: Node3D
var rear_group: Node3D
var dot_cache: ImageTexture

# футджем вип на земле: нога на колесе, рама крутится, уезжаем фейки
const FJ_DUR := 0.65
var fj_yaw0 := 0.0
var fj_dir := 1.0
var fj_sign := 1.0
var fj_front := Vector2.ZERO

# кранк-гринд: рейла ложится на педальный шатун (слева сам, справа — с зажатым Квадратом)
const CRANK_LAT := 0.13
var BB_X := -0.212
var CRANK_H := 0.122
var gr_kind := 0
var gr_side := 1.0
var gr_lat := 0.158
var gr_h := 0.244

# падение райдера при бейле и приземление на мануал
const RF_COM := Vector3(0.0, 0.85, 0.30)
const RF_R := 0.2
const MANUAL_LAND_MIN := 0.35
var rider_free := false
var rider_home := Transform3D.IDENTITY
var rf_com := Vector3.ZERO
var rf_vel := Vector3.ZERO
var rf_basis := Basis.IDENTITY
var rf_w := Vector3.ZERO
var rf_t := 0.0
var rf_ground_t := 0.0

# запечённый скелет
var rest_local: Array = []
var bone_ix := {}
var sk_idx: Array = []
var skin_fixed := false

# поджатие байка (L в воздухе), выход из слайда
const TUCK_H := 0.2
var tuck_on := false
var tuck_amt := 0.0
var exit_t := 0.0
var exit_yaw := 0.0
var gr_face := 1.0
var gr_fakie := false

# гринд по рейле правыми пегами (у модели пеги только справа)
const PEG_LAT := 0.158
const GRIND_ALIGN := 0.85
var PEG_H := 0.244
var grind_on := true
var gr_rail := 0
var gr_t := 0.0
var gr_dir := 1.0
var gr_spd := 0.0
var gr_time := 0.0
var gr_cool := 0.0
var gr_jump_req := false
var gr_pull := false

# слайд-докрутка 360 (приземление с недокрученным 360 + Треугольник + стик в сторону вращения)
const SPIN_SLIDE_MIN := PI * 1.5
const SPIN_SLIDE_GAP := 0.35
var sl_kind := 0
var sl_rot_rem := 0.0

# диагностика и запасные режимы райдера
var rider_ik := true
var diag_on := true
var diag_text: Array = []
var diag_t := 0.0
var pov := {}
var k_tuck := 0.12
var bar_chicken := false
var chick_count := 0

# модели (glb): велосипед и райдер со скелетом
const BIKE_SCENE := "res://models/bmx/bmx.glb"
const RIDER_SCENE := "res://models/rider/ryder_standing.glb"
const WHEEL_R := 0.264
var FRONT_X := 0.395
var FORK_X := 0.207
var bike_holder: Node3D
var rider_holder: Node3D
var bike_inst: Node3D
var rider_inst: Node3D
var skel: Skeleton3D
var n_fork: Node3D
var n_bars: Node3D
var n_wheel_f: Node3D
var n_wheel_r: Node3D
var n_chain: Node3D
var n_ped_l: Node3D
var n_ped_r: Node3D
var rt := {}
var bb_M := Vector3(0.046, -0.168, 0.212)
var ped_l_rest := Vector3(-0.163, -0.322, 0.211)
var ped_r_rest := Vector3(0.162, -0.014, 0.211)
var bar_pivot_M := Vector3(0.0, 0.298, -0.207)
var grip_rest_R := Vector3(0.279, 0.517, -0.212)
var pelvis_off := Vector3.ZERO
var bones := {}
var blen := {}
var crank_a := 0.0
var crank_w := 0.0
var crank_rem := 0.0
var crank_count := 0
var fj_amt := 0.0
var tw_footjam := false
var fj_count := 0

# слайд на фейки
var sliding := false
var sl_spd := 0.0
var sl_mv := 0.0
var sl_side := 1.0
var sl_steer := 0.0
var sl_t := 0.0

# схема управления: L ноги, R руки, крест — разгон/хоп, круг — вип/бар
var held_L := false
var held_R := false
var held_X := false
var held_O := false
var held_T := false
var held_S := false
var armed_L := false
var armed_R := false
var foot_l_off := false
var foot_r_off := false
var mash_n := 0
var mash_t := 0.0

# трюки
var frame: Node3D
var tw_rem := 0.0
var tw_ang := 0.0
var tw_dir := 1.0
var tw_count := 0
var tw_cool := 0.0
var flip_rem := 0.0
var flip_dir := 1.0
var flip_cool := 0.0
var flip_hold := 0.0
var flip_back := 0
var flip_front := 0
var xup_t := 0.0
var xup_amt := 0.0
var xup_held := false
var noft_t := 0.0
var sup_t := 0.0
var cancan_t := 0.0
var table_t := 0.0
var foot_air_l := false
var foot_air_r := false
var fl_amt := 0.0
var fr_amt := 0.0
var sup_amt := 0.0
var piv_amt := 0.0
var flips_on := true

# настройки физики и анимаций (меню паузы)
const TWEAKS := [
	["jump", "Высота прыжка", 0.5, 2.0, 1.0, 0.05],
	["push_boost", "Сила толчка ногами, м/с", 0.0, 3.5, 1.7, 0.1],
	["push_decay", "Утечка заряда толчка, ед/с", 0.0, 2.0, 0.5, 0.05],
	["hop_win", "Окно банихопа, с", 0.2, 1.0, 0.45, 0.05],
	["gravity", "Гравитация, м/с²", 5.0, 15.0, 9.81, 0.1],
	["max_speed", "Макс. скорость, м/с", 8.0, 25.0, 13.0, 0.5],
	["pedal", "Сила разгона (ноги)", 0.5, 2.5, 1.0, 0.05],
	["drag", "Сопротивление качению", 0.0, 3.0, 1.0, 0.05],
	["steer", "Поворот руля", 0.5, 2.0, 1.0, 0.05],
	["spin", "Скорость вращения в воздухе", 0.5, 2.0, 1.0, 0.05],
	["barspin", "Скорость барспина", 0.5, 2.0, 1.0, 0.05],
	["whip", "Скорость тейлвипа", 0.5, 2.5, 1.0, 0.05],
	["flip", "Скорость сальто", 0.5, 2.0, 1.0, 0.05],
	["anim", "Скорость анимаций райдера", 0.3, 2.5, 1.0, 0.05],
	["combo", "Время до записи комбо, с", 0.5, 4.0, 1.4, 0.1],
	["cam", "Дистанция камеры (меньше = ближе)", 0.25, 1.8, 1.0, 0.05],
	["tuck", "Подтяжка ног (L) — добавка высоты", 0.0, 0.4, 0.12, 0.01],
	["cam_side", "Камера: сдвиг влево, м", -3.0, 3.0, 1.0, 0.1],
	["cam_h", "Камера: высота, м", 0.5, 3.5, 1.4, 0.1],
]
var tweaks := {}
var tweak_sliders := {}
var hop_win := 0.45
var k_jump := 1.0
var k_pedal := 1.0
var k_drag := 1.0
var k_steer := 1.0
var k_spin := 1.0
var k_barspin := 1.0
var k_whip := 1.0
var k_flip := 1.0
var k_anim := 1.0
var k_combo := 1.4
var k_cam := 1.0

# виртуальные кнопки, меню и редактор раскладки
var ctrls := {}
var touch_role := {}
var stick_vec := {"stick": Vector2.ZERO, "stick2": Vector2.ZERO}
var dpad_dir := Vector2.ZERO
var dpad_dig := Vector2.ZERO
var ui_opacity := 0.55
var ui_scale := 1.0
var show_labels := true
var menu_open := false
var edit_mode := false
var edit_sel := ""
var edit_drag := -1
var edit_off := Vector2.ZERO
var menu_panel: PanelContainer
var edit_bar: PanelContainer
var edit_lbl: Label

# ---- ввод ----
var in_lx := 0.0
var in_ly := 0.0
var in_rx := 0.0
var in_ry := 0.0
var kb_lx := 0.0
var kb_ly := 0.0
var kb_rx := 0.0
var kb_ry := 0.0
var pedal_down := {"L": false, "R": false}
var pedal_last := 0
var pedal_kick := 0.0
var pedal_tap := 0.0
var pedal_both_t := 0.0
var pad_l := false
var pad_r := false
var kq := false
var ke := false
var kspace := false
var kr := false

# ---- настройки ----
var assist_bal := true
var assist_land := true
var invert_y := false

# ---- очки ----
var score := 0
var combo_items: Array = []
var combo_pts := 0.0
var combo_idle := 0.0
var has_manual := false
var has_nose := false
var toast_text := ""
var toast_t := 0.0
var toast_good := true

# ---- узлы ----
var root: Node3D
var body: Node3D
var fork: Node3D
var bar_g: Node3D
var rear_w: Node3D
var front_w: Node3D
var cam: Camera3D
var ui: CanvasLayer
var hud: Control
var crank_l: MeshInstance3D
var crank_r: MeshInstance3D
var pedal_l_m: MeshInstance3D
var pedal_r_m: MeshInstance3D
var pelvis: MeshInstance3D
var chest: MeshInstance3D
var torso: MeshInstance3D
var th_l: MeshInstance3D
var th_r: MeshInstance3D
var sh_l: MeshInstance3D
var sh_r: MeshInstance3D
var ua_l: MeshInstance3D
var ua_r: MeshInstance3D
var fa_l: MeshInstance3D
var fa_r: MeshInstance3D
var knee_l: MeshInstance3D
var knee_r: MeshInstance3D
var hand_l: MeshInstance3D
var hand_r: MeshInstance3D
var foot_l: MeshInstance3D
var foot_r: MeshInstance3D
var head_g: Node3D

var rig_ly := 0.0
var rig_head := 0.0
var rig_tors := 0.0
var rig_crouch := 0.0
var rig_steer := 0.0

var cam_yaw := SPAWN_B
var cam_pos := Vector3(0, 3, 15)
var cam_look := Vector3(0, 1, 0)
var acc_t := 0.0

var m_ledge: StandardMaterial3D
var m_ramp: StandardMaterial3D
var m_edge: StandardMaterial3D
var m_red: StandardMaterial3D
var m_dark: StandardMaterial3D
var m_rubber: StandardMaterial3D
var m_metal: StandardMaterial3D
var m_jersey: StandardMaterial3D
var m_pants: StandardMaterial3D
var m_skin: StandardMaterial3D
var m_shoe: StandardMaterial3D
var m_visor: StandardMaterial3D

const POLE_LEG := Vector3(1, 0.15, 0)
const POLE_ARM_L := Vector3(-0.5, 0.25, -1)
const POLE_ARM_R := Vector3(-0.5, 0.25, 1)
var C_VEC := Vector3(-0.574, 0, 0)
var C_VEC_F := Vector3(0.395, 0, 0)


# =====================================================================
# УТИЛИТЫ
# =====================================================================
func damp(a: float, b: float, k: float, dt: float) -> float:
	return a + (b - a) * (1.0 - exp(-k * dt))

func wrap_half(a: float) -> float:
	return a - roundf(a / PI) * PI

func dir_of(a: float) -> Vector2:
	return Vector2(cos(a), -sin(a))

func deadzone(v: Vector2, d: float = 0.14) -> Vector2:
	var m := v.length()
	if m < d:
		return Vector2.ZERO
	return v * ((m - d) / (1.0 - d) / m)

func vp_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func mat(color: String, rough: float = 0.75, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	m.metallic = metal
	return m

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://bmx.cfg") == OK:
		assist_bal = cf.get_value("s", "assist_bal", true)
		assist_land = cf.get_value("s", "assist_land", true)
		invert_y = cf.get_value("s", "invert_y", false)
		show_labels = cf.get_value("s", "show_labels", true)
		ui_opacity = cf.get_value("s", "ui_opacity", 0.55)
		ui_scale = cf.get_value("s", "ui_scale", 1.0)
		flips_on = cf.get_value("s", "flips_on", true)
		rider_ik = cf.get_value("s", "rider_ik", true)
		diag_on = cf.get_value("s", "diag_on", true)
		grind_on = cf.get_value("s", "grind_on", true)
		stance = cf.get_value("s", "stance", 1)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("s", "assist_bal", assist_bal)
	cf.set_value("s", "assist_land", assist_land)
	cf.set_value("s", "invert_y", invert_y)
	cf.set_value("s", "show_labels", show_labels)
	cf.set_value("s", "ui_opacity", ui_opacity)
	cf.set_value("s", "ui_scale", ui_scale)
	cf.set_value("s", "flips_on", flips_on)
	cf.set_value("s", "rider_ik", rider_ik)
	cf.set_value("s", "diag_on", diag_on)
	cf.set_value("s", "grind_on", grind_on)
	cf.set_value("s", "stance", stance)
	cf.save("user://bmx.cfg")


# =====================================================================
# РЕЛЬЕФ
# =====================================================================
func ramp_profile(r: Ramp, t: float) -> float:
	if r.quarter:
		var tt := minf(t, 0.97)
		var k := 1.0 - sqrt(1.0 - tt * tt)
		var km := 1.0 - sqrt(1.0 - 0.97 * 0.97)
		return r.H * minf(1.0, k / km)
	return r.H * pow(t, r.pw)

func terrain_h(x: float, z: float) -> float:
	if hf_ok:
		return map_h(x, z)
	var h := 0.0
	for b in boxes:
		if x >= b.x0 and x <= b.x1 and z >= b.z0 and z <= b.z1 and b.h > h:
			h = b.h
	for r in ramps:
		var dx := x - r.cx
		var dz := z - r.cz
		var lx := dx * r.c - dz * r.s
		var lz := dx * r.s + dz * r.c
		if absf(lz) <= r.w * 0.5 and lx >= -r.L * 0.5 and lx <= r.L * 0.5:
			var v := ramp_profile(r, (lx + r.L * 0.5) / r.L)
			if v > h:
				h = v
	return h

func slope_along(x: float, z: float, b: float) -> float:
	var fx := cos(b) * 0.5
	var fz := -sin(b) * 0.5
	return terrain_h(x + fx, z + fz) - terrain_h(x - fx, z - fz)

func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	# Godot: лицевая сторона — по часовой стрелке. Порядок подбираем под нужную нормаль.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tmp := b
		b = c
		c = tmp
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	tri(st, a, b, c, n)
	tri(st, a, c, d, n)

func ramp_mesh(r: Ramp) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 22
	var hw := r.w * 0.5
	var L := r.L
	for i in range(n):
		var t0 := float(i) / float(n)
		var t1 := float(i + 1) / float(n)
		var x0 := -L * 0.5 + t0 * L
		var x1 := -L * 0.5 + t1 * L
		var h0 := ramp_profile(r, t0)
		var h1 := ramp_profile(r, t1)
		var nrm := Vector3(-(h1 - h0), x1 - x0, 0.0).normalized()
		quad(st, Vector3(x0, h0, -hw), Vector3(x1, h1, -hw), Vector3(x1, h1, hw), Vector3(x0, h0, hw), nrm)
		quad(st, Vector3(x0, 0, hw), Vector3(x1, 0, hw), Vector3(x1, h1, hw), Vector3(x0, h0, hw), Vector3(0, 0, 1))
		quad(st, Vector3(x0, 0, -hw), Vector3(x1, 0, -hw), Vector3(x1, h1, -hw), Vector3(x0, h0, -hw), Vector3(0, 0, -1))
	var hb := ramp_profile(r, 1.0)
	quad(st, Vector3(L * 0.5, 0, -hw), Vector3(L * 0.5, 0, hw), Vector3(L * 0.5, hb, hw), Vector3(L * 0.5, hb, -hw), Vector3(1, 0, 0))
	return st.commit()

func lines_mesh(pts: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for p in pts:
		st.add_vertex(p)
	return st.commit()

func add_lines(pts: PackedVector3Array, pos: Vector3, rot_y: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = lines_mesh(pts)
	mi.material_override = m_edge
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func add_box(cx: float, cz: float, sx: float, sz: float, h: float) -> void:
	var b := Box.new()
	b.x0 = cx - sx * 0.5
	b.x1 = cx + sx * 0.5
	b.z0 = cz - sz * 0.5
	b.z1 = cz + sz * 0.5
	b.h = h
	boxes.append(b)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx, h, sz)
	mi.mesh = bm
	mi.material_override = m_ledge
	mi.position = Vector3(cx, h * 0.5, cz)
	add_child(mi)
	var a := Vector3(-sx * 0.5, -h * 0.5, -sz * 0.5)
	var c := Vector3(sx * 0.5, h * 0.5, sz * 0.5)
	var pts := PackedVector3Array()
	for y in [a.y, c.y]:
		pts.append_array(PackedVector3Array([Vector3(a.x, y, a.z), Vector3(c.x, y, a.z), Vector3(c.x, y, a.z), Vector3(c.x, y, c.z),
			Vector3(c.x, y, c.z), Vector3(a.x, y, c.z), Vector3(a.x, y, c.z), Vector3(a.x, y, a.z)]))
	for xz in [Vector2(a.x, a.z), Vector2(c.x, a.z), Vector2(c.x, c.z), Vector2(a.x, c.z)]:
		pts.append_array(PackedVector3Array([Vector3(xz.x, a.y, xz.y), Vector3(xz.x, c.y, xz.y)]))
	add_lines(pts, mi.position, 0.0)

func add_ramp(cx: float, cz: float, rot: float, L: float, w: float, hh: float, kind: String = "curve", pw: float = 1.8) -> void:
	var r := Ramp.new()
	r.cx = cx
	r.cz = cz
	r.rot = rot
	r.L = L
	r.w = w
	r.H = hh
	r.quarter = (kind == "quarter")
	r.pw = pw
	r.c = cos(rot)
	r.s = sin(rot)
	ramps.append(r)
	var mi := MeshInstance3D.new()
	mi.mesh = ramp_mesh(r)
	mi.material_override = m_ramp
	mi.position = Vector3(cx, 0, cz)
	mi.rotation.y = rot
	add_child(mi)
	var pts := PackedVector3Array()
	var n := 22
	var hw := w * 0.5
	for i in range(n):
		var t0 := float(i) / float(n)
		var t1 := float(i + 1) / float(n)
		var p0 := Vector3(-L * 0.5 + t0 * L, ramp_profile(r, t0), 0)
		var p1 := Vector3(-L * 0.5 + t1 * L, ramp_profile(r, t1), 0)
		for zz in [-hw, hw]:
			pts.append(Vector3(p0.x, p0.y, zz))
			pts.append(Vector3(p1.x, p1.y, zz))
	var hb := ramp_profile(r, 1.0)
	pts.append_array(PackedVector3Array([Vector3(L * 0.5, 0, -hw), Vector3(L * 0.5, hb, -hw), Vector3(L * 0.5, 0, hw), Vector3(L * 0.5, hb, hw),
		Vector3(L * 0.5, hb, -hw), Vector3(L * 0.5, hb, hw), Vector3(-L * 0.5, 0, -hw), Vector3(-L * 0.5, 0, hw)]))
	add_lines(pts, mi.position, rot)

func build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9bc5d9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cfdbe4")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("9bc5d9")
	env.fog_density = 0.0025
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	sun.look_at_from_position(Vector3(-14, 26, 10), Vector3.ZERO, Vector3.UP)
	cam = Camera3D.new()
	cam.far = 400.0
	cam.fov = 62.0
	add_child(cam)
	cam.make_current()

func build_ground() -> void:
	var img := Image.create(256, 256, true, Image.FORMAT_RGBA8)
	img.fill(Color("7b858c"))
	for i in range(1600):
		var c := Color(1, 1, 1, 1) if randf() < 0.5 else Color(0.3, 0.33, 0.36, 1)
		var base := Color("7b858c")
		var col := base.lerp(c, 0.12)
		var x := randi() % 255
		var y := randi() % 255
		img.set_pixel(x, y, col)
		img.set_pixel(x + 1, y, col)
		img.set_pixel(x, y + 1, col)
		img.set_pixel(x + 1, y + 1, col)
	var line := Color("5c666d")
	img.fill_rect(Rect2i(0, 0, 256, 3), line)
	img.fill_rect(Rect2i(0, 253, 256, 3), line)
	img.fill_rect(Rect2i(0, 0, 3, 256), line)
	img.fill_rect(Rect2i(253, 0, 3, 256), line)
	var thin := Color("6c777e")
	img.fill_rect(Rect2i(128, 0, 1, 256), thin)
	img.fill_rect(Rect2i(0, 128, 256, 1), thin)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = tex
	gm.uv1_scale = Vector3(60, 60, 1)
	gm.roughness = 0.9
	gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	var fl := MeshInstance3D.new()
	fl.mesh = pm
	fl.material_override = gm
	add_child(fl)
	# дальние дома для ориентации
	var bms := [mat("55616b"), mat("6d7983"), mat("4a545c")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(26):
		var a := float(i) / 26.0 * TAU
		var r := 100.0 + rng.randf() * 14.0
		var hh := 8.0 + rng.randf() * 22.0
		var ww := 8.0 + rng.randf() * 10.0
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(ww, hh, ww)
		mi.mesh = bm
		mi.material_override = bms[i % 3]
		mi.position = Vector3(cos(a) * r, hh * 0.5, sin(a) * r)
		add_child(mi)

func build_park() -> void:
	m_ledge = mat("9aa3a9")
	m_ramp = mat("8d979e")
	m_edge = StandardMaterial3D.new()
	m_edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_edge.albedo_color = Color("2b3238")
	add_box(-9, -5, 2.6, 3, 0.35)
	add_box(-9, -10, 2.6, 3, 0.6)
	add_box(-9, -15, 2.6, 3, 0.9)
	add_box(6, -8, 2.2, 16, 0.28)
	add_ramp(0, -16, PI / 2, 4.5, 4, 1.3)
	add_ramp(0, -28, PI / 2, 5, 5, 1.1, "curve", 1.4)
	add_box(0, -34.5, 5, 8, 1.1)
	add_ramp(0, -41, -PI / 2, 5, 5, 1.1, "curve", 1.4)
	add_ramp(12, -8, 0, 4.2, 6, 2.2, "quarter")
	add_box(16.5, -8, 4.8, 6, 2.2)
	add_ramp(-16, -30, PI / 2, 4, 3, 1.0)
	add_ramp(-18, -24, -PI / 2, 4, 3, 1.0)
	add_box(20, -30, 4, 4, 0.45)
	add_box(20, -36, 4, 4, 0.75)
	# рейлы: ровная прямо по курсу со старта (пег справа ложится на неё) и наклонная
	add_rail(0.158, 0.55, -1.0, 0.158, 0.55, -11.0)
	add_rail(-5.158, 0.95, 4.0, -5.158, 0.5, -10.0)


# =====================================================================
# БАЙК И РАЙДЕР
# =====================================================================
func make_seg(parent: Node3D, r: float, material: Material, rad: int = 8) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 1.0
	cm.radial_segments = rad
	cm.rings = 1
	var m := MeshInstance3D.new()
	m.mesh = cm
	m.material_override = material
	parent.add_child(m)
	return m

func place_seg(m: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.00001:
		m.visible = false
		return
	m.visible = true
	d = d / l
	var q := Quaternion(Vector3(0, 1, 0), d)
	m.transform = Transform3D(Basis(q) * Basis.from_scale(Vector3(1.0, l, 1.0)), (a + b) * 0.5)

func tube(parent: Node3D, a: Vector3, b: Vector3, r: float, material: Material) -> MeshInstance3D:
	var m := make_seg(parent, r, material)
	place_seg(m, a, b)
	return m

func make_sphere(parent: Node3D, r: float, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	var m := MeshInstance3D.new()
	m.mesh = sm
	m.material_override = material
	m.position = pos
	parent.add_child(m)
	return m

func make_box(parent: Node3D, size: Vector3, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var m := MeshInstance3D.new()
	m.mesh = bm
	m.material_override = material
	m.position = pos
	parent.add_child(m)
	return m

func make_wheel(parent: Node3D, x: float, y: float) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x, y, 0)
	parent.add_child(g)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.24
	tm.outer_radius = 0.36
	tm.rings = 30
	tm.ring_segments = 10
	var tire := MeshInstance3D.new()
	tire.mesh = tm
	tire.material_override = m_rubber
	tire.rotation.x = PI / 2.0
	g.add_child(tire)
	var rm := TorusMesh.new()
	rm.inner_radius = 0.288
	rm.outer_radius = 0.312
	rm.rings = 26
	rm.ring_segments = 6
	var rim := MeshInstance3D.new()
	rim.mesh = rm
	rim.material_override = m_metal
	rim.rotation.x = PI / 2.0
	g.add_child(rim)
	make_sphere(g, 0.05, m_metal)
	for i in range(4):
		var a := float(i) * PI / 4.0
		tube(g, Vector3(cos(a) * 0.3, sin(a) * 0.3, 0), Vector3(-cos(a) * 0.3, -sin(a) * 0.3, 0), 0.007, m_metal)
	return g


func find3d(nm: String) -> Node3D:
	if bike_inst == null:
		return null
	return bike_inst.find_child(nm, true, false) as Node3D

func m_of(n: Node3D) -> Vector3:
	return bike_holder.to_local(n.global_position)

func rest_of(nm: String) -> Transform3D:
	return rt[nm]

func bi(nm: String) -> int:
	return int(bones[nm])


func rest_len(a: String, b: String) -> float:
	return (gb(kx(b), false).origin - gb(kx(a), false).origin).length()

func build_bike() -> void:
	root = Node3D.new()
	add_child(root)
	body = Node3D.new()
	root.add_child(body)
	frame = Node3D.new()
	body.add_child(frame)
	bike_holder = Node3D.new()
	bike_holder.rotation.y = -PI / 2.0
	frame.add_child(bike_holder)
	rider_holder = Node3D.new()
	rider_holder.rotation.y = -PI / 2.0
	body.add_child(rider_holder)
	var bs = load(BIKE_SCENE)
	if bs is PackedScene:
		bike_inst = (bs as PackedScene).instantiate()
		bike_holder.add_child(bike_inst)
		n_fork = find3d("forks_front")
		n_bars = find3d("handlebars")
		n_wheel_f = find3d("wheel_front")
		n_wheel_r = find3d("wheel_rear")
		n_chain = find3d("chainset")
		n_ped_l = find3d("Pedal_l")
		n_ped_r = find3d("Pedal_r")
		var grip := find3d("bargrip")
		var ok := n_fork != null and n_bars != null and n_wheel_f != null and n_wheel_r != null
		ok = ok and n_chain != null and n_ped_l != null and n_ped_r != null and grip != null
		if ok:
			rt["forks_front"] = n_fork.transform
			rt["handlebars"] = n_bars.transform
			rt["wheel_front"] = n_wheel_f.transform
			rt["wheel_rear"] = n_wheel_r.transform
			rt["chainset"] = n_chain.transform
			rt["Pedal_l"] = n_ped_l.transform
			rt["Pedal_r"] = n_ped_r.transform
			var wf := m_of(n_wheel_f)
			var wr := m_of(n_wheel_r)
			var yoff := WHEEL_R - (wf.y + wr.y) * 0.5
			bike_holder.position.y = yoff
			PEG_H = yoff - 0.178
			CRANK_H = yoff - 0.21
			rider_holder.position.y = yoff
			FRONT_X = -wf.z
			C_VEC = Vector3(-wr.z, 0, 0)
			C_VEC_F = Vector3(-wf.z, 0, 0)
			WHEELBASE = absf(wf.z - wr.z)
			FORK_X = -m_of(n_fork).z
			bb_M = m_of(n_chain)
			BB_X = -bb_M.z
			ped_l_rest = m_of(n_ped_l)
			ped_r_rest = m_of(n_ped_r)
			bar_pivot_M = m_of(n_bars)
			grip_rest_R = m_of(grip)
			# задняя часть (рама, заднее колесо, кривошип) отдельной группой — для випа
			var par_n := n_chain.get_parent() as Node3D
			rear_group = Node3D.new()
			par_n.add_child(rear_group)
			n_chassis = find3d("chassis")
			if n_chassis != null:
				for rn in [n_chassis, n_wheel_r, n_chain]:
					(rn as Node3D).reparent(rear_group, true)
			else:
				rear_group.queue_free()
				rear_group = null
			# ось рулевой колонки: от колеса вдоль вилки вверх
			steer_axis_M = (m_of(n_fork) - wf).normalized()
			var hbs := bike_holder.global_transform.basis
			var pfn := n_fork.get_parent() as Node3D
			axis_fork = (pfn.global_transform.basis.inverse() * (hbs * steer_axis_M)).normalized()
			var pbn := n_bars.get_parent() as Node3D
			axis_bars = (pbn.global_transform.basis.inverse() * (hbs * steer_axis_M)).normalized()
		else:
			push_warning("В bmx.glb не найдены нужные узлы")
			n_fork = null
	else:
		push_warning("Не найден " + BIKE_SCENE)
	if bike_inst == null or n_fork == null:
		var fb := make_box(frame, Vector3(1.0, 0.3, 0.12), mat("e64a37"), Vector3(0.0, 0.4, 0.0))
		fb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var rs = load(RIDER_SCENE)
	if rs is PackedScene:
		rider_inst = (rs as PackedScene).instantiate()
		rider_holder.add_child(rider_inst)
		var sks := rider_inst.find_children("*", "Skeleton3D", true, false)
		if sks.size() > 0:
			skel = sks[0] as Skeleton3D
		for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			m3.extra_cull_margin = 2.0
			m3.custom_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
			m3.visible = true
		if skel != null:
			init_rider()
	else:
		push_warning("Не найден " + RIDER_SCENE)
	rider_home = rider_holder.transform
	if n_fork == null:
		skel = null


func init_rider() -> void:
	bake_init()
	sk_idx.clear()
	for k in range(BONE_NAMES.size()):
		sk_idx.append(skel.find_bone(String(BONE_NAMES[k])))
	for nm in ["Pelvis", "Spine", "Spine1", "Neck", "Head", "L_UpperArm", "L_ForeArm", "L_Hand",
			"R_UpperArm", "R_ForeArm", "R_Hand", "L_Thigh", "L_Calf", "L_Foot", "L_Toe0",
			"R_Thigh", "R_Calf", "R_Foot", "R_Toe0"]:
		if int(sk_idx[kx(nm)]) < 0:
			push_warning("В скелете райдера нет кости " + nm)
			skel = null
			return
	blen["sp1"] = rest_len("Spine", "Spine1")
	blen["sp2"] = rest_len("Spine1", "Neck")
	blen["neck"] = rest_len("Neck", "Head")
	blen["thigh"] = rest_len("L_Thigh", "L_Calf")
	blen["calf"] = rest_len("L_Calf", "L_Foot")
	blen["uarm"] = rest_len("L_UpperArm", "L_ForeArm")
	blen["farm"] = rest_len("L_ForeArm", "L_Hand")
	var ppos := gb(kx("Pelvis"), false).origin
	pelvis_off = rider_holder.to_local(skel.global_transform * ppos)
	# если импортёр отдал пустые bind-позы скина (бывает в сборке), подставляем запечённые
	for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.skin == null:
			continue
		var zero_n := 0
		for k in range(m3.skin.get_bind_count()):
			var bp := m3.skin.get_bind_pose(k)
			if bp.origin.length() < 0.00001 and (bp.basis.x - Vector3(1, 0, 0)).length() < 0.0001:
				zero_n += 1
		if zero_n >= 20:
			var ns := Skin.new()
			for k in range(BONE_NAMES.size()):
				var m: Array = BONE_IBM[k]
				var bs := Basis(Vector3(float(m[0]), float(m[1]), float(m[2])), Vector3(float(m[3]), float(m[4]), float(m[5])), Vector3(float(m[6]), float(m[7]), float(m[8])))
				ns.add_named_bind(String(BONE_NAMES[k]), Transform3D(bs, Vector3(float(m[9]), float(m[10]), float(m[11]))))
			m3.skin = ns
			skin_fixed = true

func kx(nm: String) -> int:
	return int(bone_ix[nm])

func bake_init() -> void:
	rest_local.clear()
	bone_ix.clear()
	for k in range(BONE_NAMES.size()):
		var r: Array = BONE_REST[k]
		var q := Quaternion(float(r[3]), float(r[4]), float(r[5]), float(r[6]))
		var bs := Basis(q) * Basis.from_scale(Vector3(float(r[7]), float(r[8]), float(r[9])))
		rest_local.append(Transform3D(bs, Vector3(float(r[0]), float(r[1]), float(r[2]))))
		bone_ix[BONE_NAMES[k]] = k

func gb(k: int, use_pov: bool) -> Transform3D:
	var bs: Basis = rest_local[k].basis
	if use_pov and pov.has(k):
		bs = pov[k]
	var rl: Transform3D = rest_local[k]
	var t := Transform3D(bs, rl.origin)
	var p: int = BONE_PARENT[k]
	if p < 0:
		return t
	return gb(p, use_pov) * t

func apply_pose() -> void:
	var gd := {}
	for k in range(BONE_NAMES.size()):
		var i: int = sk_idx[k]
		if i >= 0:
			gd[i] = gb(k, true)
	for k in range(BONE_NAMES.size()):
		var i: int = sk_idx[k]
		if i < 0:
			continue
		var g: Transform3D = gd[i]
		var loc := g
		var p := skel.get_bone_parent(i)
		if p >= 0 and gd.has(p):
			var pg: Transform3D = gd[p]
			loc = pg.affine_inverse() * g
		skel.set_bone_pose_position(i, loc.origin)
		skel.set_bone_pose_rotation(i, loc.basis.orthonormalized().get_rotation_quaternion())
		skel.set_bone_pose_scale(i, loc.basis.get_scale())


func bpos(nm: String) -> Vector3:
	return gb(kx(nm), true).origin


func set_bone_global_basis(k: int, nb: Basis) -> void:
	var p: int = BONE_PARENT[k]
	var pb := Basis.IDENTITY
	if p >= 0:
		pb = gb(p, true).basis
	pov[k] = (pb.inverse() * nb).orthonormalized()


func aim_bone(nm: String, child: String, target: Vector3) -> void:
	var k := kx(nm)
	var gp := gb(k, true)
	var cp := gb(kx(child), true)
	var cur := cp.origin - gp.origin
	var want := target - gp.origin
	if cur.length() < 0.0001 or want.length() < 0.0001:
		return
	var q := Quaternion(cur.normalized(), want.normalized())
	set_bone_global_basis(k, Basis(q) * gp.basis)


func twist_bone(nm: String, axis: Vector3, ang: float) -> void:
	var k := kx(nm)
	var gp := gb(k, true)
	set_bone_global_basis(k, Basis(axis.normalized(), ang) * gp.basis)

func pedal_pos(right: bool, a: float) -> Vector3:
	var rest := ped_r_rest if right else ped_l_rest
	var rel := rest - bb_M
	return Vector3(rest.x, bb_M.y + rel.y * cos(a) - rel.z * sin(a), bb_M.z + rel.y * sin(a) + rel.z * cos(a))

func foot_off_target(side: float, other_amt: float, sup: float, hip: Vector3) -> Vector3:
	var can := hip + Vector3(-side * 0.12, -0.35, -0.45)
	var tuck := hip + Vector3(side * 0.14, -0.45, 0.30)
	var ext := hip + Vector3(side * 0.12, -0.05, 0.93)
	var both := tuck.lerp(ext, sup)
	return can.lerp(both, clampf(other_amt, 0.0, 1.0))

func leg_ik(prefix: String, side: float, ankle_m: Vector3, toe_m: Vector3, to_skel: Transform3D) -> void:
	var thigh := prefix + "_Thigh"
	var calf := prefix + "_Calf"
	var foot := prefix + "_Foot"
	var toe := prefix + "_Toe0"
	var pole := to_skel.basis * Vector3(side * 0.25, 0.1, -1.0)
	var res: Array = ik2(bpos(thigh), to_skel * ankle_m, float(blen["thigh"]), float(blen["calf"]), pole)
	var j: Vector3 = res[0]
	var e: Vector3 = res[1]
	aim_bone(thigh, calf, j)
	aim_bone(calf, foot, e)
	aim_bone(foot, toe, to_skel * toe_m)

func arm_ik(prefix: String, side: float, grip_m: Vector3, to_skel: Transform3D) -> void:
	var up := prefix + "_UpperArm"
	var fa := prefix + "_ForeArm"
	var hd := prefix + "_Hand"
	var pole := to_skel.basis * Vector3(side * 0.7, -0.4, 0.3)
	var res: Array = ik2(bpos(up), to_skel * grip_m, float(blen["uarm"]), float(blen["farm"]), pole)
	var j: Vector3 = res[0]
	var e: Vector3 = res[1]
	aim_bone(up, fa, j)
	aim_bone(fa, hd, e)


func pose_rider() -> void:
	var tuck_off := Vector3(0.0, TUCK_H * tuck_amt, 0.0)
	var hy := 0.68 - rig_crouch * 0.22 - rig_man * 0.14
	var hz := 0.36 - rig_ly * 0.18 + rig_man * 0.12
	var hip := Vector3(0.0, hy, hz)
	var ta := 0.8 + rig_ly * 0.35 + rig_crouch * 0.3 + tuck_amt * 0.15
	rider_inst.position = hip - pelvis_off
	pov.clear()
	var to_skel := skel.global_transform.affine_inverse() * rider_holder.global_transform
	var up_s := (to_skel.basis * Vector3.UP).normalized()
	# позвоночник: наклон вперёд, скрутка, голова
	var a1 := ta * 0.55
	var s1 := hip + Vector3(0.0, cos(a1), -sin(a1)) * float(blen["sp1"])
	aim_bone("Spine", "Spine1", to_skel * s1)
	var nk := s1 + Vector3(0.0, cos(ta), -sin(ta)) * float(blen["sp2"])
	aim_bone("Spine1", "Neck", to_skel * nk)
	twist_bone("Spine1", up_s, rig_tors * 0.5)
	var hd_dir := (to_skel.basis * Vector3(0.0, cos(ta * 0.35), -sin(ta * 0.35))).normalized()
	aim_bone("Neck", "Head", bpos("Neck") + hd_dir * float(blen["neck"]))
	# голова: смотрит вперёд (запечённая ориентация), поворот только по взгляду
	var h0 := gb(kx("Head"), false).basis
	set_bone_global_basis(kx("Head"), Basis(up_s, rig_head) * h0)
	# ноги на педалях (при поджатии байк поднят вместе с педалями)
	var ped_r := pedal_pos(true, crank_a) + tuck_off
	var ped_l := pedal_pos(false, crank_a) + tuck_off
	var ank_r := ped_r + Vector3(0.0, 0.09, 0.12)
	var ank_l := ped_l + Vector3(0.0, 0.09, 0.12)
	var toe_r := ped_r + Vector3(0.0, 0.05, -0.04)
	var toe_l := ped_l + Vector3(0.0, 0.05, -0.04)
	# вип: ноги убираются с педалей, пока рама прокручивается
	var wt := whip_amt
	var tk_r := hip + Vector3(0.14, -0.45, 0.25)
	var tk_l := hip + Vector3(-0.14, -0.45, 0.25)
	ank_r = ank_r.lerp(tk_r, wt)
	toe_r = toe_r.lerp(tk_r + Vector3(0.0, -0.04, -0.15), wt)
	ank_l = ank_l.lerp(tk_l, wt)
	toe_l = toe_l.lerp(tk_l + Vector3(0.0, -0.04, -0.15), wt)
	# рокет менуал: ноги на заднем пеге/оси, hang 5: на переднем
	var rp_m := Vector3(PEG_LAT, -0.155, -C_VEC.x)
	var rl_m := Vector3(-0.11, -0.155, -C_VEC.x)
	var fp_m := Vector3(PEG_LAT, -0.155, -FRONT_X)
	var fl_m := Vector3(-0.11, -0.155, -FRONT_X)
	ank_r = ank_r.lerp(rp_m + Vector3(0.0, 0.09, 0.12), rock_amt)
	toe_r = toe_r.lerp(rp_m + Vector3(0.0, 0.05, -0.04), rock_amt)
	ank_l = ank_l.lerp(rl_m + Vector3(0.0, 0.09, 0.12), rock_amt)
	toe_l = toe_l.lerp(rl_m + Vector3(0.0, 0.05, -0.04), rock_amt)
	ank_r = ank_r.lerp(fp_m + Vector3(0.0, 0.09, 0.12), hang_amt)
	toe_r = toe_r.lerp(fp_m + Vector3(0.0, 0.05, -0.04), hang_amt)
	ank_l = ank_l.lerp(fl_m + Vector3(0.0, 0.09, 0.12), hang_amt)
	toe_l = toe_l.lerp(fl_m + Vector3(0.0, 0.05, -0.04), hang_amt)
	# футджем: правая нога упирается в переднюю покрышку
	ank_r = ank_r.lerp(Vector3(0.10, 0.27, -0.30), fj_amt)
	toe_r = toe_r.lerp(Vector3(0.10, 0.22, -0.45), fj_amt)
	leg_ik("R", 1.0, ank_r, toe_r, to_skel)
	leg_ik("L", -1.0, ank_l, toe_l, to_skel)
	# руки на грипсах (во время бара и випа отпускают руль)
	var rot := Basis(steer_axis_M, rig_steer + bar_angle + xup_amt * 1.5)
	var grip_r := bar_pivot_M + rot * (grip_rest_R - bar_pivot_M) + tuck_off
	var grip_l_rest := Vector3(-grip_rest_R.x, grip_rest_R.y, grip_rest_R.z)
	var grip_l := bar_pivot_M + rot * (grip_l_rest - bar_pivot_M) + tuck_off
	grip_r += Vector3(0.25 * hr_amt, 0.40 * hr_amt, 0.05 * hr_amt)
	grip_l += Vector3(-0.25 * hl_amt, 0.40 * hl_amt, 0.05 * hl_amt)
	arm_ik("R", 1.0, grip_r, to_skel)
	arm_ik("L", -1.0, grip_l, to_skel)
	apply_pose()

func ik2(A: Vector3, T: Vector3, l1: float, l2: float, pole: Vector3) -> Array:
	var d := T - A
	var dist := maxf(d.length(), 0.05)
	d = d / dist
	var maxd := l1 + l2 - 0.002
	if dist > maxd:
		dist = maxd
	var E := A + d * dist
	var a := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var p := pole - d * pole.dot(d)
	if p.length_squared() < 0.000001:
		p = Vector3(0, 0, 1)
	p = p.normalized()
	var J := A + d * a + p * h
	return [J, E]


# =====================================================================
# ОЧКИ
# =====================================================================
func show_toast(text: String, good: bool) -> void:
	toast_text = text
	toast_good = good
	toast_t = 1.5

func add_trick(trick_name: String, pts: float) -> void:
	combo_items.append(trick_name)
	combo_pts += pts
	combo_idle = 0.0

func combo_mult() -> float:
	var u := {}
	for it in combo_items:
		u[it] = true
	return 1.0 + 0.25 * float(u.size() - 1)

func reset_combo() -> void:
	combo_items = []
	combo_pts = 0.0
	combo_idle = 0.0
	has_manual = false
	has_nose = false
	has_rocket = false
	has_hang5 = false

func bank_combo() -> void:
	if combo_items.is_empty():
		return
	var total := int(roundf(combo_pts * combo_mult()))
	score += total
	show_toast("+%d · %s" % [total, " + ".join(PackedStringArray(combo_items))], true)
	reset_combo()

func spin_name(n: int) -> String:
	var d := n * 180
	if d == 360:
		return "360 · треха"
	return str(d)

func spin_pts(n: int) -> float:
	var arr := [0.0, 150.0, 400.0, 800.0, 1400.0, 2200.0, 3200.0]
	var v: float = arr[mini(n, 6)]
	return v * (2.0 if n > 6 else 1.0)


# =====================================================================
# ФИЗИКА
# =====================================================================
func bail(msg: String) -> void:
	if mode == BAIL:
		return
	if mode == GROUND:
		var f := dir_of(yaw)
		var sl := slope_along(px, pz, yaw)
		var ca := 1.0 / sqrt(1.0 + sl * sl)
		wvx = f.x * spd * ca
		wvz = f.y * spd * ca
		vy = maxf(vy_g, 0.0)
	mode = BAIL
	bail_t = 0.0
	sliding = false
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	tum_dir = -1.0 if randf() < 0.5 else 1.0
	tumble = 0.0
	th = 0.0
	om = 0.0
	nose_acc = 0.0
	hop_armed = false
	hop_push = 0.0
	show_toast("БЕЙЛ · " + msg, false)
	reset_combo()
	start_rider_fall()

func respawn(full: bool) -> void:
	if rider_free:
		rider_free = false
		rider_holder.reparent(body, false)
		rider_holder.transform = rider_home
	var x0 := SPAWN_X
	var z0 := SPAWN_Z
	var b0 := SPAWN_B
	if not full:
		x0 = safe_x
		z0 = safe_z
		b0 = safe_b
	px = x0
	pz = z0
	yaw = b0
	py = terrain_h(x0, z0)
	spd = 0.0
	vy = 0.0
	wvx = 0.0
	wvz = 0.0
	mode = GROUND
	th = 0.0
	om = 0.0
	pitch = 0.0
	pitch_w = 0.0
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	xup_amt = 0.0
	sliding = false
	crank_rem = 0.0
	gp = 0.0
	roll = 0.0
	vy_g = 0.0
	ws = 0.0
	spin_w = 0.0
	spin_acc = 0.0
	nose_acc = 0.0
	air_t = 0.0
	tumble = 0.0
	bar_angle = 0.0
	bar_rem = 0.0
	if full:
		safe_x = SPAWN_X
		safe_z = SPAWN_Z
		safe_b = SPAWN_B
		reset_combo()
	hop_armed = false
	hop_peak = 0.0
	hop_push = 0.0
	cam_yaw = b0
	cam_pos = Vector3(x0 - cos(b0) * 5.0, 3.0, z0 + sin(b0) * 5.0)

func start_air(nx: float, nz: float, y: float) -> void:
	mode = AIR
	px = nx
	pz = nz
	py = y
	air_t = 0.0
	hop_t = 999.0
	spin_acc = 0.0
	take_y = y
	bar_count = 0
	bar_cool = 0.0
	var vh := Vector2(wvx, wvz).length()
	mair = atan2(-wvz, wvx) if vh > 0.5 else yaw
	var f0 := dir_of(yaw)
	takeoff_fakie = vh > 1.0 and (wvx * f0.x + wvz * f0.y) < 0.0
	spin_w = -in_rx * 5.5 if absf(in_rx) > 0.3 else 0.0
	nose_acc = 0.0
	pitch = gp + th
	pitch_w = 0.0
	noh_t = 0.0
	oneh_t = 0.0
	om = 0.0
	tw_rem = 0.0
	tw_ang = 0.0
	tw_count = 0
	tw_cool = 0.0
	flip_rem = 0.0
	flip_cool = 0.0
	flip_hold = 0.0
	flip_back = 0
	flip_front = 0
	xup_t = 0.0
	noft_t = 0.0
	sup_t = 0.0
	cancan_t = 0.0
	table_t = 0.0
	foot_air_l = false
	foot_air_r = false
	crank_rem = 0.0
	crank_count = 0
	fj_count = 0
	tw_footjam = false
	chick_count = 0
	bar_chicken = false
	tw_opo_count = 0
	bar_opo_count = 0

func pop_hop(power: float) -> void:
	var f := dir_of(yaw)
	var sl := slope_along(px, pz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	# толчок ногами: накопленный заряд от нажатий L/R добавляет скорость прыжка
	if held_X:
		hop_push = maxf(hop_push, 1.8)
	var boost := clampf(hop_push / PUSH_MAX, 0.0, 1.0) * PUSH_BOOST
	# акселерейт: стик вниз-вверх и долбёжка крестом даёт ещё и ускорение
	if mash_n >= 3:
		add_trick("Акселерейт", 60.0)
		show_toast("Акселерейт!", true)
	mash_n = 0
	vy = (2.5 + 2.4 * power + boost + maxf(vy_g, 0.0) * 0.5) * k_jump
	wvx = f.x * spd * ca
	wvz = f.y * spd * ca
	start_air(px, pz, py + 0.001)
	pitch = gp + th * 0.8
	pitch_w = 0.0
	hop_t = 0.0
	th = 0.0
	om = 0.0
	rig_crouch = -0.4 - 0.25 * (boost / PUSH_BOOST)
	hop_push = 0.0
	if boost > 0.35:
		show_toast("Высокий банихоп!", true)

func land_now(nx: float, nz: float, hN: float) -> void:
	px = nx
	pz = nz
	py = hN
	var f := dir_of(yaw)
	var sl := slope_along(nx, nz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	var gpn := atan(sl)
	var v_along := wvx * f.x + wvz * f.y
	var vh := Vector2(wvx, wvz).length()
	var m := atan2(-wvz, wvx)
	var e_face := absf(wrap_half(yaw - m))
	if flip_rem != 0.0 and absf(flip_rem) < 0.45:
		pitch -= TAU * flip_dir
		if flip_dir > 0.0:
			flip_back += 1
		else:
			flip_front += 1
		flip_rem = 0.0
	var err := pitch - gpn
	var vn := (-sl * v_along + vy) / sqrt(1.0 + sl * sl)
	var impact := maxf(0.0, -vn)
	# недокрученный 360 + Треугольник + правый стик в сторону вращения: докрутим слайдом
	var spin_abs := absf(spin_acc)
	var rescue := false
	if held_T and vh > 1.5 and spin_abs >= SPIN_SLIDE_MIN and spin_abs <= TAU - SPIN_SLIDE_GAP:
		if absf(in_rx) > 0.4 and in_rx * spin_acc < 0.0:
			rescue = true
	var why := ""
	if vh > 1.5 and e_face > 0.7 and not rescue:
		why = "боком"
	elif err < -1.05:
		why = "через руль"
	elif err > 1.05:
		why = "назад через заднее"
	elif impact > 13.5:
		why = "слишком жёстко"
	var stick_ok := (err > 0.0 and in_ly < -0.4) or (err < 0.0 and in_ly > 0.4)
	if why == "" and absf(err) > MANUAL_LAND_MIN and not stick_ok:
		why = "не удержал мануал"
	if why == "" and tw_rem > 0.35:
		why = "посреди тейлвипа"
	if why != "":
		py = hN
		bail("приземление " + why)
		return
	mode = GROUND
	spd = v_along / ca * (1.0 - 0.25 * sin(minf(e_face, 1.2)))
	th = clampf(err, -1.1, 1.0) if (absf(err) > 0.12 and stick_ok) else 0.0
	om = 0.0
	gp = gpn
	pitch = gpn + th
	vy_g = 0.0
	vy = 0.0
	ws = spd
	rig_crouch = clampf(impact / 9.0, 0.0, 1.0) * 0.9
	var air := air_t
	var n := int(roundf(absf(spin_acc) / PI))
	if air > 0.25:
		if n >= 1:
			var opo := signf(spin_acc) != float(stance)
			var snm := spin_name(n)
			var spts := spin_pts(n)
			if opo:
				snm = "Опо " + snm
				spts *= 1.25
			add_air_trick(snm, spts)
		if bar_count > 0:
			add_air_trick("Барспин ×%d" % bar_count if bar_count > 1 else "Барспин", 100.0 * bar_count)
		if bar_opo_count > 0:
			add_air_trick("Опо бар ×%d" % bar_opo_count if bar_opo_count > 1 else "Опо бар", 130.0 * bar_opo_count)
		if chick_count > 0:
			add_trick("Чикенбар ×%d" % chick_count if chick_count > 1 else "Чикенбар", 220.0 * chick_count)
		if air > 0.8:
			add_trick("Эйр %.1fс" % air, roundf(air * 60.0))
		if hN - take_y > 0.3:
			add_trick("На препятствие", 80.0)
		if tw_count > 0:
			add_air_trick("Вип" + (" ×%d" % tw_count if tw_count > 1 else ""), 350.0 * tw_count)
		if tw_opo_count > 0:
			add_air_trick("Опо вип" + (" ×%d" % tw_opo_count if tw_opo_count > 1 else ""), 420.0 * tw_opo_count)
		if fj_count > 0:
			add_air_trick("Футджем вип" + (" ×%d" % fj_count if fj_count > 1 else ""), 420.0 * fj_count)
		if crank_count > 0:
			add_air_trick("Кренкфлип" + (" ×%d" % crank_count if crank_count > 1 else ""), 260.0 * crank_count)
		if flip_back > 0:
			add_air_trick("Бэкфлип" + (" ×%d" % flip_back if flip_back > 1 else ""), 500.0 * flip_back)
		if flip_front > 0:
			add_air_trick("Фронтфлип" + (" ×%d" % flip_front if flip_front > 1 else ""), 450.0 * flip_front)
		if xup_t > 0.3:
			add_air_trick("Икс-ап", 90.0)
	noh_t = 0.0
	oneh_t = 0.0
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	crank_rem = 0.0
	if rescue:
		start_spin_slide(TAU - spin_abs, signf(spin_acc), m, vh)
	if not combo_items.is_empty():
		combo_idle = 0.0
	bar_angle = 0.0
	bar_rem = 0.0

func ground_step(dt: float) -> void:
	if sliding:
		slide_step(dt)
		return
	# чикенбар: руль крутится на земле, пока переднее колесо поднято
	bar_cool -= dt
	if bar_rem > 0.0:
		var bd := minf(bar_rem, 18.0 * k_barspin * dt)
		bar_angle += bd * bar_dir
		bar_rem -= bd
		if bar_rem <= 0.0:
			bar_cool = 0.25
			bar_angle = 0.0
			if bar_chicken:
				add_trick("Чикенбар", 220.0)
				show_toast("Чикенбар!", true)
			bar_chicken = false
	# плавный доворот после выхода из слайда
	if exit_t > 0.0:
		exit_t -= dt
		yaw += wrapf(exit_yaw - yaw, -PI, PI) * (1.0 - exp(-16.0 * dt))
	var f := dir_of(yaw)
	var sl := slope_along(px, pz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	var sa := sl * ca
	spd -= G * sa * dt
	var ly := in_ly
	# банихоп: потянул назад, затем резко вперёд
	if ly < -0.55:
		hop_since = 0.0
		hop_armed = true
	else:
		hop_since += dt
		if hop_since > hop_win:
			hop_armed = false
			hop_peak = 0.0
	if hop_armed:
		hop_peak = maxf(hop_peak, th)
		# толчок ногами: нажатия педалей при отведённом весе копят заряд
		hop_push = minf(hop_push + pedal_tap, PUSH_MAX)
		hop_push = maxf(0.0, hop_push - PUSH_DECAY * dt)
	else:
		hop_push = 0.0
	pedal_tap = 0.0
	if kb_hop:
		kb_hop = false
		pop_hop(0.55)
		return
	if hop_armed and ly > 0.35 and hop_since < hop_win and th < 0.95:
		var power := clampf(0.25 + hop_peak / 0.6 * 0.75, 0.25, 1.0)
		hop_armed = false
		hop_peak = 0.0
		pop_hop(power)
		return
	# мануал как балансировка перевёрнутого маятника
	var lean := -ly
	var BAL := 0.55
	var K := 7.0 * (0.5 if assist_bal else 1.0)
	var sgn := 0.0
	if absf(th) > 0.0001:
		sgn = signf(th)
	elif lean > 0.0:
		sgn = 1.0
	elif lean < 0.0:
		sgn = -1.0
	if sgn == 0.0:
		th = 0.0
		om = 0.0
	else:
		var acc := K * (th - sgn * BAL) + 13.0 * lean - 1.8 * om
		if absf(th) <= 0.0001 and sgn * acc <= 0.0:
			th = 0.0
			om = 0.0
		else:
			om += acc * dt
			var nt := th + om * dt
			if nt * sgn < 0.0:
				th = 0.0
				om = 0.0
			else:
				th = nt
	if th > 1.3:
		bail("мануал: перевернулся назад")
		return
	if th < -1.2:
		bail("перелетел через руль")
		return
	# разгон: поочерёдные нажатия L/R; обе вместе — тормоз
	if absf(th) < 0.4 and pedal_kick > 0.0:
		var room := (1.0 - clampf(spd / MAXS, 0.0, 1.0)) if spd >= 0.0 else 1.0
		spd += pedal_kick * room * k_pedal
	pedal_kick = 0.0
	if (pedal_both_t > 0.25 or brake_held) and not hop_armed:
		var br := 9.0 * dt
		spd = maxf(0.0, spd - br) if spd > 0.0 else minf(0.0, spd + br)
	var drag := (0.3 + 0.008 * spd * spd) * k_drag * dt
	spd = maxf(0.0, spd - drag) if spd > 0.0 else minf(0.0, spd + drag)
	spd = clampf(spd, -8.0, MAXS)
	# руление: кинематическая модель велосипеда (колёсная база, угол руля)
	var hand_k := 1.0
	if hand_l_off and hand_r_off:
		hand_k = 0.15
	elif hand_l_off or hand_r_off:
		hand_k = 0.55
	var slow := 0.6 if absf(th) > 0.1 else 1.0
	steer_ang = -in_lx * 0.6 / (1.0 + absf(spd) * 0.14) * hand_k * k_steer
	var yaw_rate := spd * tan(steer_ang) / WHEELBASE * slow
	yaw += yaw_rate * dt
	# ноуз-пивот
	if th < -0.25:
		spin_w = clampf(spin_w + (-in_rx * 19.0 - spin_w * 2.0) * dt, -11.0, 11.0)
		var dB := spin_w * dt
		if dB != 0.0:
			var cx := px + f.x * FRONT_X
			var cz := pz + f.y * FRONT_X
			yaw += dB
			nose_acc += dB
			var f2 := dir_of(yaw)
			px = cx - f2.x * FRONT_X
			pz = cz - f2.y * FRONT_X
		spd *= exp(-0.9 * dt)
	else:
		spin_w = 0.0
	if th > -0.12 and nose_acc != 0.0:
		var nn := int(roundf(absf(nose_acc) / PI))
		if nn >= 1:
			add_trick("Ноуз-пивот %d" % (nn * 180), roundf(spin_pts(nn) * 0.8))
		nose_acc = 0.0
	f = dir_of(yaw)
	# движение
	var step_h := spd * ca * dt
	var nx := px + f.x * step_h
	var nz := pz + f.y * step_h
	var hN := maxf(terrain_h(nx, nz), rail_wall(nx, nz))
	if hN > py + 0.38:
		if absf(spd) > 8.0:
			bail("врезался в препятствие")
			return
		spd = -spd * 0.3 if absf(spd) > 1.5 else 0.0
		vy_g = 0.0
		return
	var y_free := py + maxf(vy_g, 0.0) * dt - 0.5 * G * dt * dt
	if hN < y_free - 0.012 and (vy_g > 0.6 or py - hN > 0.15):
		wvx = f.x * spd * ca
		wvz = f.y * spd * ca
		vy = vy_g if vy_g > 0.6 else minf(vy_g, 0.0)
		start_air(nx, nz, maxf(hN, y_free))
		return
	vy_g = damp(vy_g, (hN - py) / dt, 60.0, dt)
	px = nx
	pz = nz
	py = hN
	if absf(px) > LIM:
		px = clampf(px, -LIM, LIM)
		spd *= -0.3
	if absf(pz) > LIM:
		pz = clampf(pz, -LIM, LIM)
		spd *= -0.3
	gp = damp(gp, atan(sl), 25.0, dt)
	pitch = gp + th
	ws = spd
	roll = damp(roll, clampf(-atan(spd * yaw_rate / G), -0.6, 0.6), 8.0, dt)
	safe_t += dt
	if safe_t > 0.7 and absf(sl) < 0.12 and absf(th) < 0.05 and absf(spd) > 0.3:
		safe_x = px
		safe_z = pz
		safe_b = yaw
		safe_t = 0.0

func air_step(dt: float) -> void:
	air_t += dt
	hop_t += dt
	var gm := 1.0
	if tuck_on and vy > 0.0:
		gm = 1.0 - k_tuck
	vy -= G * gm * dt
	var a := -in_rx * 19.0 * k_spin - spin_w * 1.6
	var hh := py - terrain_h(px, pz)
	if assist_land and vy < 0.0:
		var w := clampf((1.5 - hh) / 1.0, 0.0, 1.0) * (1.0 - 0.85 * absf(in_rx))
		if w > 0.0:
			var e := wrap_half(yaw - mair)
			a += w * (-e * 40.0 - spin_w * 7.0)
	spin_w = clampf(spin_w + a * dt, -13.0 * k_spin, 13.0 * k_spin)
	var dB := spin_w * dt
	yaw += dB
	spin_acc += dB
	# барспин
	bar_cool -= dt
	if bar_rem > 0.0:
		var d := minf(bar_rem, 18.0 * k_barspin * dt)
		bar_angle += d * bar_dir
		bar_rem -= d
		if bar_rem <= 0.0:
			if bar_chicken:
				chick_count += 1
			elif bar_dir * float(stance) < 0.0:
				bar_opo_count += 1
			else:
				bar_count += 1
			bar_chicken = false
			bar_cool = 0.25
			bar_angle = 0.0
	# тейлвип (Треугольник в воздухе)
	if tw_rem > 0.0:
		var dw := minf(tw_rem, 13.0 * k_whip * dt)
		tw_ang += dw * tw_dir
		tw_rem -= dw
		if tw_rem <= 0.0:
			tw_rem = 0.0
			if tw_footjam:
				fj_count += 1
			elif tw_dir * float(stance) < 0.0:
				tw_opo_count += 1
			else:
				tw_count += 1
			tw_ang = 0.0
			tw_cool = 0.2
	else:
		tw_cool -= dt
	# кренкфлип: L + Крест в воздухе
	if crank_rem > 0.0:
		var dc := minf(crank_rem, 16.0 * dt)
		crank_a -= dc
		crank_rem -= dc
		if crank_rem <= 0.0:
			crank_rem = 0.0
			crank_count += 1
	# R + Крест — икс-ап
	if xup_held:
		xup_t += dt
	# тангаж
	var vh := Vector2(wvx, wvz).length()
	var traj := atan2(vy, maxf(vh, 2.0))
	var kick_t := 0.35 * (1.0 - hop_t / 0.22) if hop_t < 0.22 else 0.0
	var tgt := clampf(traj, -0.9, 0.9) * 0.45 + (-in_ly) * 0.75 + kick_t
	if bar_chicken and bar_rem > 0.0:
		tgt += 0.45
	if assist_land and vy < 0.0:
		var w2 := clampf((0.9 - hh) / 0.6, 0.0, 1.0) * 0.7 * (1.0 - absf(in_ly) * 0.8)
		if w2 > 0.0:
			tgt = tgt + (atan(slope_along(px, pz, yaw)) + 0.04 - tgt) * w2
	# флипы: правый стик вверх (фронтфлип) или вниз (бэкфлип) и удержать
	flip_cool -= dt
	if flips_on and flip_rem == 0.0 and flip_cool <= 0.0 and air_t > 0.12 and hh > 0.9 and absf(in_ry) > 0.75:
		flip_hold += dt
		if flip_hold > 0.12:
			flip_dir = 1.0 if in_ry < 0.0 else -1.0
			flip_rem = TAU * flip_dir
			flip_hold = 0.0
	else:
		flip_hold = 0.0
	if flip_rem == 0.0:
		pitch_w += (28.0 * (tgt - pitch) - 8.0 * pitch_w) * dt
		pitch += pitch_w * dt
	else:
		var df := minf(absf(flip_rem), 10.0 * k_flip * dt)
		pitch += df * flip_dir
		flip_rem -= df * flip_dir
		pitch_w = 0.0
		if absf(flip_rem) < 0.0001:
			flip_rem = 0.0
			pitch -= TAU * flip_dir
			flip_cool = 0.3
			if flip_dir > 0.0:
				flip_back += 1
			else:
				flip_front += 1
	roll = damp(roll, in_lx * 0.45, 6.0, dt)
	ws *= exp(-0.2 * dt)
	# перемещение
	var nx := px + wvx * dt
	var nz := pz + wvz * dt
	var ny := py + vy * dt
	var hN := terrain_h(nx, nz)
	if hN > ny + 0.38:
		var sp := Vector2(wvx, wvz).length()
		wvx *= -0.2
		wvz *= -0.2
		nx = px
		nz = pz
		hN = terrain_h(nx, nz)
		if sp > 8.0:
			py = ny
			bail("врезался в воздухе")
			return
		mair = atan2(-wvz, wvx)
	if absf(nx) > LIM:
		nx = clampf(nx, -LIM, LIM)
		wvx *= -0.3
	if absf(nz) > LIM:
		nz = clampf(nz, -LIM, LIM)
		wvz *= -0.3
	if grind_on and grind_check(nx, ny, nz):
		return
	if ny <= hN:
		land_now(nx, nz, hN)
		return
	px = nx
	pz = nz
	py = ny

func bail_step(dt: float) -> void:
	bail_t += dt
	vy -= G * dt
	px += wvx * dt
	pz += wvz * dt
	py += vy * dt
	var h := terrain_h(px, pz)
	if py <= h:
		py = h
		vy = 0.0
		var k := exp(-3.5 * dt)
		wvx *= k
		wvz *= k
	px = clampf(px, -LIM, LIM)
	pz = clampf(pz, -LIM, LIM)
	tumble = damp(tumble, 1.45, 5.0, dt)
	pitch = damp(pitch, 0.0, 4.0, dt)
	ws *= exp(-2.0 * dt)
	if bail_t > 2.6:
		respawn(false)

func physics(dt: float) -> void:
	if rider_free:
		rider_fall_step(dt)
	mash_t -= dt
	gr_cool -= dt
	if mash_t <= 0.0:
		mash_n = 0
	if mode != GROUND:
		pedal_kick = 0.0
		pedal_tap = 0.0
		kb_hop = false
	if mode == BAIL:
		bail_step(dt)
	elif mode == GROUND:
		ground_step(dt)
	elif mode == GRIND:
		grind_step(dt)
	else:
		air_step(dt)


func update_gameplay(dt: float) -> void:
	if mode == GROUND:
		var styled := held_L and not sliding
		if th > 0.25:
			if not has_manual:
				has_manual = true
				combo_items.append("Мануал")
			if styled:
				if not has_rocket:
					has_rocket = true
					combo_items.append("Рокет менуал")
				combo_pts += 130.0 * dt
			else:
				combo_pts += 90.0 * dt
			combo_idle = 0.0
		elif th < -0.25:
			if not has_nose:
				has_nose = true
				combo_items.append("Ноуз-мануал")
			if styled:
				if not has_hang5:
					has_hang5 = true
					combo_items.append("Hang 5")
				combo_pts += 150.0 * dt
			else:
				combo_pts += 110.0 * dt
			combo_idle = 0.0
		elif not combo_items.is_empty():
			combo_idle += dt
			if combo_idle > k_combo:
				bank_combo()

# =====================================================================
# ПОЗА, КАМЕРА
# =====================================================================

func spin_node(n: Node3D, nm: String, ang: float) -> void:
	if n == null:
		return
	var r := rest_of(nm)
	n.transform = Transform3D(r.basis * Basis(Vector3(1, 0, 0), ang), r.origin)


func steer_node(n: Node3D, nm: String, ang: float, axis: Vector3) -> void:
	if n == null:
		return
	var r := rest_of(nm)
	n.transform = Transform3D(Basis(axis, ang) * r.basis, r.origin)

func pose_visuals(dt: float) -> void:
	var ad := dt * k_anim
	root.position = Vector3(px, py, pz)
	root.rotation = Vector3(0, yaw, 0)
	var rl := tumble * tum_dir if mode == BAIL else roll
	body.basis = Basis(Vector3(0, 0, 1), pitch) * Basis(Vector3(1, 0, 0), rl)
	var m := clampf(absf(th) / 0.1, 0.0, 1.0) if (mode == GROUND or (mode == GRIND and gr_kind == 0)) else 0.0
	var cv := C_VEC_F if th < 0.0 else C_VEC
	if mode == GRIND:
		cv = Vector3(FRONT_X if th < 0.0 else C_VEC.x, PEG_H, 0.0)
	if m > 0.0:
		var qg := Basis(Vector3(0, 0, 1), gp)
		body.position = ((qg * cv) - (body.basis * cv)) * m
	else:
		body.position = Vector3.ZERO
	# сальто: вращение вокруг центра масс, а не вокруг точки на земле
	var piv_t := clampf((absf(pitch) - 0.5) / 0.5, 0.0, 1.0) if mode == AIR else 0.0
	piv_amt = damp(piv_amt, piv_t, 20.0, dt)
	if piv_amt > 0.001:
		var pvt := Vector3(0.0, 0.85, 0.0)
		body.position = (pvt - body.basis * pvt) * piv_amt
	# вип: рама крутится вокруг рулевой оси
	tuck_amt = damp(tuck_amt, 1.0 if (tuck_on and mode == AIR) else 0.0, 12.0 if tuck_on else 22.0, ad)
	var tuck_v := Vector3(0.0, TUCK_H * tuck_amt, 0.0)
	if rear_group != null:
		frame.transform = Transform3D(Basis.IDENTITY, tuck_v)
		var wa := Basis(axis_fork, tw_ang)
		var piv := rest_of("forks_front").origin
		rear_group.transform = Transform3D(wa, piv - wa * piv)
	else:
		var wb := Basis(Vector3(0, 1, 0), tw_ang)
		var wpv := Vector3(FORK_X, 0.0, 0.0)
		frame.transform = Transform3D(wb, wpv - wb * wpv + tuck_v)
	# колёса, кривошипы, руль
	wheel_a -= ws * dt / WHEEL_R
	spin_node(n_wheel_f, "wheel_front", wheel_a)
	spin_node(n_wheel_r, "wheel_rear", wheel_a)
	crank_w *= exp(-1.8 * dt)
	crank_a -= crank_w * dt
	if crank_rem <= 0.0 and absf(crank_w) < 0.6:
		var tgt_c := roundf((crank_a + PI * 0.5) / TAU) * TAU - PI * 0.5
		if stance < 0:
			tgt_c = roundf((crank_a - PI * 0.5) / TAU) * TAU + PI * 0.5
		var crank_rate := 4.0
		crank_a = damp(crank_a, tgt_c, crank_rate, dt)
	if not rider_ik:
		crank_a = -PI * 0.5
		crank_w = 0.0
	spin_node(n_chain, "chainset", crank_a)
	if n_ped_l != null:
		var rl_t := rest_of("Pedal_l")
		n_ped_l.transform = Transform3D(Basis(Vector3(1, 0, 0), -crank_a) * rl_t.basis, rl_t.origin)
		var rr_t := rest_of("Pedal_r")
		n_ped_r.transform = Transform3D(Basis(Vector3(1, 0, 0), -crank_a) * rr_t.basis, rr_t.origin)
	var steer_t := steer_ang if mode == GROUND else (-in_lx * 0.15)
	rig_steer = damp(rig_steer, steer_t, 14.0, ad)
	xup_amt = damp(xup_amt, 1.0 if xup_held else 0.0, 12.0, ad)
	steer_node(n_fork, "forks_front", rig_steer, axis_fork)
	steer_node(n_bars, "handlebars", rig_steer + bar_angle + xup_amt * 1.5, axis_bars)
	# позы райдера
	rig_ly = damp(rig_ly, in_ly, 14.0, ad)
	rig_head = damp(rig_head, -in_rx * 1.15, 14.0, ad)
	rig_tors = damp(rig_tors, -in_rx * 0.6, 9.0, ad)
	var cr_t := 0.0
	if hop_armed and mode == GROUND:
		cr_t = 0.45 + 0.25 * clampf(hop_push / PUSH_MAX, 0.0, 1.0)
	rig_crouch = damp(rig_crouch, cr_t, 10.0, ad)
	var man_t := clampf(th / 0.5, 0.0, 1.0) if (mode == GROUND and th > 0.0) else 0.0
	rig_man = damp(rig_man, man_t, 10.0, ad)
	whip_amt = damp(whip_amt, 1.0 if (tw_rem > 0.0 or (sliding and sl_kind == 2)) else 0.0, 14.0, ad)
	rock_amt = damp(rock_amt, 1.0 if (held_L and th > 0.25 and mode == GROUND) else 0.0, 12.0, ad)
	hang_amt = damp(hang_amt, 1.0 if (held_L and th < -0.25 and mode == GROUND) else 0.0, 12.0, ad)
	fj_amt = damp(fj_amt, 1.0 if (sliding and sl_kind == 2) else 0.0, 12.0, ad)
	hl_amt = damp(hl_amt, 1.0 if bar_rem > 0.0 else 0.0, 14.0, ad)
	hr_amt = damp(hr_amt, 1.0 if bar_rem > 0.0 else 0.0, 14.0, ad)
	if skel != null:
		if rider_free:
			pose_limp()
		elif rider_ik:
			pose_rider()
		else:
			rider_inst.position = Vector3.ZERO
			pov.clear()
			apply_pose()

func update_camera(dt: float) -> void:
	var vx := wvx
	var vz := wvz
	if mode == GROUND and not sliding:
		var f := dir_of(yaw)
		vx = f.x * spd
		vz = f.y * spd
	var sp := Vector2(vx, vz).length()
	var tgt := cam_yaw
	if sp > 1.5:
		tgt = atan2(-vz, vx)
	elif mode == GROUND:
		tgt = yaw
	cam_yaw += wrapf(tgt - cam_yaw, -PI, PI) * (1.0 - exp(-3.2 * dt))
	var dist := (5.2 + sp * 0.07) * k_cam
	var cx := cos(cam_yaw)
	var cz := -sin(cam_yaw)
	# камера левее по ходу движения (левый вектор = (cz, -cx)) и ниже
	var want_x := px - cx * dist + cz * k_cam_side
	var want_z := pz - cz * dist - cx * k_cam_side
	var want_y := k_cam_h + py * 0.65
	var k := 1.0 - exp(-8.0 * dt)
	cam_pos.x += (want_x - cam_pos.x) * k
	cam_pos.z += (want_z - cam_pos.z) * k
	cam_pos.y += (want_y - cam_pos.y) * (1.0 - exp(-5.0 * dt))
	cam_look = Vector3(px + cx * 2.0, py * 0.8 + 1.1, pz + cz * 2.0)
	cam.look_at_from_position(cam_pos, cam_look, Vector3.UP)
	cam.fov = damp(cam.fov, 62.0 + minf(sp, 13.0) * 1.3, 3.0, dt)


# =====================================================================
# ВИРТУАЛЬНЫЕ КНОПКИ (раскладка как в эмуляторе PSP) И ВВОД
# =====================================================================
const HIT_ORDER := ["L", "R", "cross", "circle", "square", "triangle", "start", "select", "dpad", "stick", "stick2"]
const KEY_RU := {
	"L": "L — поджатие байка в воздухе, модификатор трюков",
	"R": "R — модификатор трюков (руки)",
	"dpad": "крестовина (руль и вес)",
	"stick": "левый стик (руль и вес)",
	"stick2": "правый стик (вращения и флипы)",
	"cross": "Крест — разгон (долбить), с весом — высокий банихоп",
	"circle": "Круг — вип (с L), бар (с R), чикенбар (R на мануале)",
	"square": "Квадрат — опо-вариант: с L опо вип, с R опо бар",
	"triangle": "Треугольник — тормоз; на фейки — слайд",
	"start": "Start — меню",
	"select": "Select — сброс",
}

func add_ctrl(key: String, kind: String, pos: Vector2, caption: String) -> void:
	ctrls[key] = {"kind": kind, "pos": pos, "dpos": pos, "scale": 1.0, "caption": caption,
		"down": false, "touch": -1, "off": Vector2.ZERO}

func default_layout() -> void:
	ctrls = {}
	add_ctrl("L", "rect", Vector2(0.085, 0.065), "поджатие")
	add_ctrl("R", "rect", Vector2(0.915, 0.065), "руки")
	add_ctrl("dpad", "dpad", Vector2(0.12, 0.60), "")
	add_ctrl("stick", "stick", Vector2(0.25, 0.80), "руль · вес")
	add_ctrl("stick2", "stick", Vector2(0.75, 0.80), "вращения · флипы")
	add_ctrl("triangle", "circle", Vector2(0.891, 0.492), "тормоз / слайд")
	add_ctrl("square", "circle", Vector2(0.839, 0.583), "опо вип / бар")
	add_ctrl("circle", "circle", Vector2(0.942, 0.583), "вип / бар")
	add_ctrl("cross", "circle", Vector2(0.891, 0.675), "разгон / хоп")
	add_ctrl("select", "rect", Vector2(0.44, 0.94), "")
	add_ctrl("start", "rect", Vector2(0.56, 0.94), "")

func reset_layout() -> void:
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		c["pos"] = c["dpos"]
		c["scale"] = 1.0
	save_layout()

func load_layout() -> void:
	default_layout()
	var cf := ConfigFile.new()
	if cf.load("user://layout.cfg") != OK:
		return
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		var p: Vector2 = c["pos"]
		p.x = cf.get_value("l", str(key) + "_x", p.x)
		p.y = cf.get_value("l", str(key) + "_y", p.y)
		c["pos"] = p
		c["scale"] = cf.get_value("l", str(key) + "_s", 1.0)

func save_layout() -> void:
	var cf := ConfigFile.new()
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		var p: Vector2 = c["pos"]
		cf.set_value("l", str(key) + "_x", p.x)
		cf.set_value("l", str(key) + "_y", p.y)
		cf.set_value("l", str(key) + "_s", c["scale"])
	cf.save("user://layout.cfg")

func ctrl_center(key: String) -> Vector2:
	var c: Dictionary = ctrls[key]
	var p: Vector2 = c["pos"]
	return p * vp_size()

func ctrl_radius(key: String) -> float:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var base := 40.0
	if kind == "dpad":
		base = 80.0
	elif kind == "stick":
		base = 62.0
	return base * float(c["scale"]) * ui_scale

func ctrl_halfsize(key: String) -> Vector2:
	var c: Dictionary = ctrls[key]
	var base := Vector2(40, 15)
	if key == "L" or key == "R":
		base = Vector2(70, 27)
	return base * float(c["scale"]) * ui_scale

func ctrl_hit(key: String, p: Vector2) -> bool:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var cc := ctrl_center(key)
	if kind == "rect":
		var hs := ctrl_halfsize(key) + Vector2(8, 8)
		return absf(p.x - cc.x) <= hs.x and absf(p.y - cc.y) <= hs.y
	var r := ctrl_radius(key)
	if kind == "stick":
		r *= 1.25
	return p.distance_to(cc) <= r

func is_down(key: String) -> bool:
	var c: Dictionary = ctrls[key]
	return bool(c["down"])

func release_all() -> void:
	touch_role.clear()
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		c["down"] = false
		c["touch"] = -1
		c["off"] = Vector2.ZERO
	stick_vec["stick"] = Vector2.ZERO
	stick_vec["stick2"] = Vector2.ZERO
	dpad_dir = Vector2.ZERO
	pedal_release("L")
	pedal_release("R")
	kb_hop = false


func show_screen(n: int) -> void:
	menu_screen = n
	menu_panel.visible = menu_open and n == 0
	settings_panel.visible = menu_open and n == 1
	help_panel.visible = menu_open and n == 2

func _on_open_settings() -> void:
	show_screen(1)

func _on_open_help() -> void:
	show_screen(2)

func _on_back() -> void:
	show_screen(0)

func toggle_menu() -> void:
	if edit_mode:
		return
	menu_open = not menu_open
	show_screen(0)
	if menu_open:
		release_all()


func enter_edit() -> void:
	edit_mode = true
	menu_open = false
	show_screen(0)
	edit_bar.visible = true
	edit_sel = ""
	edit_drag = -1
	release_all()


func exit_edit() -> void:
	edit_mode = false
	edit_bar.visible = false
	edit_drag = -1
	menu_open = true
	show_screen(0)
	save_layout()

func edit_scale(f: float) -> void:
	if edit_sel == "":
		return
	var c: Dictionary = ctrls[edit_sel]
	c["scale"] = clampf(float(c["scale"]) * f, 0.5, 2.5)
	save_layout()

func pedal_press(side: String) -> void:
	if pedal_down[side]:
		return
	pedal_down[side] = true
	if mode == AIR:
		if side == "L":
			foot_air_l = true
		else:
			foot_air_r = true
	var v := -1 if side == "L" else 1
	var val := 1.3 if v != pedal_last else 0.3
	pedal_kick += val
	pedal_tap += val
	pedal_last = v

func pedal_release(side: String) -> void:
	pedal_down[side] = false
	if side == "L":
		foot_air_l = false
	else:
		foot_air_r = false


func ctrl_press(key: String) -> void:
	match key:
		"start":
			toggle_menu()
		"select":
			respawn(true)

func ctrl_release(key: String) -> void:
	var c: Dictionary = ctrls[key]
	c["touch"] = -1
	c["down"] = false
	c["off"] = Vector2.ZERO
	if key == "L":
		pedal_release("L")
	elif key == "R":
		pedal_release("R")
	elif key == "stick" or key == "stick2":
		stick_vec[key] = Vector2.ZERO
	elif key == "dpad":
		dpad_dir = Vector2.ZERO

func ctrl_update(key: String, p: Vector2) -> void:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var cc := ctrl_center(key)
	if kind == "stick":
		var R := ctrl_radius(key)
		var d := p - cc
		if d.length() > R:
			d = d / d.length() * R
		c["off"] = d
		stick_vec[key] = deadzone(Vector2(d.x / R, -d.y / R))
	elif kind == "dpad":
		var r := ctrl_radius(key)
		var d2 := p - cc
		var v := Vector2.ZERO
		if d2.x > r * 0.28:
			v.x = 1.0
		elif d2.x < -r * 0.28:
			v.x = -1.0
		if -d2.y > r * 0.28:
			v.y = 1.0
		elif -d2.y < -r * 0.28:
			v.y = -1.0
		dpad_dir = v


func gui_blocks(p: Vector2) -> bool:
	for pnl in [menu_panel, settings_panel, help_panel]:
		var pc := pnl as PanelContainer
		if pc != null and pc.visible and pc.get_global_rect().has_point(p):
			return true
	if edit_bar.visible and edit_bar.get_global_rect().has_point(p):
		return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			touch_down(t.index, t.position)
		else:
			touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		touch_move(d.index, d.position)

func touch_down(idx: int, p: Vector2) -> void:
	if gui_blocks(p):
		return
	if edit_mode:
		for key in HIT_ORDER:
			if ctrl_hit(key, p):
				edit_sel = key
				edit_drag = idx
				edit_off = ctrl_center(key) - p
				return
		return
	if menu_open:
		return
	for key in HIT_ORDER:
		if ctrl_hit(key, p):
			var c: Dictionary = ctrls[key]
			if int(c["touch"]) != -1:
				continue
			c["touch"] = idx
			c["down"] = true
			touch_role[idx] = key
			ctrl_press(key)
			ctrl_update(key, p)
			return

func touch_move(idx: int, p: Vector2) -> void:
	if edit_mode:
		if idx == edit_drag and edit_sel != "":
			var c: Dictionary = ctrls[edit_sel]
			var np := (p + edit_off) / vp_size()
			np.x = clampf(np.x, 0.03, 0.97)
			np.y = clampf(np.y, 0.04, 0.96)
			c["pos"] = np
		return
	var key: String = touch_role.get(idx, "")
	if key == "stick" or key == "stick2" or key == "dpad":
		ctrl_update(key, p)

func touch_up(idx: int) -> void:
	if edit_mode:
		if idx == edit_drag:
			edit_drag = -1
			save_layout()
		return
	var key: String = touch_role.get(idx, "")
	if key == "":
		return
	touch_role.erase(idx)
	ctrl_release(key)


func on_cross_press() -> void:
	if mode == GROUND and not sliding:
		mash_n += 1
		mash_t = 0.7
		if hop_armed:
			pedal_tap += 1.8
		else:
			pedal_kick += 1.1
			crank_w += 6.0
	elif mode == AIR:
		if held_L and air_t > 0.1 and crank_rem <= 0.0 and hH_ok():
			crank_rem = TAU
	elif mode == GRIND:
		gr_jump_req = true

func hH_ok() -> bool:
	return py - terrain_h(px, pz) > 0.4


func on_circle_press() -> void:
	if mode == GROUND and not sliding and held_L and in_ly > 0.4 and absf(spd) > 1.5:
		start_footjam()
		return
	if mode == GROUND and not sliding and held_R and th > 0.25 and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = -1.0 if in_lx < 0.0 else 1.0
		bar_chicken = true
		return
	if mode != AIR or air_t < 0.08 or not hH_ok():
		return
	# Круг: родное направление по стойке
	if held_L and tw_rem <= 0.0 and tw_cool <= 0.0:
		tw_rem = TAU
		tw_dir = float(stance)
		tw_footjam = false
	elif held_R and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = float(stance)
		bar_chicken = false

func on_square_press() -> void:
	if mode != AIR or air_t < 0.08 or not hH_ok():
		return
	# Квадрат: опо-вариант (в обратную сторону) — вип с L, бар с R
	if held_L and tw_rem <= 0.0 and tw_cool <= 0.0:
		tw_rem = TAU
		tw_dir = -float(stance)
		tw_footjam = false
	elif held_R and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = -float(stance)
		bar_chicken = false

func on_tri_press() -> void:
	if mode == GROUND and not sliding and spd < -0.8:
		start_slide()

func start_slide() -> void:
	var f := dir_of(yaw)
	sl_spd = absf(spd)
	sl_mv = atan2(-(f.y * spd), f.x * spd)
	sl_side = -1.0 if in_lx > 0.2 else 1.0
	var tgt := sl_mv + sl_side * PI * 0.5
	sl_steer = signf(wrapf(tgt - yaw, -PI, PI)) * 1.45
	sl_kind = 0
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("Слайд!", true)


func end_slide(steered: bool) -> void:
	sliding = false
	sl_kind = 0
	exit_yaw = sl_mv
	exit_t = 0.3
	if steered:
		spd = maxf(sl_spd * 0.9, 3.5)
		add_trick("Фейки слайд", 300.0)
		show_toast("Фейки слайд!", true)
	else:
		spd = maxf(sl_spd * 0.7, 2.5)
		add_trick("Слайд", 120.0)

func slide_step(dt: float) -> void:
	if sl_kind == 1:
		spin_slide_step(dt)
		return
	if sl_kind == 2:
		footjam_step(dt)
		return
	sl_t += dt
	var f := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 4.5 * dt)
	var nx := px + f.x * sl_spd * dt
	var nz := pz + f.y * sl_spd * dt
	var hN := terrain_h(nx, nz)
	if hN > py + 0.38:
		end_slide(false)
		return
	if hN < py - 0.15:
		wvx = f.x * sl_spd
		wvz = f.y * sl_spd
		vy = 0.0
		sliding = false
		start_air(nx, nz, py)
		return
	px = nx
	pz = nz
	py = hN
	wvx = f.x * sl_spd
	wvz = f.y * sl_spd
	var tgt := sl_mv + sl_side * PI * 0.5
	yaw += wrapf(tgt - yaw, -PI, PI) * (1.0 - exp(-12.0 * dt))
	steer_ang = damp(steer_ang, sl_steer, 20.0, dt)
	spd = -sl_spd
	ws = -sl_spd * 0.4
	gp = damp(gp, atan(slope_along(px, pz, sl_mv)), 25.0, dt)
	pitch = gp
	if sl_t > 0.25 and absf(in_lx) > 0.4:
		end_slide(true)
	elif (sl_t > 0.2 and not held_T) or sl_spd < 0.5:
		end_slide(false)

func poll_input(dt: float) -> void:
	var paused := menu_open or edit_mode
	# --- клавиатура (физические клавиши — работают при любой раскладке)
	var kL := Input.is_physical_key_pressed(KEY_Q)
	var kR := Input.is_physical_key_pressed(KEY_E)
	var kX := Input.is_physical_key_pressed(KEY_SPACE)
	var kO := Input.is_physical_key_pressed(KEY_X)
	var kT := Input.is_physical_key_pressed(KEY_C)
	var kS := Input.is_physical_key_pressed(KEY_Z)
	var rr := Input.is_physical_key_pressed(KEY_R)
	if rr and not kr and not paused:
		respawn(true)
	kr = rr
	var esc := Input.is_physical_key_pressed(KEY_ESCAPE)
	if esc and not kesc:
		toggle_menu()
	kesc = esc
	var tx := 0.0
	var ty := 0.0
	var tcx := 0.0
	var tcy := 0.0
	if Input.is_physical_key_pressed(KEY_D):
		tx += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		tx -= 1.0
	if Input.is_physical_key_pressed(KEY_W):
		ty += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		ty -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		tcx += 1.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		tcx -= 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		tcy += 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		tcy -= 1.0
	kb_lx = damp(kb_lx, tx, 16.0, dt)
	kb_ly = damp(kb_ly, ty, 16.0, dt)
	kb_rx = damp(kb_rx, tcx, 16.0, dt)
	kb_ry = damp(kb_ry, tcy, 16.0, dt)
	dpad_dig.x = damp(dpad_dig.x, dpad_dir.x, 16.0, dt)
	dpad_dig.y = damp(dpad_dig.y, dpad_dir.y, 16.0, dt)
	# --- геймпад: LB/LT — L, RB/RT — R, A — Крест, B — Круг, Y — Треугольник, X — Квадрат
	var pl := Vector2.ZERO
	var pr := Vector2.ZERO
	var gL := false
	var gR := false
	var gX := false
	var gO := false
	var gT := false
	var gS := false
	var pads := Input.get_connected_joypads()
	if pads.size() > 0:
		var j: int = pads[0]
		pl = deadzone(Vector2(Input.get_joy_axis(j, JOY_AXIS_LEFT_X), -Input.get_joy_axis(j, JOY_AXIS_LEFT_Y)))
		pr = deadzone(Vector2(Input.get_joy_axis(j, JOY_AXIS_RIGHT_X), -Input.get_joy_axis(j, JOY_AXIS_RIGHT_Y)))
		gL = Input.is_joy_button_pressed(j, JOY_BUTTON_LEFT_SHOULDER) or Input.get_joy_axis(j, JOY_AXIS_TRIGGER_LEFT) > 0.5
		gR = Input.is_joy_button_pressed(j, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(j, JOY_AXIS_TRIGGER_RIGHT) > 0.5
		gX = Input.is_joy_button_pressed(j, JOY_BUTTON_A)
		gO = Input.is_joy_button_pressed(j, JOY_BUTTON_B)
		gT = Input.is_joy_button_pressed(j, JOY_BUTTON_Y)
		gS = Input.is_joy_button_pressed(j, JOY_BUTTON_X)
		var ps := Input.is_joy_button_pressed(j, JOY_BUTTON_START)
		if ps and not pad_start:
			toggle_menu()
		pad_start = ps
		var pk := Input.is_joy_button_pressed(j, JOY_BUTTON_BACK)
		if pk and not pad_back and not paused:
			respawn(true)
		pad_back = pk
	# --- сводим экранные кнопки, клавиатуру и геймпад
	var hL := is_down("L") or kL or gL
	var hR := is_down("R") or kR or gR
	var hX := is_down("cross") or kX or gX
	var hO := is_down("circle") or kO or gO
	var hT := is_down("triangle") or kT or gT
	var hS := is_down("square") or kS or gS
	var air := mode == AIR
	if hL and not held_L and air:
		armed_L = true
	if not hL:
		armed_L = false
	if hR and not held_R and air:
		armed_R = true
	if not hR:
		armed_R = false
	var ev_x := hX and not held_X
	var ev_o := hO and not held_O
	var ev_t := hT and not held_T
	var ev_s := hS and not held_S
	held_L = hL
	held_R = hR
	held_X = hX
	held_O = hO
	held_T = hT
	held_S = hS
	# L зажатая в воздухе — поджатие байка (приземляться можно)
	hand_l_off = false
	hand_r_off = false
	foot_l_off = false
	foot_r_off = false
	tuck_on = hL and air
	brake_held = hT
	xup_held = hR and hX and air
	pedal_both_t = 0.0
	if not paused:
		if ev_x:
			on_cross_press()
		if ev_o:
			on_circle_press()
		if ev_t:
			on_tri_press()
		if ev_s:
			on_square_press()
	var sl: Vector2 = stick_vec["stick"]
	var sr: Vector2 = stick_vec["stick2"]
	in_lx = clampf(kb_lx + sl.x + dpad_dig.x + pl.x, -1.0, 1.0)
	in_ly = clampf(kb_ly + sl.y + dpad_dig.y + pl.y, -1.0, 1.0) * (-1.0 if invert_y else 1.0)
	in_rx = clampf(kb_rx + sr.x + pr.x, -1.0, 1.0)
	in_ry = clampf(kb_ry + sr.y + pr.y, -1.0, 1.0)

# =====================================================================
# МЕНЮ, РЕДАКТОР РАСКЛАДКИ, ОТРИСОВКА
# =====================================================================

func make_check(text: String, state: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = state
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 22)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = text + (":  ВКЛ" if state else ":  ВЫКЛ")
	b.toggled.connect(_on_toggle_btn.bind(b, text, cb))
	return b


func make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func make_slider(text: String, mn: float, mx: float, val: float, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(340, 0)
	l.add_theme_font_size_override("font_size", 21)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = 0.05
	sl.value = val
	sl.custom_minimum_size = Vector2(300, 52)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_slider(sl)
	sl.value_changed.connect(cb)
	h.add_child(sl)
	return h

func _on_bal(v: bool) -> void:
	assist_bal = v
	save_settings()

func _on_land(v: bool) -> void:
	assist_land = v
	save_settings()

func _on_inv(v: bool) -> void:
	invert_y = v
	save_settings()

func _on_labels(v: bool) -> void:
	show_labels = v
	save_settings()

func _on_opacity(v: float) -> void:
	ui_opacity = v
	save_settings()

func _on_uiscale(v: float) -> void:
	ui_scale = v
	save_settings()

func _on_minus() -> void:
	edit_scale(0.9)

func _on_plus() -> void:
	edit_scale(1.1)

func _on_reset_layout() -> void:
	reset_layout()


func make_menu_panel(width: float, height: float) -> VBoxContainer:
	var pnl := PanelContainer.new()
	pnl.visible = false
	pnl.anchor_left = 0.5
	pnl.anchor_right = 0.5
	pnl.anchor_top = 0.5
	pnl.anchor_bottom = 0.5
	pnl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pnl.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.add_child(pnl)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(width, height)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pnl.add_child(sc)
	sc.get_v_scroll_bar().custom_minimum_size = Vector2(30, 0)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.custom_minimum_size = Vector2(width - 50.0, 0)
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)
	var t := Label.new()
	vb.add_child(t)
	vb.set_meta("panel", pnl)
	vb.set_meta("title", t)
	return vb

func menu_title(vb: VBoxContainer, text: String) -> void:
	var t := vb.get_meta("title") as Label
	t.text = text
	t.add_theme_font_size_override("font_size", 34)

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	hud.draw.connect(_on_hud_draw)
	var vs := vp_size()
	var mw := minf(1180.0, vs.x - 60.0)
	var mh := minf(640.0, vs.y - 40.0)
	# --- главное меню (Start) ---
	var vm := make_menu_panel(minf(760.0, vs.x - 60.0), minf(560.0, vs.y - 40.0))
	menu_panel = vm.get_meta("panel") as PanelContainer
	menu_title(vm, "МЕНЮ")
	vm.add_child(make_button("Продолжить", toggle_menu))
	vm.add_child(make_button("Настройки", _on_open_settings))
	vm.add_child(make_button("Расположение кнопок", enter_edit))
	vm.add_child(make_button("Справка", _on_open_help))
	# --- настройки ---
	var vb := make_menu_panel(mw, mh)
	settings_panel = vb.get_meta("panel") as PanelContainer
	menu_title(vb, "НАСТРОЙКИ")
	vb.add_child(make_button("Назад", _on_back))
	stance_btn = make_button(stance_text(), _on_stance)
	vb.add_child(stance_btn)
	vb.add_child(make_button("Сбросить расположение кнопок", _on_reset_layout))
	vb.add_child(make_slider("Прозрачность кнопок", 0.15, 1.0, ui_opacity, _on_opacity))
	vb.add_child(make_slider("Общий размер кнопок", 0.6, 1.6, ui_scale, _on_uiscale))
	vb.add_child(make_check("Подписи под кнопками", show_labels, _on_labels))
	vb.add_child(make_check("Помощь баланса мануала", assist_bal, _on_bal))
	vb.add_child(make_check("Помощь приземления", assist_land, _on_land))
	vb.add_child(make_check("Инверсия вертикали левого стика", invert_y, _on_inv))
	vb.add_child(make_check("Флипы (правый стик вверх/вниз)", flips_on, _on_flips))
	vb.add_child(make_check("Райдер по скелету (IK), выкл = запечённая поза", rider_ik, _on_rik))
	vb.add_child(make_check("Гринд: автозахват рейлы", grind_on, _on_grind))
	vb.add_child(make_check("Диагностика модели на экране", diag_on, _on_diag))
	var th_lab := Label.new()
	th_lab.text = "ФИЗИКА И АНИМАЦИИ"
	th_lab.add_theme_font_size_override("font_size", 28)
	vb.add_child(th_lab)
	for t in TWEAKS:
		vb.add_child(make_tweak_slider(t))
	vb.add_child(make_button("Сбросить физику и анимации", _on_reset_tweaks))
	vb.add_child(make_button("Назад", _on_back))
	# --- справка ---
	var vh := make_menu_panel(mw, mh)
	help_panel = vh.get_meta("panel") as PanelContainer
	menu_title(vh, "СПРАВКА")
	vh.add_child(make_button("Назад", _on_back))
	var lab := Label.new()
	lab.text = HELP_TEXT
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(mw - 90.0, 0)
	lab.add_theme_font_size_override("font_size", 19)
	vh.add_child(lab)
	vh.add_child(make_button("Назад", _on_back))
	# --- панель редактора раскладки ---
	edit_bar = PanelContainer.new()
	edit_bar.visible = false
	edit_bar.anchor_left = 0.5
	edit_bar.anchor_right = 0.5
	edit_bar.offset_top = 8.0
	edit_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui.add_child(edit_bar)
	var hb := HBoxContainer.new()
	edit_bar.add_child(hb)
	edit_lbl = Label.new()
	edit_lbl.custom_minimum_size = Vector2(380, 0)
	edit_lbl.add_theme_font_size_override("font_size", 20)
	hb.add_child(edit_lbl)
	hb.add_child(make_button("−", _on_minus))
	hb.add_child(make_button("+", _on_plus))
	hb.add_child(make_button("Сброс", _on_reset_layout))
	hb.add_child(make_button("Готово", exit_edit))

func draw_ctrl(key: String, f: Font) -> void:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var down: bool = c["down"]
	var cc := ctrl_center(key)
	var A := maxf(ui_opacity, 0.5) if edit_mode else ui_opacity
	var fill := Color(1, 1, 1, (0.5 if down else 0.2) * A)
	var line := Color(1, 1, 1, 0.85 * A)
	var ta := minf(1.0, A + 0.3)
	var cap: String = c["caption"]
	var cap_y := cc.y
	if kind == "rect":
		var hs := ctrl_halfsize(key)
		var rc := Rect2(cc - hs, hs * 2.0)
		if key == "L" or key == "R":
			if mode == AIR and ((key == "L" and foot_l_off) or (key == "R" and hand_r_off)):
				line = Color(0.6, 0.95, 0.5, 0.95)
		hud.draw_rect(rc, fill, true)
		hud.draw_rect(rc, line, false, 2.5)
		var txt := key if (key == "L" or key == "R") else key.to_upper()
		var fs := int(hs.y * 0.85)
		hud.draw_string(f, Vector2(cc.x - hs.x, cc.y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, hs.x * 2.0, fs, Color(1, 1, 1, ta))
		cap_y = cc.y + hs.y + 13.0
	elif kind == "circle":
		var r := ctrl_radius(key)
		if key == "cross" and hop_armed:
			line = Color(1.0, 0.65, 0.15, 0.95)
		hud.draw_circle(cc, r, fill)
		hud.draw_arc(cc, r, 0.0, TAU, 40, line, 2.5)
		var s := r * 0.42
		if key == "cross":
			var col := Color(0.45, 0.65, 1.0, ta)
			hud.draw_line(cc + Vector2(-s, -s), cc + Vector2(s, s), col, 4.0)
			hud.draw_line(cc + Vector2(-s, s), cc + Vector2(s, -s), col, 4.0)
		elif key == "circle":
			hud.draw_arc(cc, s * 1.05, 0.0, TAU, 28, Color(1.0, 0.4, 0.4, ta), 4.0)
		elif key == "square":
			hud.draw_rect(Rect2(cc - Vector2(s, s) * 0.95, Vector2(s, s) * 1.9), Color(1.0, 0.55, 0.85, ta), false, 4.0)
		elif key == "triangle":
			var pts := PackedVector2Array([cc + Vector2(0, -s * 1.1), cc + Vector2(s * 1.0, s * 0.8), cc + Vector2(-s * 1.0, s * 0.8), cc + Vector2(0, -s * 1.1)])
			hud.draw_polyline(pts, Color(0.5, 0.95, 0.55, ta), 4.0)
		cap_y = cc.y + r + 13.0
	elif kind == "dpad":
		var r := ctrl_radius(key)
		var a := r * 0.36
		var plus := PackedVector2Array([
			cc + Vector2(-a, -r), cc + Vector2(a, -r), cc + Vector2(a, -a), cc + Vector2(r, -a),
			cc + Vector2(r, a), cc + Vector2(a, a), cc + Vector2(a, r), cc + Vector2(-a, r),
			cc + Vector2(-a, a), cc + Vector2(-r, a), cc + Vector2(-r, -a), cc + Vector2(-a, -a)])
		hud.draw_colored_polygon(plus, Color(1, 1, 1, 0.2 * A))
		var outline := plus.duplicate()
		outline.append(plus[0])
		hud.draw_polyline(outline, line, 2.5)
		var dirs := [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
		for di in range(4):
			var dv: Vector2 = dirs[di]
			var pv := Vector2(-dv.y, dv.x)
			var on := (dpad_dir.x != 0.0 and dv.x == dpad_dir.x) or (dpad_dir.y != 0.0 and dv.y == -dpad_dir.y)
			var ac := Color(1, 1, 1, (0.95 if on else 0.55) * ta)
			hud.draw_colored_polygon(PackedVector2Array([cc + dv * r * 0.84, cc + dv * r * 0.56 + pv * a * 0.6, cc + dv * r * 0.56 - pv * a * 0.6]), ac)
		cap_y = cc.y + r + 13.0
	elif kind == "stick":
		var r := ctrl_radius(key)
		hud.draw_circle(cc, r, Color(1, 1, 1, 0.1 * A))
		hud.draw_arc(cc, r, 0.0, TAU, 48, line, 2.5)
		var off: Vector2 = c["off"]
		hud.draw_circle(cc + off, r * 0.47, Color(1, 1, 1, (0.55 if down else 0.3) * A))
		hud.draw_arc(cc + off, r * 0.47, 0.0, TAU, 28, line, 2.0)
		cap_y = cc.y + r + 13.0
	if (show_labels or edit_mode) and cap != "":
		hud.draw_string(f, Vector2(cc.x - 70, cap_y), cap, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, Color(1, 1, 1, 0.75 * ta))
	if edit_mode and edit_sel == key:
		var yel := Color(1.0, 0.9, 0.3, 0.95)
		if kind == "rect":
			var hs2 := ctrl_halfsize(key)
			hud.draw_rect(Rect2(cc - hs2, hs2 * 2.0).grow(6.0), yel, false, 3.0)
		else:
			var r2 := ctrl_radius(key)
			hud.draw_arc(cc, r2 + 7.0, 0.0, TAU, 48, yel, 3.0)

func _on_hud_draw() -> void:
	var s := vp_size()
	var f := ThemeDB.fallback_font
	for key in ctrls:
		draw_ctrl(key, f)
	# табло
	var iy := 72.0
	hud.draw_rect(Rect2(10, iy, 250, 78), Color(0.04, 0.07, 0.1, 0.6), true)
	hud.draw_string(f, Vector2(20, iy + 22), "BMX STREET  прототип 2.3", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var speed := absf(spd) if mode == GROUND else Vector2(wvx, wvz).length()
	var label := "Земля"
	if mode == BAIL:
		label = "Бейл"
	elif mode == AIR:
		label = "Воздух"
	elif mode == GRIND:
		label = "Гринд"
	elif th > 0.05:
		label = "Мануал"
	elif th < -0.05:
		label = "Ноуз-мануал"
	elif spd < -0.5:
		label = "Фэйки"
	if sliding:
		label = "Слайд"
	hud.draw_string(f, Vector2(20, iy + 44), "%d км/ч · %s" % [int(roundf(speed * 3.6)), label], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.85, 0.92, 1))
	hud.draw_string(f, Vector2(20, iy + 66), "Очки: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 0.9, 0.5))
	if diag_on and not menu_open and not edit_mode:
		for di in range(diag_text.size()):
			var dl := String(diag_text[di])
			hud.draw_string_outline(f, Vector2(10, iy + 100 + di * 16), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.8))
			hud.draw_string(f, Vector2(10, iy + 100 + di * 16), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0.7))
	# комбо
	if not combo_items.is_empty():
		var ct := " + ".join(PackedStringArray(combo_items))
		if combo_items.size() > 1:
			ct += "  ×%.2f" % combo_mult()
		hud.draw_string_outline(f, Vector2(0, 118), ct, HORIZONTAL_ALIGNMENT_CENTER, s.x, 20, 5, Color(0, 0, 0, 0.8))
		hud.draw_string(f, Vector2(0, 118), ct, HORIZONTAL_ALIGNMENT_CENTER, s.x, 20, Color.WHITE)
		var pt := str(int(roundf(combo_pts * combo_mult())))
		hud.draw_string_outline(f, Vector2(0, 150), pt, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, 6, Color(0, 0, 0, 0.8))
		hud.draw_string(f, Vector2(0, 150), pt, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, Color(1, 0.9, 0.4))
	# всплывающая надпись
	if toast_t > 0.0:
		var tc := Color(0.55, 1, 0.55) if toast_good else Color(1, 0.45, 0.4)
		tc.a = clampf(toast_t / 0.4, 0.0, 1.0)
		var oc := Color(0, 0, 0, tc.a * 0.8)
		hud.draw_string_outline(f, Vector2(0, s.y * 0.32), toast_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, 7, oc)
		hud.draw_string(f, Vector2(0, s.y * 0.32), toast_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, tc)
	if hint_t > 0.0 and not menu_open and not edit_mode:
		hud.draw_string_outline(f, Vector2(0, s.y - 64), "Start — меню, настройки и расположение кнопок", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, 4, Color(0, 0, 0, 0.7))
		hud.draw_string(f, Vector2(0, s.y - 64), "Start — меню, настройки и расположение кнопок", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, Color(1, 1, 1, 0.85))
	# шкалы баланса и толчка ногами (рядом с райдером)
	var bar_h := 154.0
	var bx := s.x * 0.5 + 190.0
	var by := s.y * 0.5 - 80.0
	if mode == GROUND and absf(th) > 0.03:
		hud.draw_rect(Rect2(bx, by, 16, bar_h), Color(0.04, 0.07, 0.1, 0.55), true)
		var band_b := (0.55 - 0.14) / 1.3 * bar_h
		var band_h := 0.28 / 1.3 * bar_h
		hud.draw_rect(Rect2(bx, by + bar_h - band_b - band_h, 16, band_h), Color(0.4, 0.9, 0.4, 0.5), true)
		var mk := clampf(absf(th) / 1.3, 0.0, 1.0) * bar_h
		hud.draw_rect(Rect2(bx - 3, by + bar_h - mk - 3, 22, 6), Color.WHITE, true)
	if hop_armed and mode == GROUND:
		var pxb := bx - 30.0
		hud.draw_rect(Rect2(pxb, by, 16, bar_h), Color(0.04, 0.07, 0.1, 0.55), true)
		var fh := clampf(hop_push / PUSH_MAX, 0.0, 1.0) * bar_h
		hud.draw_rect(Rect2(pxb, by + bar_h - fh, 16, fh), Color(1.0, 0.65, 0.15, 0.9), true)
		hud.draw_string(f, Vector2(pxb - 14, by + bar_h + 16), "толчок", HORIZONTAL_ALIGNMENT_CENTER, 44, 12, Color(1, 0.85, 0.5))



func tv(key: String) -> float:
	return float(tweaks[key])

func init_tweaks() -> void:
	tweaks = {}
	for t in TWEAKS:
		tweaks[t[0]] = t[4]

func load_tweaks() -> void:
	init_tweaks()
	var cf := ConfigFile.new()
	if cf.load("user://tweaks.cfg") == OK:
		for t in TWEAKS:
			tweaks[t[0]] = cf.get_value("t", t[0], t[4])
	apply_tweaks()

func save_tweaks() -> void:
	var cf := ConfigFile.new()
	for t in TWEAKS:
		cf.set_value("t", t[0], tweaks[t[0]])
	cf.save("user://tweaks.cfg")

func apply_tweaks() -> void:
	G = tv("gravity")
	MAXS = tv("max_speed")
	PUSH_BOOST = tv("push_boost")
	PUSH_DECAY = tv("push_decay")
	hop_win = tv("hop_win")
	k_jump = tv("jump")
	k_pedal = tv("pedal")
	k_drag = tv("drag")
	k_steer = tv("steer")
	k_spin = tv("spin")
	k_barspin = tv("barspin")
	k_whip = tv("whip")
	k_flip = tv("flip")
	k_anim = tv("anim")
	k_combo = tv("combo")
	k_cam = tv("cam")
	k_tuck = tv("tuck")
	k_cam_side = tv("cam_side")
	k_cam_h = tv("cam_h")


func make_tweak_slider(t: Array) -> HBoxContainer:
	var key: String = t[0]
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = t[1]
	l.custom_minimum_size = Vector2(380, 0)
	l.add_theme_font_size_override("font_size", 20)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = t[2]
	sl.max_value = t[3]
	sl.step = t[5]
	sl.value = tv(key)
	sl.custom_minimum_size = Vector2(260, 52)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_slider(sl)
	h.add_child(sl)
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(84, 0)
	vl.text = "%.2f" % tv(key)
	vl.add_theme_font_size_override("font_size", 20)
	h.add_child(vl)
	sl.value_changed.connect(_on_tweak.bind(key, vl))
	tweak_sliders[key] = sl
	return h

func _on_tweak(v: float, key: String, vl: Label) -> void:
	tweaks[key] = v
	vl.text = "%.2f" % v
	apply_tweaks()
	save_tweaks()

func _on_reset_tweaks() -> void:
	for t in TWEAKS:
		var sl: HSlider = tweak_sliders[t[0]]
		sl.value = t[4]
	init_tweaks()
	apply_tweaks()
	save_tweaks()

func _on_flips(v: bool) -> void:
	flips_on = v
	save_settings()



func _on_rik(v: bool) -> void:
	rider_ik = v
	save_settings()

func _on_diag(v: bool) -> void:
	diag_on = v
	save_settings()

func fin(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)

func update_diag() -> void:
	var lines: Array = []
	lines.append("Байк: " + ("модель OK" if (bike_inst != null and n_fork != null) else "НЕТ модели или узлов"))
	lines.append("Поз: x=%.0f z=%.0f h=%.1f, карта: %s" % [px, pz, py, "город" if hf_ok else "парк (город не загрузился)"])
	if rider_inst == null:
		lines.append("Райдер: сцена не загружена")
	else:
		var st := "Skeleton3D НЕ НАЙДЕН"
		if skel != null:
			st = "Skeleton3D OK, костей %d" % skel.get_bone_count()
		lines.append("Райдер: " + st + (" · IK вкл" if rider_ik else " · IK выкл"))
		for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			if m3.mesh != null:
				var ab := m3.get_aabb()
				var sk_ok := m3.get_node_or_null(m3.skeleton) != null
				lines.append("mesh %s: поверхностей %d, skin=%s, skel=%s, AABB %.1f x %.1f x %.1f" % [m3.name, m3.mesh.get_surface_count(), str(m3.skin != null), str(sk_ok), ab.size.x, ab.size.y, ab.size.z])
		if skel != null and rider_ik:
			for nm in ["Head", "L_Foot", "R_Foot", "L_Hand", "R_Hand"]:
				var p := bpos(nm)
				if fin(p):
					lines.append("%s: %.2f %.2f %.2f" % [nm, p.x, p.y, p.z])
				else:
					lines.append(nm + ": NaN!")
	if skel != null:
		var hk := kx("Head")
		var hi: int = sk_idx[hk]
		var ir := skel.get_bone_rest(hi).origin
		var br: Vector3 = rest_local[hk].origin
		lines.append("rest Head: движок %.2f %.2f %.2f / запечено %.2f %.2f %.2f" % [ir.x, ir.y, ir.z, br.x, br.y, br.z])
		var sg := skel.global_transform
		lines.append("skel node: %.2f %.2f %.2f, scale %.2f, скин подменён: %s" % [sg.origin.x, sg.origin.y, sg.origin.z, sg.basis.get_scale().x, str(skin_fixed)])
	diag_text = lines


func start_spin_slide(rem: float, dir: float, mv: float, speed: float) -> void:
	sl_kind = 1
	sl_mv = mv
	sl_spd = speed
	sl_rot_rem = rem * dir
	sl_steer = dir * 1.2
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("360 слайдом!", true)

func spin_slide_step(dt: float) -> void:
	sl_t += dt
	var f := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 3.0 * dt)
	var nx := px + f.x * sl_spd * dt
	var nz := pz + f.y * sl_spd * dt
	var hN := terrain_h(nx, nz)
	if hN > py + 0.38:
		sliding = false
		sl_kind = 0
		spd = 0.0
		return
	if hN < py - 0.15:
		wvx = f.x * sl_spd
		wvz = f.y * sl_spd
		vy = 0.0
		sliding = false
		sl_kind = 0
		start_air(nx, nz, py)
		return
	px = nx
	pz = nz
	py = hN
	wvx = f.x * sl_spd
	wvz = f.y * sl_spd
	var dyaw := signf(sl_rot_rem) * minf(absf(sl_rot_rem), 7.5 * dt)
	yaw += dyaw
	sl_rot_rem -= dyaw
	steer_ang = damp(steer_ang, sl_steer, 20.0, dt)
	spd = sl_spd
	ws = sl_spd * 0.5
	gp = damp(gp, atan(slope_along(px, pz, sl_mv)), 25.0, dt)
	pitch = gp
	if absf(sl_rot_rem) < 0.02:
		sliding = false
		sl_kind = 0
		yaw = sl_mv
		spd = sl_spd
		add_trick("360 слайдом", 200.0)
		show_toast("360 слайдом!", true)


func _on_grind(v: bool) -> void:
	grind_on = v
	save_settings()

func rail_h(r: Rail, t: float) -> float:
	return r.ay + (r.by - r.ay) * clampf(t / r.rlen, 0.0, 1.0)

func add_rail(ax: float, ay: float, az: float, bx: float, by: float, bz: float) -> void:
	var r := Rail.new()
	r.ax = ax
	r.ay = ay
	r.az = az
	r.by = by
	var hl := Vector2(bx - ax, bz - az)
	r.rlen = hl.length()
	var dn := hl / r.rlen
	r.dx = dn.x
	r.dz = dn.y
	rails.append(r)
	var rm := mat("cfd4d9", 0.3, 0.75)
	var pm := mat("5b646b", 0.6, 0.3)
	tube(self, Vector3(ax, ay - 0.03, az), Vector3(bx, by - 0.03, bz), 0.03, rm)
	var n := int(r.rlen / 2.5) + 1
	for i in range(n + 1):
		var t := r.rlen * float(i) / float(n)
		var x := ax + r.dx * t
		var z := az + r.dz * t
		var h := rail_h(r, t)
		tube(self, Vector3(x, 0.0, z), Vector3(x, h - 0.03, z), 0.022, pm)
		make_box(self, Vector3(0.28, 0.03, 0.28), pm, Vector3(x, 0.015, z))

func rail_wall(x: float, z: float) -> float:
	for r in rails:
		var rx := x - r.ax
		var rz := z - r.az
		var t := rx * r.dx + rz * r.dz
		var lat := rx * r.dz - rz * r.dx
		if t >= -0.05 and t <= r.rlen + 0.05 and absf(lat) < 0.12:
			return rail_h(r, t)
	return 0.0


func grind_contact(r: Rail, pp: Vector2, y: float) -> bool:
	var rel := pp - Vector2(r.ax, r.az)
	var d := Vector2(r.dx, r.dz)
	var t := rel.dot(d)
	var lat := rel.x * d.y - rel.y * d.x
	if t < 0.0 or t > r.rlen or absf(lat) > 0.1:
		return false
	var rh := rail_h(r, t)
	return y > rh - 0.08 and y < rh + 0.18


func grind_check(nx: float, ny: float, nz: float) -> bool:
	if gr_cool > 0.0 or vy > 1.0 or rails.is_empty():
		return false
	var f := dir_of(yaw)
	var right := Vector2(sin(yaw), cos(yaw))
	var base := Vector2(nx, nz)
	for ri in range(rails.size()):
		var r: Rail = rails[ri]
		var d := Vector2(r.dx, r.dz)
		var along := f.dot(d)
		# пеги (только справа): байк должен лечь вдоль рейлы
		if absf(along) >= GRIND_ALIGN:
			for k in range(2):
				var pgx := FRONT_X if k == 0 else C_VEC.x
				if grind_contact(r, base + f * pgx + right * PEG_LAT, ny + PEG_H):
					start_grind(ri, along, nx, ny, nz, 0, 1.0)
					return true
		# каретка: рейла под центром байка, угол захода любой, но нужна скорость вдоль рейлы
		var vd := Vector2(wvx, wvz).dot(d)
		if absf(vd) >= 1.5 and grind_contact(r, base + f * BB_X, ny + CRANK_H):
			start_grind(ri, along, nx, ny, nz, 1, 0.0)
			return true
	return false


func start_grind(ri: int, along: float, nx: float, ny: float, nz: float, kind: int, side: float) -> void:
	var r: Rail = rails[ri]
	gr_rail = ri
	gr_kind = kind
	gr_side = side
	gr_lat = PEG_LAT if kind == 0 else 0.0
	gr_h = PEG_H if kind == 0 else CRANK_H
	gr_style = 0
	var d := Vector2(r.dx, r.dz)
	var vd := Vector2(wvx, wvz).dot(d)
	if kind == 0:
		gr_face = 1.0 if along >= 0.0 else -1.0
		gr_dir = signf(vd) if absf(vd) > 0.3 else gr_face
		gr_fakie = gr_dir != gr_face
		var fv := d * gr_face
		var yt := atan2(-fv.y, fv.x)
		var right := Vector2(sin(yt), cos(yt))
		var c := Vector2(nx, nz) + right * (gr_side * gr_lat) - Vector2(r.ax, r.az)
		gr_t = clampf(c.dot(d), 0.0, r.rlen)
	else:
		# каретка: курс байка не меняем, едем вдоль рейлы с той скоростью, что вдоль неё была
		gr_face = 1.0 if along >= 0.0 else -1.0
		gr_dir = 1.0 if vd >= 0.0 else -1.0
		var fh := dir_of(yaw)
		gr_fakie = fh.dot(d * gr_dir) < 0.0
		var c2 := Vector2(nx, nz) + fh * BB_X - Vector2(r.ax, r.az)
		gr_t = clampf(c2.dot(d), 0.0, r.rlen)
	gr_spd = absf(vd)
	gr_time = 0.0
	gr_jump_req = false
	gr_pull = false
	mode = GRIND
	px = nx
	pz = nz
	py = ny
	vy = 0.0
	th = 0.0
	om = 0.0
	spin_w = 0.0
	hop_armed = false
	var gname := "Пег-гринд" if kind == 0 else "Гринд на каретке"
	if gr_fakie:
		gname = "Фейки гринд" if kind == 0 else "Фейки гринд на каретке"
	if not combo_items.has(gname):
		add_trick(gname, 0.0)
	combo_idle = 0.0
	show_toast(gname + "!", true)


func grind_step(dt: float) -> void:
	var r: Rail = rails[gr_rail]
	gr_time += dt
	gr_spd = maxf(0.0, gr_spd - 0.9 * dt)
	gr_t += gr_dir * gr_spd * dt
	var dv := Vector2(r.dx, r.dz) * gr_dir
	var tc := clampf(gr_t, 0.0, r.rlen)
	var rp: Vector2
	var slope := 0.0
	var roll_t := 0.14
	if gr_kind == 0:
		# пеги: байк выравнивается вдоль рейлы
		var fv := Vector2(r.dx, r.dz) * gr_face
		var yaw_t := atan2(-fv.y, fv.x)
		yaw += wrapf(yaw_t - yaw, -PI, PI) * (1.0 - exp(-14.0 * dt))
		var right := Vector2(sin(yaw_t), cos(yaw_t))
		rp = Vector2(r.ax, r.az) + Vector2(r.dx, r.dz) * tc - right * (gr_side * gr_lat)
		slope = (r.by - r.ay) / r.rlen * gr_face
		# L + стик вниз — айс пик (задний пег, нос вверх), L + стик вверх — туз пик (передний пег)
		var sty := 0
		if held_L and in_ly < -0.5:
			sty = 1
		elif held_L and in_ly > 0.5:
			sty = 2
		if sty != 0 and sty != gr_style:
			var sn := "Айс пик" if sty == 1 else "Туз пик"
			if not combo_items.has(sn):
				add_trick(sn, 0.0)
			show_toast(sn + "!", true)
		gr_style = sty
		var th_t := 0.0
		if sty == 1:
			th_t = 0.55
		elif sty == 2:
			th_t = -0.5
		th = damp(th, th_t, 10.0, dt)
	else:
		# каретка: угол байка остаётся таким, каким зашли; рейла под кареткой
		var fh := dir_of(yaw)
		rp = Vector2(r.ax, r.az) + Vector2(r.dx, r.dz) * tc - fh * BB_X
		slope = (r.by - r.ay) / r.rlen * fh.dot(Vector2(r.dx, r.dz))
		roll_t = 0.0
	var k := 1.0 - exp(-25.0 * dt)
	px += (rp.x - px) * k
	pz += (rp.y - pz) * k
	py = rail_h(r, tc) - gr_h
	wvx = dv.x * gr_spd
	wvz = dv.y * gr_spd
	spd = -gr_spd if gr_fakie else gr_spd
	ws = spd
	gp = damp(gp, atan(slope), 20.0, dt)
	pitch = gp + th
	roll = damp(roll, roll_t, 8.0, dt)
	var rate := 160.0 if gr_kind == 0 else 200.0
	if gr_style != 0:
		rate += 70.0
	if gr_fakie:
		rate *= 1.35
	combo_pts += rate * dt
	combo_idle = 0.0
	if in_ly < -0.55:
		gr_pull = true
	if gr_jump_req or (gr_pull and in_ly > 0.3):
		end_grind(true)
		return
	if gr_t <= 0.0 or gr_t >= r.rlen or gr_spd < 0.8:
		end_grind(false)

func end_grind(jump: bool) -> void:
	var r: Rail = rails[gr_rail]
	var dv := Vector2(r.dx, r.dz) * gr_dir
	wvx = dv.x * gr_spd
	wvz = dv.y * gr_spd
	vy = 3.2 * k_jump if jump else 0.3
	gr_cool = 0.4
	gr_jump_req = false
	start_air(px, pz, py + 0.001)
	th = 0.0
	if jump:
		hop_t = 0.0
		rig_crouch = -0.3


func start_rider_fall() -> void:
	if rider_inst == null or rider_free:
		return
	var gt := rider_holder.global_transform
	rf_basis = gt.basis.orthonormalized()
	rf_com = gt * RF_COM
	var m := Vector3(wvx, 0.0, wvz)
	if m.length() < 0.5:
		var f := dir_of(yaw)
		m = Vector3(f.x, 0.0, f.y)
	m = m.normalized()
	rf_vel = Vector3(wvx, maxf(vy, 0.0) + 2.5, wvz) + m * 1.5
	var ax := Vector3(m.z, 0.0, -m.x)
	var sgn := 1.0 if pitch < 0.3 else -1.0
	rf_w = ax * sgn * (5.0 + randf() * 4.0) + Vector3(0.0, randf_range(-3.0, 3.0), 0.0)
	rf_t = 0.0
	rf_ground_t = 0.0
	rider_holder.reparent(self, true)
	rider_free = true

func rider_fall_step(dt: float) -> void:
	rf_t += dt
	rf_vel.y -= G * dt
	rf_com += rf_vel * dt
	var h := terrain_h(rf_com.x, rf_com.z)
	var on_ground := false
	if rf_com.y < h + RF_R:
		rf_com.y = h + RF_R
		on_ground = true
		if rf_vel.y < -1.5:
			rf_vel.y *= -0.25
			rf_w *= 0.6
		else:
			rf_vel.y = 0.0
	if on_ground:
		rf_ground_t += dt
		var k := exp(-3.0 * dt)
		rf_vel.x *= k
		rf_vel.z *= k
		rf_w *= exp(-5.0 * dt)
	rf_com.x = clampf(rf_com.x, -LIM, LIM)
	rf_com.z = clampf(rf_com.z, -LIM, LIM)
	var wl := rf_w.length()
	if wl > 0.001:
		rf_basis = (Basis(rf_w / wl, wl * dt) * rf_basis).orthonormalized()
	if rf_ground_t > 0.25:
		# ложимся: верх тела становится горизонтальным в ту сторону, куда он уже наклонён
		var u := rf_basis.y
		var hd := Vector3(u.x, 0.0, u.z)
		if hd.length() < 0.15:
			hd = Vector3(rf_vel.x, 0.0, rf_vel.z)
		if hd.length() < 0.1:
			hd = Vector3(1.0, 0.0, 0.0)
		hd = hd.normalized()
		var target := (Basis(Quaternion(u, hd)) * rf_basis).orthonormalized()
		var qs := Quaternion(rf_basis).slerp(Quaternion(target), 1.0 - exp(-5.0 * dt))
		rf_basis = Basis(qs)
	rider_holder.global_transform = Transform3D(rf_basis, rf_com - rf_basis * RF_COM)

func pose_limp() -> void:
	pov.clear()
	var to_skel := skel.global_transform.affine_inverse() * rider_holder.global_transform
	var amp := 1.0 if rf_ground_t <= 0.0 else exp(-1.4 * rf_ground_t)
	var ph := rf_t * 11.0
	for si in range(2):
		var side := 1.0 if si == 0 else -1.0
		var pre := "R" if si == 0 else "L"
		var upa := pre + "_UpperArm"
		var fa := pre + "_ForeArm"
		var hd := pre + "_Hand"
		var th1 := pre + "_Thigh"
		var calf := pre + "_Calf"
		var foot := pre + "_Foot"
		var du := Vector3(side * 0.9, -0.15 + 0.6 * amp * sin(ph + side), -0.15 + 0.5 * amp * cos(ph * 1.3 + side)).normalized()
		aim_bone(upa, fa, bpos(upa) + (to_skel.basis * du).normalized() * float(blen["uarm"]))
		var df := Vector3(side * 0.6, -0.4 + 0.7 * amp * sin(ph * 1.2 + side * 2.0), -0.3 + 0.5 * amp * cos(ph + side)).normalized()
		aim_bone(fa, hd, bpos(fa) + (to_skel.basis * df).normalized() * float(blen["farm"]))
		var dt1 := Vector3(side * (0.35 + 0.2 * amp * sin(ph * 0.9 + side)), -0.9, -0.2 * amp * cos(ph + side)).normalized()
		aim_bone(th1, calf, bpos(th1) + (to_skel.basis * dt1).normalized() * float(blen["thigh"]))
		var dc := Vector3(side * 0.15, -0.9, 0.35 * amp * sin(ph * 1.1 + side)).normalized()
		aim_bone(calf, foot, bpos(calf) + (to_skel.basis * dc).normalized() * float(blen["calf"]))
	apply_pose()


func add_air_trick(nm: String, pts: float) -> void:
	if takeoff_fakie:
		add_trick("Свитч " + nm, pts * 1.15)
	else:
		add_trick(nm, pts)

func start_footjam() -> void:
	var f := dir_of(yaw)
	sl_kind = 2
	sl_mv = atan2(-(f.y * spd), f.x * spd)
	sl_spd = absf(spd)
	fj_sign = 1.0 if spd >= 0.0 else -1.0
	fj_yaw0 = yaw
	fj_dir = -1.0 if in_lx > 0.2 else 1.0
	if absf(in_lx) <= 0.2:
		fj_dir = float(stance)
	fj_front = Vector2(px, pz) + f * FRONT_X
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("Футджем вип!", true)

func footjam_step(dt: float) -> void:
	sl_t += dt
	var p := clampf(sl_t / FJ_DUR, 0.0, 1.0)
	var e := p * p * (3.0 - 2.0 * p)
	var mvf := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 3.5 * dt)
	fj_front += mvf * sl_spd * dt
	yaw = fj_yaw0 + PI * fj_dir * e
	tw_ang = TAU * fj_dir * e
	var f2 := dir_of(yaw)
	var nc := fj_front - f2 * FRONT_X
	var hN := terrain_h(nc.x, nc.y)
	if hN > py + 0.38:
		sliding = false
		sl_kind = 0
		tw_ang = 0.0
		spd = 0.0
		return
	px = nc.x
	pz = nc.y
	py = hN
	wvx = mvf.x * sl_spd
	wvz = mvf.y * sl_spd
	spd = -sl_spd * fj_sign
	ws = sl_spd * 0.3
	steer_ang = damp(steer_ang, 0.0, 10.0, dt)
	gp = damp(gp, atan(slope_along(px, pz, yaw)), 25.0, dt)
	pitch = gp
	if p >= 1.0:
		end_footjam()

func end_footjam() -> void:
	sliding = false
	sl_kind = 0
	tw_ang = 0.0
	yaw = fj_yaw0 + PI * fj_dir
	spd = -fj_sign * maxf(sl_spd * 0.8, 2.0)
	add_trick("Футджем вип", 380.0)
	show_toast("Футджем вип!", true)

func stance_text() -> String:
	return "Стойка: правая нога вперёд" if stance > 0 else "Стойка: левая нога вперёд"

func _on_stance() -> void:
	stance = -stance
	stance_btn.text = stance_text()
	save_settings()

func dot_tex() -> ImageTexture:
	if dot_cache != null:
		return dot_cache
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for yy in range(48):
		for xx in range(48):
			var d := Vector2(float(xx) - 23.5, float(yy) - 23.5).length()
			img.set_pixel(xx, yy, Color(0.95, 0.95, 0.95, clampf(23.0 - d, 0.0, 1.0)))
	dot_cache = ImageTexture.create_from_image(img)
	return dot_cache

func style_slider(sl: HSlider) -> void:
	var t := dot_tex()
	sl.add_theme_icon_override("grabber", t)
	sl.add_theme_icon_override("grabber_highlight", t)
	sl.add_theme_icon_override("grabber_disabled", t)
	var tr := StyleBoxFlat.new()
	tr.bg_color = Color(1, 1, 1, 0.25)
	tr.set_corner_radius_all(6)
	tr.content_margin_top = 9
	tr.content_margin_bottom = 9
	sl.add_theme_stylebox_override("slider", tr)
	var ga := StyleBoxFlat.new()
	ga.bg_color = Color(0.45, 0.85, 0.5, 0.95)
	ga.set_corner_radius_all(6)
	ga.content_margin_top = 9
	ga.content_margin_bottom = 9
	sl.add_theme_stylebox_override("grabber_area", ga)
	sl.add_theme_stylebox_override("grabber_area_highlight", ga)

func _on_toggle_btn(v: bool, b: Button, text: String, cb: Callable) -> void:
	b.text = text + (":  ВКЛ" if v else ":  ВЫКЛ")
	cb.call(v)


func map_h(x: float, z: float) -> float:
	var ix := int(floor((x - HF_X0) / HF_CELL))
	var iz := int(floor((z - HF_Z0) / HF_CELL))
	if ix < 0 or ix >= HF_W or iz < 0 or iz >= HF_H:
		return 60.0
	var v := hf_data.decode_u16((iz * HF_W + ix) * 2)
	return HF_BASE + float(v - 1) * HF_SCALE

func add_rail_data(ax: float, ay: float, az: float, bx: float, by: float, bz: float) -> void:
	var r := Rail.new()
	r.ax = ax
	r.ay = ay
	r.az = az
	r.by = by
	var hl := Vector2(bx - ax, bz - az)
	r.rlen = hl.length()
	var dn := hl / r.rlen
	r.dx = dn.x
	r.dz = dn.y
	rails.append(r)

func build_map() -> bool:
	var sc = load(CITY_SCENE)
	if not (sc is PackedScene):
		push_warning("Не найдена карта " + CITY_SCENE)
		return false
	var bytes := FileAccess.get_file_as_bytes(CITY_HF)
	if bytes.size() != HF_W * HF_H * 2:
		push_warning("Карта высот не загрузилась, байт: " + str(bytes.size()))
		return false
	city_inst = (sc as PackedScene).instantiate()
	add_child(city_inst)
	# физика движка не нужна: рельеф и стены берём из карты высот
	for co in city_inst.find_children("*", "CollisionObject3D", true, false):
		co.queue_free()
	# дальние кварталы скрываем по расстоянию (рекомендация к карте)
	for blk in city_inst.find_children("Block_*", "Node3D", true, false):
		if blk is MeshInstance3D:
			(blk as MeshInstance3D).visibility_range_end = 230.0
		for mi in blk.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = 230.0
	hf_data = bytes
	hf_ok = true
	# 9 рейлов карты (найдены в её коллизиях): плоский на площади и 8 на лестницах
	add_rail_data(5.750, 3.310, -0.248, 10.750, 3.549, -0.252)
	add_rail_data(-94.752, 1.216, 13.520, -94.748, 1.810, 14.800)
	add_rail_data(-54.335, 4.100, -24.000, -54.331, 4.844, -22.400)
	add_rail_data(-44.252, 6.682, -102.480, -44.248, 7.276, -101.200)
	add_rail_data(-44.252, 0.422, 68.880, -44.248, 1.316, 70.800)
	add_rail_data(-7.500, 1.645, 117.252, -5.580, 2.539, 117.248)
	add_rail_data(-0.721, 7.887, -128.595, -0.717, 8.631, -126.995)
	add_rail_data(21.055, 4.137, 56.775, 21.059, 4.881, 58.375)
	add_rail_data(67.248, 4.602, 69.520, 67.252, 5.196, 70.800)
	return true

# =====================================================================
# ЗАПУСК И ГЛАВНЫЙ ЦИКЛ
# =====================================================================
func _ready() -> void:
	get_viewport().mesh_lod_threshold = 0.0
	load_settings()
	load_tweaks()
	load_layout()
	build_environment()
	if not build_map():
		build_ground()
		build_park()
	build_bike()
	build_ui()
	respawn(true)

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	poll_input(dt)
	if not (menu_open or edit_mode):
		acc_t += dt
		var n := 0
		while acc_t >= FIXED and n < 12:
			physics(FIXED)
			acc_t -= FIXED
			n += 1
		if n >= 12:
			acc_t = 0.0
		update_gameplay(dt)
	pose_visuals(dt)
	update_camera(dt)
	if toast_t > 0.0:
		toast_t -= dt
	if hint_t > 0.0:
		hint_t -= dt
	diag_t -= dt
	if diag_on and diag_t <= 0.0:
		update_diag()
		diag_t = 0.5
	if edit_mode:
		var nm := "Перетаскивайте кнопки пальцем"
		if edit_sel != "":
			nm = "Выбрано: " + String(KEY_RU[edit_sel])
		edit_lbl.text = nm
	hud.queue_redraw()
