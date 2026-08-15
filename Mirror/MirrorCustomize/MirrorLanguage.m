//
//  MirrorLanguage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import "MirrorLanguage.h"
#import "MirrorSettings.h"

#define ML(en, zh, es, fr, ja, ko) @[en, zh, es, fr, ja, ko]

@implementation MirrorLanguage

+ (NSString *)mirror_stringWithKey:(NSString *)key
{
    return [MirrorLanguage mirror_stringWithKey:key languageKey:[MirrorSettings preferredLanguageKey]];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key languageKey:(NSInteger)languageKey
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];
    
    // locale
    [mirrorDict setValue:ML(@"en", @"zh-Hans", @"es", @"fr", @"ja", @"ko") forKey:@"locale_Identifier"];
    
    // tabs
    [mirrorDict setValue:ML(@"Start", @"计时", @"Iniciar", @"Démarrer", @"開始", @"시작") forKey:@"start"];
    [mirrorDict setValue:ML(@"Today", @"今天", @"Hoy", @"Aujourd'hui", @"今日", @"오늘") forKey:@"today"];
    [mirrorDict setValue:ML(@"Yesterday", @"昨天", @"Ayer", @"Hier", @"昨日", @"어제") forKey:@"yesterday"];
    [mirrorDict setValue:ML(@"Tomorrow", @"明天", @"Mañana", @"Demain", @"明日", @"내일") forKey:@"tomorrow"];
    [mirrorDict setValue:ML(@"Calendar", @"日历", @"Calendario", @"Calendrier", @"カレンダー", @"캘린더") forKey:@"calendar"];
    [mirrorDict setValue:ML(@"Record", @"记录", @"Historial", @"Historique", @"記録", @"기록") forKey:@"record"];
    
    // Settings
    [mirrorDict setValue:ML(@"Language", @"语言", @"Idioma", @"Langue", @"言語", @"언어") forKey:@"language"];
    [mirrorDict setValue:ML(@"Use Chinese", @"使用中文", @"Usar chino", @"Utiliser le chinois", @"中国語を使う", @"중국어 사용") forKey:@"apply_chinese"];
    [mirrorDict setValue:ML(@"Weeks start on Monday", @"周一作为一周的第一天", @"Las semanas empiezan el lunes", @"Les semaines commencent le lundi", @"週の始まりを月曜日にする", @"월요일부터 주 시작") forKey:@"week_starts_on_Monday"];
    [mirrorDict setValue:ML(@"Show record indexes", @"展示记录的序号", @"Mostrar índices de registros", @"Afficher les index des enregistrements", @"記録番号を表示", @"기록 번호 표시") forKey:@"show_record_indexes"];
    [mirrorDict setValue:ML(@"Piechart on Record", @"记录页使用饼状图", @"Gráfico circular en Registro", @"Camembert dans Historique", @"記録で円グラフを表示", @"기록에 원형 차트 표시") forKey:@"show_piechart_on_record"];
    [mirrorDict setValue:ML(@"Heatmap on Record", @"记录页使用热力图", @"Mapa de calor en Registro", @"Carte thermique dans Historique", @"記録でヒートマップを表示", @"기록에 히트맵 표시") forKey:@"heatmap"];
    [mirrorDict setValue:ML(@"Download from iCloud", @"从 iCloud 下载", @"Descargar desde iCloud", @"Télécharger depuis iCloud", @"iCloudからダウンロード", @"iCloud에서 다운로드") forKey:@"download_from_icloud"];
    [mirrorDict setValue:ML(@"Download from iCloud?", @"确认从 iCloud 下载？", @"¿Descargar desde iCloud?", @"Télécharger depuis iCloud ?", @"iCloudからダウンロードしますか？", @"iCloud에서 다운로드할까요?") forKey:@"download_from_icloud_?"];
    [mirrorDict setValue:ML(@"There are %@ records on your iCloud. Downloading will replace your current data.", @"你的 iCloud 上有 %@ 条记录。下载后会替换当前数据。", @"Hay %@ registros en tu iCloud. La descarga reemplazará tus datos actuales.", @"Il y a %@ enregistrements sur votre iCloud. Le téléchargement remplacera vos données actuelles.", @"iCloudに%@件の記録があります。ダウンロードすると現在のデータが置き換えられます。", @"iCloud에 %@개의 기록이 있습니다. 다운로드하면 현재 데이터가 대체됩니다.") forKey:@"icloud_records_message"];
    [mirrorDict setValue:ML(@"There are %@ tasks, %@ records, and %@ special days on your iCloud.", @"您的 iCloud 上存在 %@ 个任务，%@ 条记录，%@ 个特别日。", @"Hay %@ tareas, %@ registros y %@ días especiales en tu iCloud.", @"Il y a %@ tâches, %@ enregistrements et %@ jours spéciaux sur votre iCloud.", @"iCloudに%@個のタスク、%@件の記録、%@件の特別な日があります。", @"iCloud에 %@개의 작업, %@개의 기록, %@개의 특별한 날이 있습니다.") forKey:@"icloud_summary_message"];
    [mirrorDict setValue:ML(@"Download", @"下载", @"Descargar", @"Télécharger", @"ダウンロード", @"다운로드") forKey:@"download"];
    [mirrorDict setValue:ML(@"No iCloud data", @"没有 iCloud 数据", @"No hay datos en iCloud", @"Aucune donnée iCloud", @"iCloudデータがありません", @"iCloud 데이터 없음") forKey:@"no_icloud_data"];
    [mirrorDict setValue:ML(@"No iCloud data was found. Example data will be generated.", @"没有找到 iCloud 数据，将生成示例数据。", @"No se encontraron datos de iCloud. Se generarán datos de ejemplo.", @"Aucune donnée iCloud trouvée. Des données d’exemple seront générées.", @"iCloudデータが見つかりませんでした。サンプルデータを生成します。", @"iCloud 데이터를 찾지 못했습니다. 예시 데이터가 생성됩니다.") forKey:@"no_icloud_data_generated_example_data_message"];
    [mirrorDict setValue:ML(@"Export/Import data", @"导出/导入数据", @"Exportar/importar datos", @"Exporter/importer les données", @"データの書き出し/読み込み", @"데이터 내보내기/가져오기") forKey:@"export_import_data"];
    [mirrorDict setValue:ML(@"Export or import data?", @"选择导入或是导出", @"¿Exportar o importar datos?", @"Exporter ou importer les données ?", @"データを書き出すか読み込みますか？", @"데이터를 내보내거나 가져올까요?") forKey:@"export_or_import"];
    [mirrorDict setValue:ML(@"Export data", @"导出数据", @"Exportar datos", @"Exporter les données", @"データを書き出す", @"데이터 내보내기") forKey:@"export_data"];
    [mirrorDict setValue:ML(@"Export JSON", @"导出 JSON", @"Exportar JSON", @"Exporter JSON", @"JSONを書き出す", @"JSON 내보내기") forKey:@"export_json"];
    [mirrorDict setValue:ML(@"Import data", @"导入数据", @"Importar datos", @"Importer les données", @"データを読み込む", @"데이터 가져오기") forKey:@"import_data"];
    [mirrorDict setValue:ML(@"Import JSON", @"导入 JSON", @"Importar JSON", @"Importer JSON", @"JSONを読み込む", @"JSON 가져오기") forKey:@"import_json"];
    [mirrorDict setValue:ML(@"Import data?", @"确认导入该数据？", @"¿Importar datos?", @"Importer les données ?", @"データを読み込みますか？", @"데이터를 가져올까요?") forKey:@"import_data_?"];
    [mirrorDict setValue:ML(@"Current data will be replaced by the imported data", @"导入后当前的数据将被覆盖", @"Los datos actuales serán reemplazados por los datos importados", @"Les données actuelles seront remplacées par les données importées", @"現在のデータは読み込んだデータで置き換えられます", @"현재 데이터가 가져온 데이터로 대체됩니다") forKey:@"import_data_?_message"];
    [mirrorDict setValue:ML(@"Import", @"导入", @"Importar", @"Importer", @"読み込む", @"가져오기") forKey:@"import"];
    [mirrorDict setValue:ML(@"Wrong data format", @"数据格式错误", @"Formato de datos incorrecto", @"Format de données incorrect", @"データ形式が正しくありません", @"데이터 형식이 잘못되었습니다") forKey:@"wrong_data_format"];
    [mirrorDict setValue:ML(@"OK", @"好的", @"OK", @"OK", @"OK", @"확인") forKey:@"ok"];
    [mirrorDict setValue:ML(@"Contact me", @"联系作者", @"Contáctame", @"Me contacter", @"連絡する", @"문의하기") forKey:@"contact_me"];
    [mirrorDict setValue:ML(@"Copy author's email address to clipboard", @"拷贝作者邮箱地址到剪切板", @"Copiar el correo del autor al portapapeles", @"Copier l'adresse e-mail de l'auteur", @"作者のメールアドレスをコピー", @"작성자 이메일 주소 복사") forKey:@"copy_email_address_to_clipboard"];
    [mirrorDict setValue:ML(@"Copy", @"拷贝", @"Copiar", @"Copier", @"コピー", @"복사") forKey:@"copy"];
    
    // Profile edit cell
    [mirrorDict setValue:ML(@"Save", @"保存", @"Guardar", @"Enregistrer", @"保存", @"저장") forKey:@"save"];
    [mirrorDict setValue:ML(@"Edit", @"编辑", @"Editar", @"Modifier", @"編集", @"편집") forKey:@"edit"];
    [mirrorDict setValue:ML(@"Remove", @"移掉", @"Quitar", @"Retirer", @"取り除く", @"제거") forKey:@"remove"];
    [mirrorDict setValue:ML(@"Delete", @"删除", @"Eliminar", @"Supprimer", @"削除", @"삭제") forKey:@"delete"];
    [mirrorDict setValue:ML(@"Merge", @"合并", @"Fusionar", @"Fusionner", @"結合", @"병합") forKey:@"merge"];
    [mirrorDict setValue:ML(@"Cancel", @"取消", @"Cancelar", @"Annuler", @"キャンセル", @"취소") forKey:@"cancel"];
    [mirrorDict setValue:ML(@"Add", @"添加", @"Añadir", @"Ajouter", @"追加", @"추가") forKey:@"add"];
    
    // Profile add cell
    [mirrorDict setValue:ML(@"Enter task title", @"输入任务名称", @"Ingresa el título de la tarea", @"Saisir le titre de la tâche", @"タスク名を入力", @"작업 제목 입력") forKey:@"enter_task_title"];
    [mirrorDict setValue:ML(@"Edit task", @"编辑任务", @"Editar tarea", @"Modifier la tâche", @"タスクを編集", @"작업 편집") forKey:@"edit_task"];
    [mirrorDict setValue:ML(@"Create a new task", @"创建新任务", @"Crear una nueva tarea", @"Créer une nouvelle tâche", @"新しいタスクを作成", @"새 작업 만들기") forKey:@"create_a_new_task"];
    [mirrorDict setValue:ML(@"Edit this task", @"编辑此任务", @"Editar esta tarea", @"Modifier cette tâche", @"このタスクを編集", @"이 작업 편집") forKey:@"edit_this_task"];
    [mirrorDict setValue:ML(@"Create", @"创建", @"Crear", @"Créer", @"作成", @"생성") forKey:@"create"];
    [mirrorDict setValue:ML(@"Discard", @"放弃", @"Descartar", @"Abandonner", @"破棄", @"취소") forKey:@"discard"];
    [mirrorDict setValue:ML(@"Untitled", @"未命名", @"Sin título", @"Sans titre", @"無題", @"제목 없음") forKey:@"untitled"];
    [mirrorDict setValue:ML(@"Enter a title to create a new task", @"输入名称以创建新的任务", @"Ingresa un título para crear una nueva tarea", @"Saisir un titre pour créer une tâche", @"新しいタスク名を入力", @"새 작업을 만들 제목 입력") forKey:@"add_taskname_hint"];
    [mirrorDict setValue:ML(@"Name field cannot be empty", @"任务名不能为空", @"El nombre no puede estar vacío", @"Le nom ne peut pas être vide", @"名前は空にできません", @"이름은 비워둘 수 없습니다") forKey:@"name_field_cannot_be_empty"];
    [mirrorDict setValue:ML(@"Gotcha", @"知道啦", @"Entendido", @"Compris", @"了解", @"알겠어요") forKey:@"gotcha"];
    [mirrorDict setValue:ML(@"Task cannot be duplicated", @"任务不可重复", @"La tarea no puede duplicarse", @"La tâche ne peut pas être dupliquée", @"タスクは重複できません", @"작업은 중복될 수 없습니다") forKey:@"task_cannot_be_duplicated"];
    [mirrorDict setValue:ML(@"This task exists in the current task list", @"这个任务已经存在于当前任务列表中", @"Esta tarea ya existe en la lista actual", @"Cette tâche existe déjà dans la liste actuelle", @"このタスクは現在のリストに存在します", @"이 작업은 현재 목록에 이미 있습니다") forKey:@"this_task_exists_in_current_task_list"];
    
    // Full screen
    [mirrorDict setValue:ML(@"Go!", @"开始!", @"¡Vamos!", @"C'est parti !", @"開始!", @"시작!") forKey:@"go"];
    [mirrorDict setValue:ML(@"Give up", @"放弃", @"Rendirse", @"Abandonner", @"あきらめる", @"포기") forKey:@"give_up"];
    [mirrorDict setValue:ML(@"Stop", @"结束", @"Finalizar", @"Terminer", @"終了", @"종료") forKey:@"stop"];
    
    // Task record
    [mirrorDict setValue:ML(@"Counting...", @"计时中...", @"Cronometrando...", @"Chronométrage...", @"計時中...", @"타이머 실행 중...") forKey:@"counting"];
    [mirrorDict setValue:ML(@"Lasted: ", @"持续时间：", @"Duración: ", @"Durée : ", @"経過時間: ", @"지속 시간: ") forKey:@"lasted"];
    
    // Delete period
    [mirrorDict setValue:ML(@"Delete this time period? ", @"确定删除这个时间段？", @"¿Eliminar este periodo?", @"Supprimer cette période ?", @"この時間帯を削除しますか？", @"이 시간대를 삭제할까요?") forKey:@"delete_period_?"];
    [mirrorDict setValue:ML(@"Ends at", @"结束于", @"Termina a las", @"Termine à", @"終了時刻", @"종료 시각") forKey:@"ends_at"];
    [mirrorDict setValue:ML(@"Note", @"备注", @"Nota", @"Note", @"メモ", @"메모") forKey:@"note"];
    
    // Time VC
    [mirrorDict setValue:ML(@"Long press a task to edit tasks", @"长按任务进入编辑模式", @"Mantén presionada una tarea para editar tareas", @"Appuyez longuement sur une tâche pour modifier les tâches", @"タスクを長押しして編集モードに入る", @"작업을 길게 눌러 편집 모드로 들어가세요") forKey:@"timeVC_hint0"];
    [mirrorDict setValue:ML(@"Long press in edit mode to reorder tasks", @"编辑模式下长按可以调整任务顺序", @"Mantén presionado en modo edición para reordenar tareas", @"Appuyez longuement en mode édition pour réordonner les tâches", @"編集モードで長押ししてタスクを並べ替え", @"편집 모드에서 길게 눌러 작업 순서를 변경하세요") forKey:@"timeVC_hint1"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"timeVC_hint2"];
    [mirrorDict setValue:ML(@"Tap timeline records to drag", @"轻点时间线记录可拖动", @"Toca registros para arrastrarlos", @"Touchez un enregistrement pour le déplacer", @"タイムライン記録をタップしてドラッグ", @"타임라인 기록을 탭해 드래그") forKey:@"timeVC_hint3"];
    [mirrorDict setValue:ML(@"Long press timeline records to delete", @"长按时间线记录可删除", @"Mantén registros para eliminarlos", @"Appuyez longuement pour supprimer", @"タイムライン記録を長押しして削除", @"타임라인 기록을 길게 눌러 삭제") forKey:@"timeVC_hint4"];
    
    // All tasks
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按拖动可以编辑顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替え", @"길게 눌러 작업 순서 변경") forKey:@"alltasks_hint0"];
    [mirrorDict setValue:ML(@"Tap task name to edit", @"轻点任务名可编辑", @"Toca el nombre para editar", @"Touchez le nom pour modifier", @"タスク名をタップして編集", @"작업 이름을 눌러 편집") forKey:@"alltasks_hint1"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"alltasks_hint3"];
    [mirrorDict setValue:ML(@"Delete this task? ", @"确定删除这个任务？", @"¿Eliminar esta tarea?", @"Supprimer cette tâche ?", @"このタスクを削除しますか？", @"이 작업을 삭제할까요?") forKey:@"delete_task_?"];
    [mirrorDict setValue:ML(@"This will permanently delete this task and all records inside it. This cannot be undone.", @"这会永久删除此任务以及其中的所有记录，且无法撤销。", @"Esto eliminará permanentemente esta tarea y todos sus registros. No se puede deshacer.", @"Cela supprimera définitivement cette tâche et tous ses enregistrements. Cette action est irréversible.", @"このタスクとそのすべての記録が完全に削除され、元に戻せません。", @"이 작업과 포함된 모든 기록이 영구 삭제되며 되돌릴 수 없습니다.") forKey:@"delete_task_warning"];
    [mirrorDict setValue:ML(@"Merge tasks?", @"合并任务？", @"¿Fusionar tareas?", @"Fusionner les tâches ?", @"タスクを結合しますか？", @"작업을 병합할까요?") forKey:@"merge_tasks_?"];
    [mirrorDict setValue:ML(@"This will merge the selected task into another task. This cannot be undone.", @"这会将所选任务合并到另一个任务，且无法撤销。", @"Esto fusionará la tarea seleccionada con otra tarea. No se puede deshacer.", @"Cela fusionnera la tâche sélectionnée avec une autre tâche. Cette action est irréversible.", @"選択したタスクを別のタスクに結合します。元に戻せません。", @"선택한 작업을 다른 작업에 병합하며 되돌릴 수 없습니다.") forKey:@"merge_task_warning"];
    [mirrorDict setValue:ML(@"Created at ", @"创建于 ", @"Creada el ", @"Créée le ", @"作成日 ", @"생성일 ") forKey:@"created_at"];
    
    // Special days
    [mirrorDict setValue:ML(@"Days", @"特别日", @"Días", @"Jours", @"日", @"날") forKey:@"special_days"];
    [mirrorDict setValue:ML(@"Add Special Day", @"添加特别日", @"Añadir día especial", @"Ajouter un jour spécial", @"特別な日を追加", @"특별한 날 추가") forKey:@"add_special_day"];
    [mirrorDict setValue:ML(@"Info", @"信息", @"Información", @"Info", @"情報", @"정보") forKey:@"special_day_info"];
    [mirrorDict setValue:ML(@"Icon", @"图标", @"Icono", @"Icône", @"アイコン", @"아이콘") forKey:@"special_day_icon"];
    [mirrorDict setValue:ML(@"No special days", @"暂无特别日", @"Sin días especiales", @"Aucun jour spécial", @"特別な日はありません", @"특별한 날 없음") forKey:@"no_special_days"];
    [mirrorDict setValue:ML(@"Only one special day can be added per day", @"一天只能添加一个特别日", @"Solo se puede añadir un día especial por fecha", @"Un seul jour spécial peut être ajouté par date", @"1日に追加できる特別な日は1つだけです", @"하루에 특별한 날은 하나만 추가할 수 있습니다") forKey:@"special_day_cannot_be_duplicated"];
    
    // Weekdays
    [mirrorDict setValue:ML(@"Sun", @"周日", @"Dom", @"Dim", @"日", @"일") forKey:@"sunday"];
    [mirrorDict setValue:ML(@"Mon", @"周一", @"Lun", @"Lun", @"月", @"월") forKey:@"monday"];
    [mirrorDict setValue:ML(@"Tue", @"周二", @"Mar", @"Mar", @"火", @"화") forKey:@"tuesday"];
    [mirrorDict setValue:ML(@"Wed", @"周三", @"Mié", @"Mer", @"水", @"수") forKey:@"wednesday"];
    [mirrorDict setValue:ML(@"Thu", @"周四", @"Jue", @"Jeu", @"木", @"목") forKey:@"thursday"];
    [mirrorDict setValue:ML(@"Fri", @"周五", @"Vie", @"Ven", @"金", @"금") forKey:@"friday"];
    [mirrorDict setValue:ML(@"Sat", @"周六", @"Sáb", @"Sam", @"土", @"토") forKey:@"saturday"];
    
    // Months
    [mirrorDict setValue:ML(@"Jan", @"1月", @"Ene", @"Jan", @"1月", @"1월") forKey:@"january"];
    [mirrorDict setValue:ML(@"Feb", @"2月", @"Feb", @"Fév", @"2月", @"2월") forKey:@"february"];
    [mirrorDict setValue:ML(@"Mar", @"3月", @"Mar", @"Mar", @"3月", @"3월") forKey:@"march"];
    [mirrorDict setValue:ML(@"Apr", @"4月", @"Abr", @"Avr", @"4月", @"4월") forKey:@"april"];
    [mirrorDict setValue:ML(@"May", @"5月", @"May", @"Mai", @"5月", @"5월") forKey:@"may"];
    [mirrorDict setValue:ML(@"Jun", @"6月", @"Jun", @"Juin", @"6月", @"6월") forKey:@"june"];
    [mirrorDict setValue:ML(@"Jul", @"7月", @"Jul", @"Juil", @"7月", @"7월") forKey:@"july"];
    [mirrorDict setValue:ML(@"Aug", @"8月", @"Ago", @"Août", @"8月", @"8월") forKey:@"august"];
    [mirrorDict setValue:ML(@"Sep", @"9月", @"Sep", @"Sep", @"9月", @"9월") forKey:@"september"];
    [mirrorDict setValue:ML(@"Oct", @"10月", @"Oct", @"Oct", @"10月", @"10월") forKey:@"october"];
    [mirrorDict setValue:ML(@"Nov", @"11月", @"Nov", @"Nov", @"11月", @"11월") forKey:@"november"];
    [mirrorDict setValue:ML(@"Dec", @"12月", @"Dic", @"Déc", @"12月", @"12월") forKey:@"december"];
    
    // Empty hints
    [mirrorDict setValue:ML(@"No data", @"暂无数据", @"Sin datos", @"Aucune donnée", @"データなし", @"데이터 없음") forKey:@"no_data"];
    [mirrorDict setValue:ML(@"Please create a task on the Start page first", @"请先去计时页面新建一个任务", @"Crea primero una tarea en la página Iniciar", @"Créez d'abord une tâche sur la page Démarrer", @"まず開始ページでタスクを作成してください", @"먼저 시작 페이지에서 작업을 만들어 주세요") forKey:@"no_task"];
    
    // Today total
    [mirrorDict setValue:ML(@"Total: ", @"总时长：", @"Total: ", @"Total : ", @"合計: ", @"합계: ") forKey:@"total"];
    
    // Time editing
    [mirrorDict setValue:ML(@"Starts at", @"开始于", @"Comienza a las", @"Commence à", @"開始時刻", @"시작 시각") forKey:@"starts_at"];
    [mirrorDict setValue:ML(@"OR", @"或", @"O", @"OU", @"または", @"또는") forKey:@"or"];
    [mirrorDict setValue:ML(@"Start now", @"开始计时", @"Empezar ahora", @"Commencer maintenant", @"今すぐ開始", @"지금 시작") forKey:@"start_now"];
    [mirrorDict setValue:ML(@"The current time is already covered by an existing record, so counting cannot start.", @"当前时间已被已有记录占用，无法开始计时。", @"La hora actual ya está cubierta por un registro existente, así que no se puede empezar a contar.", @"L’heure actuelle est déjà couverte par un enregistrement existant, le chronométrage ne peut pas démarrer.", @"現在時刻は既存の記録に含まれているため、計時を開始できません。", @"현재 시간이 기존 기록에 포함되어 있어 타이머를 시작할 수 없습니다.") forKey:@"current_time_occupied_cannot_start_counting"];
    [mirrorDict setValue:ML(@" hours", @" 小时", @" horas", @" heures", @" 時間", @"시간") forKey:@"picker_hours"];
    [mirrorDict setValue:ML(@" mins", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_mins"];
    [mirrorDict setValue:ML(@" hour", @" 小时", @" hora", @" heure", @" 時間", @"시간") forKey:@"picker_hour"];
    [mirrorDict setValue:ML(@" min", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_min"];
    
    // All records
    [mirrorDict setValue:ML(@"All records", @"所有记录", @"Todos los registros", @"Tous les enregistrements", @"すべての記録", @"모든 기록") forKey:@"all_records"];
    [mirrorDict setValue:ML(@"Records", @"记录", @"Registros", @"Enregistrements", @"記録", @"기록") forKey:@"records"];
    [mirrorDict setValue:ML(@"Check all records of %@ for %@?", @"查看 %@ 在 %@ 的所有记录？", @"¿Revisar todos los registros de %@ para %@?", @"Voir tous les enregistrements de %@ pour %@ ?", @"%@ の %@ のすべての記録を確認しますか？", @"%@의 %@ 모든 기록을 확인할까요?") forKey:@"check_task_records_for_period_?"];
    [mirrorDict setValue:ML(@"the year of %@", @"%@年", @"el año %@", @"l’année %@", @"%@年", @"%@년") forKey:@"period_year_format"];
    [mirrorDict setValue:ML(@"the week from %@ to %@", @"%@ 至 %@ 这一周", @"la semana del %@ al %@", @"la semaine du %@ au %@", @"%@ から %@ までの週", @"%@부터 %@까지의 주") forKey:@"period_week_format"];
    
    // Motto
    [mirrorDict setValue:ML(@"Something you want to keep in mind?", @"想记下来什么？", @"¿Algo que quieras recordar?", @"Quelque chose à garder en tête ?", @"覚えておきたいことは？", @"기억하고 싶은 것이 있나요?") forKey:@"motto"];
    
    return [MirrorLanguage localizedValue:[mirrorDict valueForKey:key] languageKey:languageKey fallback:key];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];

    // Time
    [mirrorDict setValue:ML(@"Pick a color for %@", @"为 %@ 选择颜色", @"Elige un color para %@", @"Choisir une couleur pour %@", @"%@ の色を選択", @"%@ 색상 선택") forKey:@"pick_color_for_task"];
    [mirrorDict setValue:ML(@"Merge %@ to", @"将 %@ 合并到", @"Fusionar %@ con", @"Fusionner %@ avec", @"%@ の結合先", @"%@ 병합 대상") forKey:@"merge_task_to"];
    [mirrorDict setValue:ML(@"%@h ", @"%@时", @"%@ h ", @"%@ h ", @"%@時間", @"%@시간") forKey:@"h"];
    [mirrorDict setValue:ML(@"%@m ", @"%@分", @"%@ min ", @"%@ min ", @"%@分", @"%@분") forKey:@"m"];
    [mirrorDict setValue:ML(@"%@s", @"%@秒", @"%@ s", @"%@ s", @"%@秒", @"%@초") forKey:@"s"];
    [mirrorDict setValue:ML(@"%@ hour ", @"%@小时", @"%@ hora ", @"%@ heure ", @"%@時間", @"%@시간") forKey:@"hour"];
    [mirrorDict setValue:ML(@"%@ min ", @"%@分钟", @"%@ min ", @"%@ min ", @"%@分", @"%@분") forKey:@"min"];
    [mirrorDict setValue:ML(@"%@ second", @"%@秒", @"%@ segundo", @"%@ seconde", @"%@秒", @"%@초") forKey:@"second"];
    [mirrorDict setValue:ML(@"%@ hours ", @"%@小时", @"%@ horas ", @"%@ heures ", @"%@時間", @"%@시간") forKey:@"hours"];
    [mirrorDict setValue:ML(@"%@ mins ", @"%@分钟", @"%@ min ", @"%@ min ", @"%@分", @"%@분") forKey:@"mins"];
    [mirrorDict setValue:ML(@"%@ seconds", @"%@秒", @"%@ segundos", @"%@ secondes", @"%@秒", @"%@초") forKey:@"seconds"];
    [mirrorDict setValue:ML(@"%@ reached the next record, so it was stopped automatically to avoid overlap.", @"%@ 已到达下一条记录的开始时间，为避免重叠，已自动停止。", @"%@ llegó al siguiente registro, así que se detuvo automáticamente para evitar solaparse.", @"%@ a atteint l’enregistrement suivant et s’est arrêté automatiquement pour éviter un chevauchement.", @"%@ は次の記録の開始時刻に達したため、重複を避けて自動停止しました。", @"%@이 다음 기록 시작 시간에 도달해 겹치지 않도록 자동 중지되었습니다.") forKey:@"counting_auto_stopped_due_to_next_record"];
    [mirrorDict setValue:ML(@"%@ reached the next record before 60 seconds, so it was cancelled to avoid overlap.", @"%@ 在满 60 秒前到达了下一条记录的开始时间，为避免重叠，已自动取消。", @"%@ llegó al siguiente registro antes de 60 segundos, así que se canceló para evitar solaparse.", @"%@ a atteint l’enregistrement suivant avant 60 secondes et a été annulé pour éviter un chevauchement.", @"%@ は60秒経過前に次の記録の開始時刻に達したため、重複を避けて自動キャンセルされました。", @"%@이 60초 전에 다음 기록 시작 시간에 도달해 겹치지 않도록 자동 취소되었습니다.") forKey:@"counting_auto_cancelled_due_to_next_record"];
    
    NSString *format = [MirrorLanguage localizedValue:[mirrorDict valueForKey:key] languageKey:[MirrorSettings preferredLanguageKey] fallback:key];
    return [NSString stringWithFormat:format, placeholder];
}

+ (NSString *)localizedValue:(NSArray<NSString *> *)translations languageKey:(NSInteger)languageKey fallback:(NSString *)fallback
{
    if (![translations isKindOfClass:NSArray.class] || translations.count == 0) {
        return fallback;
    }
    
    if (languageKey >= 0 && languageKey < translations.count) {
        return translations[languageKey];
    }
    
    return translations.firstObject;
}

@end
