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
    [mirrorDict setValue:ML(@"Calendar", @"日历", @"Calendario", @"Calendrier", @"カレンダー", @"캘린더") forKey:@"calendar"];
    [mirrorDict setValue:ML(@"Data", @"数据", @"Datos", @"Données", @"データ", @"데이터") forKey:@"data"];
    [mirrorDict setValue:ML(@"Record", @"记录", @"Historial", @"Historique", @"記録", @"기록") forKey:@"record"];
    
    // Settings
    [mirrorDict setValue:ML(@"Language", @"语言", @"Idioma", @"Langue", @"言語", @"언어") forKey:@"language"];
    [mirrorDict setValue:ML(@"Use Chinese", @"使用中文", @"Usar chino", @"Utiliser le chinois", @"中国語を使う", @"중국어 사용") forKey:@"apply_chinese"];
    [mirrorDict setValue:ML(@"Weeks start on Monday", @"周一作为一周的第一天", @"Las semanas empiezan el lunes", @"Les semaines commencent le lundi", @"週の始まりを月曜日にする", @"월요일부터 주 시작") forKey:@"week_starts_on_Monday"];
    [mirrorDict setValue:ML(@"Show record indexes", @"展示记录的序号", @"Mostrar índices de registros", @"Afficher les index des enregistrements", @"記録番号を表示", @"기록 번호 표시") forKey:@"show_record_indexes"];
    [mirrorDict setValue:ML(@"Piechart on Data", @"数据页使用饼状图", @"Gráfico circular en Datos", @"Camembert dans Données", @"データで円グラフを表示", @"데이터에 원형 차트 표시") forKey:@"show_piechart_on_data"];
    [mirrorDict setValue:ML(@"Piechart on Record", @"记录页使用饼状图", @"Gráfico circular en Registro", @"Camembert dans Historique", @"記録で円グラフを表示", @"기록에 원형 차트 표시") forKey:@"show_piechart_on_record"];
    [mirrorDict setValue:ML(@"Heatmap on Record", @"记录页使用热力图", @"Mapa de calor en Registro", @"Carte thermique dans Historique", @"記録でヒートマップを表示", @"기록에 히트맵 표시") forKey:@"heatmap"];
    [mirrorDict setValue:ML(@"Download from iCloud", @"从 iCloud 下载", @"Descargar desde iCloud", @"Télécharger depuis iCloud", @"iCloudからダウンロード", @"iCloud에서 다운로드") forKey:@"download_from_icloud"];
    [mirrorDict setValue:ML(@"Download from iCloud?", @"确认从 iCloud 下载？", @"¿Descargar desde iCloud?", @"Télécharger depuis iCloud ?", @"iCloudからダウンロードしますか？", @"iCloud에서 다운로드할까요?") forKey:@"download_from_icloud_?"];
    [mirrorDict setValue:ML(@"There are %@ records on your iCloud. Downloading will replace your current data.", @"你的 iCloud 上有 %@ 条记录。下载后会替换当前数据。", @"Hay %@ registros en tu iCloud. La descarga reemplazará tus datos actuales.", @"Il y a %@ enregistrements sur votre iCloud. Le téléchargement remplacera vos données actuelles.", @"iCloudに%@件の記録があります。ダウンロードすると現在のデータが置き換えられます。", @"iCloud에 %@개의 기록이 있습니다. 다운로드하면 현재 데이터가 대체됩니다.") forKey:@"icloud_records_message"];
    [mirrorDict setValue:ML(@"Detected %@ records from your iCloud. Do you want to download them?", @"检测到你的 iCloud 上有 %@ 条记录。要下载吗？", @"Se detectaron %@ registros en tu iCloud. ¿Quieres descargarlos?", @"%@ enregistrements ont été détectés dans votre iCloud. Voulez-vous les télécharger ?", @"iCloudに%@件の記録が見つかりました。ダウンロードしますか？", @"iCloud에서 %@개의 기록을 찾았습니다. 다운로드할까요?") forKey:@"icloud_records_detected_message"];
    [mirrorDict setValue:ML(@"There are %@ tasks and %@ records on your iCloud.", @"您的 iCloud 上存在 %@ 个任务，%@ 条记录。", @"Hay %@ tareas y %@ registros en tu iCloud.", @"Il y a %@ tâches et %@ enregistrements sur votre iCloud.", @"iCloudに%@個のタスクと%@件の記録があります。", @"iCloud에 %@개의 작업과 %@개의 기록이 있습니다.") forKey:@"icloud_summary_message"];
    [mirrorDict setValue:ML(@"Download", @"下载", @"Descargar", @"Télécharger", @"ダウンロード", @"다운로드") forKey:@"download"];
    [mirrorDict setValue:ML(@"No iCloud data", @"没有 iCloud 数据", @"No hay datos en iCloud", @"Aucune donnée iCloud", @"iCloudデータがありません", @"iCloud 데이터 없음") forKey:@"no_icloud_data"];
    [mirrorDict setValue:ML(@"Import example data?", @"导入示例数据？", @"¿Importar datos de ejemplo?", @"Importer des données d’exemple ?", @"サンプルデータを読み込みますか？", @"예시 데이터를 가져올까요?") forKey:@"import_example_data_?"];
    [mirrorDict setValue:ML(@"No iCloud records were found. You can start with one year of example records.", @"没有找到 iCloud 记录。你可以先导入一年的示例记录。", @"No se encontraron registros de iCloud. Puedes empezar con un año de registros de ejemplo.", @"Aucun enregistrement iCloud n’a été trouvé. Vous pouvez commencer avec un an d’exemples.", @"iCloudの記録は見つかりませんでした。1年分のサンプル記録から始められます。", @"iCloud 기록을 찾지 못했습니다. 1년치 예시 기록으로 시작할 수 있습니다.") forKey:@"import_example_data_message"];
    [mirrorDict setValue:ML(@"Example data is ready. When you're done learning the app, swipe right on a task to delete it.", @"示例数据已导入。熟悉 App 后，可以向右滑动任务来删除它。", @"Los datos de ejemplo están listos. Cuando termines de aprender la app, desliza una tarea hacia la derecha para eliminarla.", @"Les données d’exemple sont prêtes. Quand vous aurez terminé de découvrir l’app, faites glisser une tâche vers la droite pour la supprimer.", @"サンプルデータの準備ができました。アプリに慣れたら、タスクを右にスワイプして削除できます。", @"예시 데이터가 준비되었습니다. 앱 사용법을 익힌 뒤에는 작업을 오른쪽으로 밀어 삭제할 수 있습니다.") forKey:@"example_data_imported_message"];
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
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按可以调整任务顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替えられます", @"길게 눌러 작업 순서를 바꿀 수 있습니다") forKey:@"timeVC_hint0"];
    [mirrorDict setValue:ML(@"Swipe left to edit tasks", @"左滑可以编辑任务", @"Desliza a la izquierda para editar tareas", @"Balayez vers la gauche pour modifier les tâches", @"左にスワイプしてタスクを編集できます", @"왼쪽으로 밀어 작업을 편집할 수 있습니다") forKey:@"timeVC_hint1"];
    [mirrorDict setValue:ML(@"Swipe right to delete or merge tasks", @"右滑可以删除或合并任务", @"Desliza a la derecha para eliminar o fusionar tareas", @"Balayez vers la droite pour supprimer ou fusionner les tâches", @"右にスワイプしてタスクを削除または結合できます", @"오른쪽으로 밀어 작업을 삭제하거나 병합할 수 있습니다") forKey:@"timeVC_hint2"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"timeVC_hint3"];
    [mirrorDict setValue:ML(@"Tap timeline records to drag", @"轻点时间线记录可拖动", @"Toca registros para arrastrarlos", @"Touchez un enregistrement pour le déplacer", @"タイムライン記録をタップしてドラッグ", @"타임라인 기록을 탭해 드래그") forKey:@"timeVC_hint4"];
    [mirrorDict setValue:ML(@"Long press timeline records to delete", @"长按时间线记录可删除", @"Mantén registros para eliminarlos", @"Appuyez longuement pour supprimer", @"タイムライン記録を長押しして削除", @"타임라인 기록을 길게 눌러 삭제") forKey:@"timeVC_hint5"];
    
    // All tasks
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按拖动可以编辑顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替え", @"길게 눌러 작업 순서 변경") forKey:@"alltasks_hint0"];
    [mirrorDict setValue:ML(@"Tap task name to edit", @"轻点任务名可编辑", @"Toca el nombre para editar", @"Touchez le nom pour modifier", @"タスク名をタップして編集", @"작업 이름을 눌러 편집") forKey:@"alltasks_hint1"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"alltasks_hint3"];
    [mirrorDict setValue:ML(@"Delete this task? ", @"确定删除这个任务？", @"¿Eliminar esta tarea?", @"Supprimer cette tâche ?", @"このタスクを削除しますか？", @"이 작업을 삭제할까요?") forKey:@"delete_task_?"];
    [mirrorDict setValue:ML(@"This will permanently delete this task and all records inside it. This cannot be undone.", @"这会永久删除此任务以及其中的所有记录，且无法撤销。", @"Esto eliminará permanentemente esta tarea y todos sus registros. No se puede deshacer.", @"Cela supprimera définitivement cette tâche et tous ses enregistrements. Cette action est irréversible.", @"このタスクとそのすべての記録が完全に削除され、元に戻せません。", @"이 작업과 포함된 모든 기록이 영구 삭제되며 되돌릴 수 없습니다.") forKey:@"delete_task_warning"];
    [mirrorDict setValue:ML(@"Merge tasks?", @"合并任务？", @"¿Fusionar tareas?", @"Fusionner les tâches ?", @"タスクを結合しますか？", @"작업을 병합할까요?") forKey:@"merge_tasks_?"];
    [mirrorDict setValue:ML(@"This will merge the selected task into another task. This cannot be undone.", @"这会将所选任务合并到另一个任务，且无法撤销。", @"Esto fusionará la tarea seleccionada con otra tarea. No se puede deshacer.", @"Cela fusionnera la tâche sélectionnée avec une autre tâche. Cette action est irréversible.", @"選択したタスクを別のタスクに結合します。元に戻せません。", @"선택한 작업을 다른 작업에 병합하며 되돌릴 수 없습니다.") forKey:@"merge_task_warning"];
    [mirrorDict setValue:ML(@"Created at ", @"创建于 ", @"Creada el ", @"Créée le ", @"作成日 ", @"생성일 ") forKey:@"created_at"];
    
    // History type switch
    [mirrorDict setValue:ML(@"Day", @"日", @"Día", @"Jour", @"日", @"일") forKey:@"segment_day"];
    [mirrorDict setValue:ML(@"Week", @"周", @"Semana", @"Semaine", @"週", @"주") forKey:@"segment_week"];
    [mirrorDict setValue:ML(@"Month", @"月", @"Mes", @"Mois", @"月", @"월") forKey:@"segment_month"];
    [mirrorDict setValue:ML(@"Year", @"年", @"Año", @"Année", @"年", @"년") forKey:@"segment_year"];
    
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

+ (NSString *)localizedSampleTaskNameWithEnglishName:(NSString *)englishName
{
    return [MirrorLanguage localizedValue:[MirrorLanguage localizedSampleTaskNamesForEnglishName:englishName]
                              languageKey:[MirrorSettings preferredLanguageKey]
                                fallback:englishName];
}

+ (NSArray<NSString *> *)localizedSampleTaskNamesForEnglishName:(NSString *)englishName
{
    NSDictionary<NSString *, NSArray<NSString *> *> *taskNames = @{
        @"Gym": ML(@"Gym", @"健身", @"Gimnasio", @"Sport", @"ジム", @"운동"),
        @"Tennis": ML(@"Tennis", @"网球", @"Tenis", @"Tennis", @"テニス", @"테니스"),
        @"Code": ML(@"Code", @"编程", @"Programar", @"Coder", @"コーディング", @"코딩"),
        @"Swim": ML(@"Swim", @"游泳", @"Nadar", @"Natation", @"水泳", @"수영"),
        @"Read": ML(@"Read", @"阅读", @"Leer", @"Lire", @"読書", @"독서"),
        @"Study": ML(@"Study", @"学习", @"Estudiar", @"Étudier", @"勉強", @"공부")
    };
    return taskNames[englishName] ?: ML(englishName, englishName, englishName, englishName, englishName, englishName);
}

+ (NSString *)localizedSampleRecordNoteForEnglishTaskName:(NSString *)englishName index:(NSInteger)index
{
    NSDictionary<NSString *, NSArray<NSArray<NSString *> *> *> *notesByTask = @{
        @"Gym": @[
            ML(@"10 pull-ups, new best", @"引体向上10个，新高", @"10 dominadas, nuevo máximo", @"10 tractions, nouveau record", @"懸垂10回、自己新", @"풀업 10개, 신기록"),
            ML(@"cardio 30 minutes, burned 280 kcal", @"有氧30分钟，消耗280大卡", @"cardio 30 minutos, 280 kcal", @"cardio 30 minutes, 280 kcal brûlées", @"有酸素30分、280kcal消費", @"유산소 30분, 280kcal 소모"),
            ML(@"body fat 14.5%, down 0.3%", @"体脂14.5%，降了0.3%", @"grasa 14,5%, bajó 0,3%", @"masse grasse 14,5 %, -0,3 %", @"体脂肪14.5%、0.3%減", @"체지방 14.5%, 0.3% 감소"),
            ML(@"treadmill 5 km, pace 6", @"跑步机5公里，配速6", @"cinta 5 km, ritmo 6", @"tapis 5 km, allure 6", @"ランニングマシン5km、ペース6", @"러닝머신 5km, 페이스 6"),
            ML(@"dumbbell shoulder press 40kg, 3 sets", @"哑铃推举40kg，3组", @"press hombro mancuernas 40kg, 3 series", @"développé épaules haltères 40kg, 3 séries", @"ダンベルショルダープレス40kg、3セット", @"덤벨 숄더프레스 40kg, 3세트"),
            ML(@"lat pulldown 50kg, 4 sets", @"高位下拉50kg，4组", @"jalón al pecho 50kg, 4 series", @"tirage vertical 50kg, 4 séries", @"ラットプルダウン50kg、4セット", @"랫풀다운 50kg, 4세트"),
            ML(@"leg press 120kg, 4x12", @"腿举120kg，4组×12次", @"prensa de piernas 120kg, 4x12", @"presse à jambes 120kg, 4x12", @"レッグプレス120kg、4x12回", @"레그프레스 120kg, 4x12회"),
            ML(@"bench stuck at 80kg, try 85 next time", @"卧推卡80kg，下次冲85", @"press banca atascado en 80kg, próxima 85", @"développé couché bloqué à 80kg, tenter 85", @"ベンチ80kgで停滞、次は85狙い", @"벤치 80kg 정체, 다음엔 85 도전"),
            ML(@"plank 2 minutes, new record", @"平板支撑2分钟，破纪录", @"plancha 2 minutos, récord", @"gainage 2 minutes, record", @"プランク2分、自己記録更新", @"플랭크 2분, 기록 경신"),
            ML(@"cardio 40 minutes, burned 350 kcal", @"有氧40分钟，消耗350大卡", @"cardio 40 minutos, 350 kcal", @"cardio 40 minutes, 350 kcal brûlées", @"有酸素40分、350kcal消費", @"유산소 40분, 350kcal 소모"),
            ML(@"rowing machine 30 minutes, 2.5 km", @"划船机30分钟，2.5公里", @"remo 30 minutos, 2,5 km", @"rameur 30 minutes, 2,5 km", @"ローイングマシン30分、2.5km", @"로잉머신 30분, 2.5km"),
            ML(@"squat attempted 105kg, almost", @"深蹲冲105kg，差一点", @"intenté sentadilla 105kg, casi", @"squat tenté à 105kg, presque", @"スクワット105kg挑戦、あと少し", @"스쿼트 105kg 도전, 아깝다"),
            ML(@"body fat 15.2%, goal 14%", @"体脂15.2%，目标14%", @"grasa 15,2%, meta 14%", @"masse grasse 15,2 %, objectif 14 %", @"体脂肪15.2%、目標14%", @"체지방 15.2%, 목표 14%"),
            ML(@"200 crunches, finished in 4 sets", @"卷腹200个，分4组完成", @"200 abdominales, en 4 series", @"200 crunchs, en 4 séries", @"クランチ200回、4セットで完了", @"크런치 200개, 4세트 완료"),
            ML(@"seated row 45kg, 4 sets", @"坐姿划船45kg，4组", @"remo sentado 45kg, 4 series", @"rowing assis 45kg, 4 séries", @"シーテッドロー45kg、4セット", @"시티드 로우 45kg, 4세트"),
            ML(@"bench press 75kg, 5 sets done", @"卧推75kg，5组完成", @"press banca 75kg, 5 series hechas", @"développé couché 75kg, 5 séries faites", @"ベンチプレス75kg、5セット完了", @"벤치프레스 75kg, 5세트 완료"),
            ML(@"weighted pull-ups 5kg, 3 sets", @"引体向上负重5kg，3组", @"dominadas lastradas 5kg, 3 series", @"tractions lestées 5kg, 3 séries", @"加重懸垂5kg、3セット", @"중량 풀업 5kg, 3세트"),
        ],
        @"Tennis": @[
            ML(@"ran into Judy", @"偶遇Judy", @"me encontré con Judy", @"croisé Judy", @"Judyに偶然会った", @"Judy 우연히 만남"),
            ML(@"30 serves, first-serve rate 60%", @"发球练习30次，一发成功率60%", @"30 saques, 60% de primeros", @"30 services, 60 % de premières", @"サーブ30本、ファースト成功率60%", @"서브 30개, 첫 서브 성공률 60%"),
            ML(@"20 backhand slices, high net clearance", @"反手切削20次，过网率高", @"20 reveses cortados, alta tasa sobre la red", @"20 revers slicés, bon passage au filet", @"バックハンドスライス20本、ネット越え率高め", @"백핸드 슬라이스 20개, 네트 통과율 높음"),
            ML(@"baseline rally 15 minutes, long rallies", @"底线对拉15分钟，回合多", @"peloteo de fondo 15 minutos, muchos intercambios", @"échanges de fond 15 minutes, longs rallies", @"ベースラインラリー15分、ラリー多め", @"베이스라인 랠리 15분, 랠리 길었음"),
            ML(@"3 serve aces, small breakthrough", @"发球ACE球3个，小突破", @"3 aces de saque, pequeño avance", @"3 aces au service, petit progrès", @"サービスエース3本、小さな突破", @"서브 에이스 3개, 작은 돌파"),
            ML(@"30 down-the-line backhands, good quality", @"反手直线练习30次，质量不错", @"30 reveses paralelos, buena calidad", @"30 revers long de ligne, bonne qualité", @"バックハンドストレート30本、質よし", @"백핸드 다운더라인 30개, 질 좋음"),
            ML(@"20 net volleys, found the touch", @"网前截击20次，手感来了", @"20 voleas en la red, buen toque", @"20 volées au filet, bonnes sensations", @"ネットボレー20本、感触が出てきた", @"네트 발리 20개, 감 잡음"),
            ML(@"15 overheads, enough power", @"高压球15次，力量够了", @"15 remates, potencia suficiente", @"15 smashs, assez de puissance", @"スマッシュ15本、パワー十分", @"오버헤드 15개, 힘 충분"),
            ML(@"second-serve topspin, 70% in", @"二发上旋练习，进区率70%", @"segundo saque con topspin, 70% dentro", @"deuxième service lifté, 70 % dedans", @"セカンドのトップスピン練習、イン率70%", @"세컨 서브 탑스핀, 성공률 70%"),
            ML(@"forehand cross-court rally 20 minutes", @"正手斜线对拉20分钟", @"peloteo cruzado de derecha 20 minutos", @"diagonale coup droit 20 minutes", @"フォアクロスラリー20分", @"포핸드 크로스 랠리 20분"),
            ML(@"held serve 4 games, clear progress", @"发球局保发4局，进步明显", @"mantuve 4 juegos de saque, progreso claro", @"4 jeux de service tenus, progrès net", @"サービスゲーム4回キープ、進歩はっきり", @"서비스 게임 4번 킵, 확실히 발전"),
        ],
        @"Code": @[
            ML(@"Mirror line chart performance optimized", @"Mirror折线图性能优化完成", @"optimicé el rendimiento del gráfico de líneas de Mirror", @"performance du graphique en ligne de Mirror optimisée", @"Mirrorの折れ線グラフ性能最適化完了", @"Mirror 선 그래프 성능 최적화 완료"),
            ML(@"solved the dynamic programming knapsack problem", @"搞定动态规划背包问题", @"resolví el problema de mochila con programación dinámica", @"problème du sac à dos en programmation dynamique résolu", @"動的計画法のナップサック問題を解いた", @"동적 계획법 배낭 문제 해결"),
            ML(@"finished Mirror calendar month view", @"Mirror日历月视图写完了", @"terminé la vista mensual del calendario de Mirror", @"vue mensuelle du calendrier Mirror terminée", @"Mirrorカレンダー月表示を書き終えた", @"Mirror 캘린더 월간 뷰 완료"),
            ML(@"organized the binary search template", @"二分查找模板整理好了", @"organicé la plantilla de búsqueda binaria", @"modèle de recherche binaire rangé", @"二分探索テンプレートを整理", @"이분 탐색 템플릿 정리 완료"),
            ML(@"finished refactoring Mirror networking layer", @"Mirror网络层重构完了", @"terminé la refactorización de la capa de red de Mirror", @"couche réseau de Mirror refactorisée", @"Mirrorネットワーク層のリファクタ完了", @"Mirror 네트워크 계층 리팩터링 완료"),
            ML(@"solved a two-pointer algorithm problem", @"刷了道双指针算法题", @"hice un problema de dos punteros", @"exercice à deux pointeurs résolu", @"双ポインタの問題を1問解いた", @"투 포인터 알고리즘 문제 풀이"),
            ML(@"finished Mirror database migration", @"Mirror数据库迁移搞定", @"terminé la migración de base de datos de Mirror", @"migration de base de données Mirror terminée", @"Mirrorデータベース移行完了", @"Mirror 데이터베이스 마이그레이션 완료"),
            ML(@"finished binary tree level-order traversal", @"二叉树层序遍历写完了", @"terminé el recorrido por niveles del árbol binario", @"parcours en largeur d'un arbre binaire terminé", @"二分木のレベル順走査を書き終えた", @"이진 트리 레벨 순회 완료"),
            ML(@"Mirror chart Y-axis now adapts automatically", @"Mirror图表Y轴自适应了", @"el eje Y del gráfico de Mirror ahora se adapta", @"axe Y du graphique Mirror rendu adaptatif", @"MirrorグラフのY軸を自動調整にした", @"Mirror 차트 Y축 자동 조정 완료"),
            ML(@"solved the sliding window algorithm problem", @"滑动窗口算法题解出来了", @"resolví el problema de ventana deslizante", @"problème de fenêtre glissante résolu", @"スライディングウィンドウ問題を解いた", @"슬라이딩 윈도우 문제 해결"),
            ML(@"integrated Mirror local notifications", @"Mirror本地推送接入了", @"integré las notificaciones locales de Mirror", @"notifications locales de Mirror intégrées", @"Mirrorのローカル通知を組み込んだ", @"Mirror 로컬 알림 연동 완료"),
            ML(@"passed the topological sort problem", @"拓扑排序算法题过了", @"pasé el problema de ordenación topológica", @"exercice de tri topologique validé", @"トポロジカルソート問題を通した", @"위상 정렬 문제 통과"),
            ML(@"rebuilt the Mirror settings page", @"Mirror设置页重做了一遍", @"rehice la página de ajustes de Mirror", @"page réglages de Mirror refaite", @"Mirror設定画面を作り直した", @"Mirror 설정 페이지 재작업 완료"),
            ML(@"finished permutation backtracking", @"全排列回溯算法写完了", @"terminé backtracking de permutaciones", @"backtracking des permutations terminé", @"全順列バックトラックを書き終えた", @"순열 백트래킹 완료"),
            ML(@"dynamic programming", @"动态规划", @"programación dinámica", @"programmation dynamique", @"動的計画法", @"동적 계획법"),
            ML(@"passed the union-find problem", @"并查集算法题过了", @"pasé el problema de unión-búsqueda", @"exercice union-find validé", @"Union-Find問題を通した", @"유니온 파인드 문제 통과"),
            ML(@"finished the Mirror widget", @"Mirror小组件做完了", @"terminé el widget de Mirror", @"widget Mirror terminé", @"Mirrorウィジェット完成", @"Mirror 위젯 완료"),
            ML(@"finished greedy interval scheduling", @"贪心算法区间调度搞定了", @"terminé planificación de intervalos con greedy", @"ordonnancement d'intervalles glouton terminé", @"貪欲法の区間スケジューリング完了", @"그리디 구간 스케줄링 해결"),
            ML(@"optimized Mirror launch screen", @"Mirror启动页优化完了", @"optimicé la pantalla de inicio de Mirror", @"écran de lancement de Mirror optimisé", @"Mirror起動画面の最適化完了", @"Mirror 시작 화면 최적화 완료"),
            ML(@"finished the prefix sum algorithm problem", @"前缀和算法题写完了", @"terminé el problema de suma prefija", @"exercice de somme préfixe terminé", @"累積和の問題を書き終えた", @"누적합 알고리즘 문제 완료")
        ],
        @"Swim": @[
            ML(@"finished 1000m freestyle", @"自由泳1000米完成", @"1000 m de libre completados", @"1000 m nage libre terminés", @"自由形1000m完了", @"자유형 1000m 완료"),
            ML(@"found power in 50m butterfly", @"蝶泳50米发力找到了", @"encontré potencia en 50 m mariposa", @"puissance trouvée sur 50 m papillon", @"バタフライ50mで力の入れ方を掴んだ", @"접영 50m 힘 쓰는 감 찾음"),
            ML(@"IM, 50m each stroke", @"混合泳四种泳姿各50米", @"estilos combinados, 50 m cada uno", @"4 nages, 50 m chacune", @"個人メドレー4種目各50m", @"개인혼영 네 영법 각 50m"),
            ML(@"treading water for 5 minutes", @"踩水练习坚持了5分钟", @"5 minutos de flotación vertical", @"5 minutes de surplace dans l'eau", @"立ち泳ぎ5分キープ", @"입영 5분 버팀"),
            ML(@"freestyle breathing rhythm smoothed out", @"自由泳换气节奏顺了", @"ritmo de respiración libre más fluido", @"rythme de respiration en crawl plus fluide", @"自由形の呼吸リズムが整った", @"자유형 호흡 리듬 좋아짐"),
            ML(@"practiced 10 breaststroke turns", @"蛙泳转身练了10次", @"10 virajes de braza practicados", @"10 virages brasse travaillés", @"平泳ぎターン10回練習", @"평영 턴 10회 연습"),
            ML(@"freestyle flip turn finally clicked", @"自由泳翻滚转身练成了", @"por fin salió el viraje de libre", @"virage culbute en crawl enfin réussi", @"自由形のクイックターン成功", @"자유형 플립턴 성공"),
            ML(@"freestyle kick, 4 sets of 25m", @"自由泳打腿4组各25米", @"patada de libre, 4x25 m", @"battements crawl, 4x25 m", @"自由形キック25m×4本", @"자유형 킥 25m 4세트"),
            ML(@"broke down butterfly arm motion", @"蝶泳手部动作分解练了", @"desglosé el movimiento de brazos de mariposa", @"mouvement des bras en papillon décomposé", @"バタフライの腕動作を分解練習", @"접영 팔 동작 분해 연습"),
            ML(@"backstroke kick, 4 sets of 50m", @"仰泳打腿4组各50米", @"patada de espalda, 4x50 m", @"battements dos, 4x50 m", @"背泳ぎキック50m×4本", @"배영 킥 50m 4세트"),
            ML(@"improved high-elbow freestyle", @"自由泳高肘动作改进了", @"mejoré el codo alto en libre", @"coude haut en crawl amélioré", @"自由形のハイエルボー改善", @"자유형 하이엘보 개선"),
            ML(@"tried wave breaststroke, failed", @"尝试波蛙（失败）", @"probé braza ondulante, falló", @"brasse ondulée essayée, ratée", @"ウェーブ平泳ぎに挑戦、失敗", @"웨이브 평영 시도, 실패"),
            ML(@"finished 1500m long freestyle", @"自由泳1500米长距离完成", @"1500 m largos de libre completados", @"1500 m longue distance en crawl terminés", @"自由形1500m長距離完了", @"자유형 1500m 장거리 완료"),
            ML(@"practiced 10 dive starts", @"跳水出发练了10次", @"10 salidas de clavado practicadas", @"10 départs plongés travaillés", @"飛び込みスタート10回練習", @"다이빙 스타트 10회 연습"),
            ML(@"total swim volume today 2000m", @"今日总游量2000米", @"volumen total de hoy 2000 m", @"volume total aujourd'hui 2000 m", @"今日の総泳距離2000m", @"오늘 총 수영량 2000m")
        ],
        @"Read": @[
            ML(@"Karamazov Book I done", @"卡拉马佐夫第一卷", @"Karamázov libro I", @"Karamazov livre I", @"カラマーゾフ第1巻", @"카라마조프 1권"),
            ML(@"Anna Karenina p.50", @"安娜读到50页", @"Ana Karenina p.50", @"Anna p.50", @"アンナ50ページ", @"안나 50쪽"),
            ML(@"1984 Part I done", @"1984第一部", @"1984 parte I", @"1984 partie I", @"1984第1部", @"1984 1부"),
            ML(@"Animal Farm done", @"动物农场读完", @"Rebelión terminada", @"Ferme finie", @"動物農場読了", @"동물농장 완독"),
            ML(@"Grand Inquisitor done", @"宗教大法官读完", @"Gran Inquisidor", @"Grand Inquisiteur", @"大審問官読了", @"대심문관 완료"),
            ML(@"Anna race scene", @"安娜赛马场景", @"carrera de Ana", @"course d'Anna", @"アンナ競馬場面", @"안나 경마 장면"),
            ML(@"Winston's diary", @"温斯顿写日记", @"diario de Winston", @"journal de Winston", @"ウィンストン日記", @"윈스턴 일기"),
            ML(@"Seven Commandments", @"七诫背下了", @"Siete Mandamientos", @"Sept Commandements", @"七戒暗記", @"일곱 계명"),
            ML(@"Karamazov second brother", @"卡拉马佐夫二哥", @"segundo Karamázov", @"deuxième frère", @"カラマーゾフ次男", @"카라마조프 둘째"),
            ML(@"Anna train scene", @"安娜火车场景", @"tren de Ana", @"train d'Anna", @"アンナ列車場面", @"안나 기차 장면"),
            ML(@"1984 telescreen", @"1984电幕", @"telepantalla 1984", @"télécran 1984", @"1984テレスクリーン", @"1984 텔레스크린"),
            ML(@"Napoleon takes power", @"拿破仑掌权", @"Napoleón al poder", @"Napoléon au pouvoir", @"ナポレオン掌握", @"나폴레옹 집권"),
            ML(@"Zosima died", @"佐西马去世", @"murió Zósima", @"Zossime mort", @"ゾシマ死去", @"조시마 사망"),
            ML(@"Newspeak", @"新话概念", @"neolengua", @"novlangue", @"ニュースピーク", @"신어"),
            ML(@"Snowball expelled", @"雪球被赶走", @"Snowball expulsado", @"Boule de Neige chassé", @"スノーボール追放", @"스노볼 추방"),
            ML(@"Alyosha wavering", @"阿辽沙动摇", @"Aliosha duda", @"Aliocha vacille", @"アリョーシャ揺れる", @"알료샤 흔들림"),
            ML(@"Kitty rejects Levin", @"吉提拒绝列文", @"Kitty rechaza", @"Kitty refuse", @"キティ拒否", @"키티 거절"),
            ML(@"doublethink", @"双重思想", @"doblepensar", @"doublepensée", @"二重思考", @"이중사고"),
            ML(@"animals can't tell", @"动物分不清了", @"ya no distinguen", @"ne distinguent plus", @"見分け不能", @"구분 못함")
        ],
        @"Study": @[
            ML(@"limits reviewed", @"极限定义", @"límites", @"limites", @"極限定義", @"극한 정의"),
            ML(@"derivatives derived", @"导数公式", @"derivadas", @"dérivées", @"導関数公式", @"도함수 공식"),
            ML(@"Taylor x3", @"泰勒3题", @"Taylor x3", @"Taylor x3", @"テイラー3問", @"테일러 3문제"),
            ML(@"L'Hopital done", @"洛必达做完", @"L'Hopital listo", @"L'Hopital fini", @"ロピタル完了", @"로피탈 완료"),
            ML(@"20 integral formulas", @"20个积分公式", @"20 integrales", @"20 intégrales", @"積分公式20個", @"적분 공식 20개"),
            ML(@"definite integrals x5", @"定积分5题", @"integrales x5", @"intégrales x5", @"定積分5問", @"정적분 5문제"),
            ML(@"mean value theorem", @"中值定理", @"valor medio", @"valeur moyenne", @"平均値定理", @"평균값 정리"),
            ML(@"partials x10", @"偏导10题", @"parciales x10", @"partielles x10", @"偏微分10問", @"편도함수 10문제"),
            ML(@"total differential", @"全微分", @"diferencial total", @"différentielle totale", @"全微分", @"전미분"),
            ML(@"implicit x5", @"隐函数5题", @"implícitas x5", @"implicites x5", @"陰関数5問", @"음함수 5문제"),
            ML(@"polar double integral", @"二重积分极坐标", @"doble polar", @"double polaire", @"二重積分極座標", @"이중적분 극좌표"),
            ML(@"triple integrals x3", @"三重积分3题", @"triples x3", @"triples x3", @"三重積分3問", @"삼중적분 3문제"),
            ML(@"series tests", @"级数判别", @"series", @"séries", @"級数判定", @"급수 판정"),
            ML(@"power series", @"幂级数", @"series potencias", @"séries entières", @"冪級数", @"멱급수"),
            ML(@"Fourier series", @"傅里叶级数", @"Fourier", @"Fourier", @"フーリエ級数", @"푸리에 급수"),
            ML(@"linear independence", @"线性无关", @"independencia", @"indépendance", @"線形独立", @"선형독립"),
            ML(@"quadratic form", @"二次型", @"forma cuadrática", @"forme quadratique", @"二次形式", @"이차형"),
            ML(@"ODE x4", @"常微分4题", @"EDO x4", @"EDO x4", @"常微分4問", @"상미분 4문제"),
            ML(@"PDE separation", @"偏微分分离变量", @"EDP separación", @"EDP séparation", @"偏微分変数分離", @"편미분 변수분리")
        ]
    };
    NSArray<NSArray<NSString *> *> *notes = notesByTask[englishName] ?: notesByTask[@"Code"];
    if (notes.count == 0) {
        return @"";
    }
    NSInteger safeIndex = labs(index) % notes.count;
    return [MirrorLanguage localizedValue:notes[safeIndex]
                              languageKey:[MirrorSettings preferredLanguageKey]
                                fallback:notes[safeIndex].firstObject];
}

@end
