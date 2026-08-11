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
    [mirrorDict setValue:ML(@"Download", @"下载", @"Descargar", @"Télécharger", @"ダウンロード", @"다운로드") forKey:@"download"];
    [mirrorDict setValue:ML(@"No iCloud data", @"没有 iCloud 数据", @"No hay datos en iCloud", @"Aucune donnée iCloud", @"iCloudデータがありません", @"iCloud 데이터 없음") forKey:@"no_icloud_data"];
    [mirrorDict setValue:ML(@"Import example data?", @"导入示例数据？", @"¿Importar datos de ejemplo?", @"Importer des données d’exemple ?", @"サンプルデータを読み込みますか？", @"예시 데이터를 가져올까요?") forKey:@"import_example_data_?"];
    [mirrorDict setValue:ML(@"No iCloud records were found. You can start with one year of example records.", @"没有找到 iCloud 记录。你可以先导入一年的示例记录。", @"No se encontraron registros de iCloud. Puedes empezar con un año de registros de ejemplo.", @"Aucun enregistrement iCloud n’a été trouvé. Vous pouvez commencer avec un an d’exemples.", @"iCloudの記録は見つかりませんでした。1年分のサンプル記録から始められます。", @"iCloud 기록을 찾지 못했습니다. 1년치 예시 기록으로 시작할 수 있습니다.") forKey:@"import_example_data_message"];
    [mirrorDict setValue:ML(@"Example data is ready. When you're done learning the app, swipe right on a task to delete it.", @"示例数据已导入。熟悉 App 后，可以向右滑动任务来删除它。", @"Los datos de ejemplo están listos. Cuando termines de aprender la app, desliza una tarea hacia la derecha para eliminarla.", @"Les données d’exemple sont prêtes. Quand vous aurez terminé de découvrir l’app, faites glisser une tâche vers la droite pour la supprimer.", @"サンプルデータの準備ができました。アプリに慣れたら、タスクを右にスワイプして削除できます。", @"예시 데이터가 준비되었습니다. 앱 사용법을 익힌 뒤에는 작업을 오른쪽으로 밀어 삭제할 수 있습니다.") forKey:@"example_data_imported_message"];
    [mirrorDict setValue:ML(@"Export/Import data", @"导出/导入数据", @"Exportar/importar datos", @"Exporter/importer les données", @"データの書き出し/読み込み", @"데이터 내보내기/가져오기") forKey:@"export_import_data"];
    [mirrorDict setValue:ML(@"Export or import data?", @"选择导入或是导出", @"¿Exportar o importar datos?", @"Exporter ou importer les données ?", @"データを書き出すか読み込みますか？", @"데이터를 내보내거나 가져올까요?") forKey:@"export_or_import"];
    [mirrorDict setValue:ML(@"Export data", @"导出数据", @"Exportar datos", @"Exporter les données", @"データを書き出す", @"데이터 내보내기") forKey:@"export_data"];
    [mirrorDict setValue:ML(@"Import data", @"导入数据", @"Importar datos", @"Importer les données", @"データを読み込む", @"데이터 가져오기") forKey:@"import_data"];
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
    [mirrorDict setValue:ML(@"Edit task title", @"编辑任务名称", @"Edita el título de la tarea", @"Modifier le titre de la tâche", @"タスク名を編集", @"작업 제목 편집") forKey:@"edit_task_title"];
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
    [mirrorDict setValue:ML(@"Ends at", @"结束于", @"Termina a las", @"Se termine à", @"終了時刻", @"종료 시간") forKey:@"ends_at"];
    [mirrorDict setValue:ML(@"Note", @"备注", @"Nota", @"Note", @"メモ", @"메모") forKey:@"note"];
    
    // Time VC
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按可以调整任务顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替えられます", @"길게 눌러 작업 순서를 바꿀 수 있습니다") forKey:@"timeVC_hint0"];
    [mirrorDict setValue:ML(@"Swipe left to edit tasks", @"左滑可以编辑任务", @"Desliza a la izquierda para editar tareas", @"Balayez vers la gauche pour modifier les tâches", @"左にスワイプしてタスクを編集できます", @"왼쪽으로 밀어 작업을 편집할 수 있습니다") forKey:@"timeVC_hint1"];
    [mirrorDict setValue:ML(@"Swipe right to delete or merge tasks", @"右滑可以删除或合并任务", @"Desliza a la derecha para eliminar o fusionar tareas", @"Balayez vers la droite pour supprimer ou fusionner les tâches", @"右にスワイプしてタスクを削除または結合できます", @"오른쪽으로 밀어 작업을 삭제하거나 병합할 수 있습니다") forKey:@"timeVC_hint2"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"timeVC_hint3"];
    
    // All tasks
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按拖动可以编辑顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替え", @"길게 눌러 작업 순서 변경") forKey:@"alltasks_hint0"];
    [mirrorDict setValue:ML(@"Tap task name to edit", @"轻点任务名可编辑", @"Toca el nombre para editar", @"Touchez le nom pour modifier", @"タスク名をタップして編集", @"작업 이름을 눌러 편집") forKey:@"alltasks_hint1"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"alltasks_hint3"];
    [mirrorDict setValue:ML(@"Delete this task? ", @"确定删除这个任务？", @"¿Eliminar esta tarea?", @"Supprimer cette tâche ?", @"このタスクを削除しますか？", @"이 작업을 삭제할까요?") forKey:@"delete_task_?"];
    [mirrorDict setValue:ML(@"This will permanently delete this task and all records inside it. This cannot be undone.", @"这会永久删除此任务以及其中的所有记录，且无法撤销。", @"Esto eliminará permanentemente esta tarea y todos sus registros. No se puede deshacer.", @"Cela supprimera définitivement cette tâche et tous ses enregistrements. Cette action est irréversible.", @"このタスクとそのすべての記録が完全に削除され、元に戻せません。", @"이 작업과 포함된 모든 기록이 영구 삭제되며 되돌릴 수 없습니다.") forKey:@"delete_task_warning"];
    [mirrorDict setValue:ML(@"Merge tasks?", @"合并任务？", @"¿Fusionar tareas?", @"Fusionner les tâches ?", @"タスクを結合しますか？", @"작업을 병합할까요?") forKey:@"merge_tasks_?"];
    [mirrorDict setValue:ML(@"This will merge the selected task into another task. This cannot be undone.", @"这会将所选任务合并到另一个任务，且无法撤销。", @"Esto fusionará la tarea seleccionada con otra tarea. No se puede deshacer.", @"Cela fusionnera la tâche sélectionnée avec une autre tâche. Cette action est irréversible.", @"選択したタスクを別のタスクに結合します。元に戻せません。", @"선택한 작업을 다른 작업에 병합하며 되돌릴 수 없습니다.") forKey:@"merge_task_warning"];
    [mirrorDict setValue:ML(@"Created at ", @"创建于 ", @"Creada el ", @"Créée le ", @"作成日 ", @"생성일 ") forKey:@"created_at"];
    [mirrorDict setValue:ML(@"Edit tasks", @"编辑任务", @"Editar tareas", @"Modifier les tâches", @"タスクを編集", @"작업 편집") forKey:@"edit_tasks"];
    
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
    [mirrorDict setValue:ML(@"Starts at", @"开始时间", @"Empieza a las", @"Commence à", @"開始時刻", @"시작 시간") forKey:@"starts_at"];
    [mirrorDict setValue:ML(@"OR", @"或", @"O", @"OU", @"または", @"또는") forKey:@"or"];
    [mirrorDict setValue:ML(@"A current or future time period is already occupied, so Start Now is unavailable", @"当前或未来时间段已被其他记录占用，无法立即开始计时", @"Ya hay un periodo actual o futuro ocupado, así que no se puede empezar ahora", @"Une période actuelle ou future est déjà occupée, le démarrage immédiat est indisponible", @"現在または未来の時間帯がすでに使用中のため、今すぐ開始できません", @"현재 또는 미래 시간대가 이미 사용 중이라 지금 시작할 수 없습니다") forKey:@"now_is_occupied"];
    [mirrorDict setValue:ML(@"Check occupied records", @"查看占用记录", @"Revisar registros ocupados", @"Voir les enregistrements occupés", @"使用中の記録を確認", @"점유된 기록 확인") forKey:@"check_occupied_records"];
    [mirrorDict setValue:ML(@"Start now", @"开始计时", @"Empezar ahora", @"Commencer maintenant", @"今すぐ開始", @"지금 시작") forKey:@"start_now"];
    [mirrorDict setValue:ML(@" hours", @" 小时", @" horas", @" heures", @" 時間", @"시간") forKey:@"picker_hours"];
    [mirrorDict setValue:ML(@" mins", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_mins"];
    [mirrorDict setValue:ML(@" hour", @" 小时", @" hora", @" heure", @" 時間", @"시간") forKey:@"picker_hour"];
    [mirrorDict setValue:ML(@" min", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_min"];
    
    // All records
    [mirrorDict setValue:ML(@"All records", @"所有记录", @"Todos los registros", @"Tous les enregistrements", @"すべての記録", @"모든 기록") forKey:@"all_records"];
    [mirrorDict setValue:ML(@"Records", @"记录", @"Registros", @"Enregistrements", @"記録", @"기록") forKey:@"records"];
    [mirrorDict setValue:ML(@"Occupied records", @"占用记录", @"Registros ocupados", @"Enregistrements occupés", @"使用中の記録", @"점유된 기록") forKey:@"occupied_records"];
    [mirrorDict setValue:ML(@"Clear future records to start counting", @"清空未来记录以便开启计时功能", @"Borrar registros futuros para empezar a contar", @"Effacer les futurs enregistrements pour démarrer", @"計時を開始するため未来の記録を消去", @"타이머를 시작하려면 미래 기록 지우기") forKey:@"delete_future_records_to_start_counting"];
    [mirrorDict setValue:ML(@"Delete all records after now?", @"删除当前时间之后的所有记录？", @"¿Eliminar todos los registros posteriores a ahora?", @"Supprimer tous les enregistrements après maintenant ?", @"今以降のすべての記録を削除しますか？", @"지금 이후의 모든 기록을 삭제할까요?") forKey:@"delete_future_records_?"];
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
            ML(@"leg day", @"练腿日", @"día de piernas", @"jambes", @"脚の日", @"하체 운동"),
            ML(@"bench press sets", @"卧推组", @"series de press banca", @"séries de développé couché", @"ベンチプレス", @"벤치프레스 세트"),
            ML(@"stretching and core", @"拉伸和核心", @"estiramientos y core", @"étirements et gainage", @"ストレッチと体幹", @"스트레칭과 코어"),
            ML(@"too crowded, short session", @"人太多，缩短训练", @"muy lleno, sesión corta", @"trop de monde, séance courte", @"混んでいて短め", @"사람이 많아서 짧게"),
            ML(@"deadlift form check", @"硬拉动作检查", @"revisé técnica de peso muerto", @"technique du soulevé de terre", @"デッドリフトフォーム確認", @"데드리프트 자세 확인"),
            ML(@"easy treadmill run", @"轻松跑步机", @"cinta suave", @"tapis tranquille", @"軽めのランニングマシン", @"가벼운 러닝머신"),
            ML(@"shoulder rehab work", @"肩部康复训练", @"rehab de hombro", @"rééducation épaule", @"肩のリハビリ", @"어깨 재활 운동"),
            ML(@"pull-ups felt strong", @"引体向上状态好", @"dominadas fuertes", @"tractions solides", @"懸垂が好調", @"풀업 컨디션 좋음"),
            ML(@"skipped cardio", @"跳过有氧", @"salté cardio", @"cardio sauté", @"有酸素は省略", @"유산소 생략"),
            ML(@"new squat weight", @"深蹲加重量", @"nuevo peso en sentadilla", @"nouvelle charge squat", @"スクワット重量更新", @"스쿼트 중량 올림"),
            ML(@"foam rolling after", @"结束后泡沫轴", @"foam roller después", @"rouleau après", @"終わってフォームローラー", @"마무리 폼롤러"),
            ML(@"quick hotel gym", @"酒店健身房快练", @"gimnasio del hotel rápido", @"salle hôtel rapide", @"ホテルジムで短時間", @"호텔 헬스장 짧게"),
            ML(@"arms and abs", @"手臂和腹部", @"brazos y abdominales", @"bras et abdos", @"腕と腹筋", @"팔과 복근"),
            ML(@"trainer session", @"私教课", @"sesión con entrenador", @"séance coach", @"トレーナーセッション", @"트레이너 수업"),
            ML(@"mobility only", @"只做灵活性", @"solo movilidad", @"mobilité seulement", @"可動域だけ", @"가동성 운동만"),
            ML(@"ran into Sam", @"遇到 Sam", @"me encontré con Sam", @"croisé Sam", @"Sam に会った", @"Sam 만남"),
            ML(@"bad sleep, lighter weights", @"没睡好，减重量", @"mal sueño, menos peso", @"mal dormi, plus léger", @"寝不足で軽め", @"잠 부족해서 가볍게"),
            ML(@"hit all planned sets", @"完成所有计划组", @"hice todas las series", @"toutes les séries faites", @"予定セット完了", @"계획 세트 완료"),
            ML(@"forgot water bottle", @"忘带水杯", @"olvidé la botella", @"gourde oubliée", @"水筒を忘れた", @"물병 깜빡함")
        ],
        @"Tennis": @[
            ML(@"serve practice", @"发球练习", @"práctica de saque", @"service", @"サーブ練習", @"서브 연습"),
            ML(@"backhand drills", @"反手训练", @"ejercicios de revés", @"revers", @"バックハンド練習", @"백핸드 훈련"),
            ML(@"friendly match with Alex", @"和 Alex 友谊赛", @"partido amistoso con Alex", @"match amical avec Alex", @"Alex と練習試合", @"Alex와 친선 경기"),
            ML(@"windy court, lots of mistakes", @"场地风大，失误很多", @"cancha con viento, muchos errores", @"court venteux, beaucoup d'erreurs", @"風が強くミス多め", @"바람이 세서 실수 많음"),
            ML(@"forehand cross-court", @"正手斜线", @"derecha cruzada", @"coup droit croisé", @"フォアのクロス", @"포핸드 크로스"),
            ML(@"tiebreak practice", @"抢七练习", @"práctica de tie-break", @"tie-break", @"タイブレーク練習", @"타이브레이크 연습"),
            ML(@"worked on footwork", @"练步伐", @"trabajé el juego de pies", @"jeu de jambes", @"フットワーク練習", @"풋워크 연습"),
            ML(@"volleys at the net", @"网前截击", @"voleas en la red", @"volées au filet", @"ネットボレー", @"네트 발리"),
            ML(@"new grip felt odd", @"新握拍不太习惯", @"nuevo grip raro", @"nouveau grip étrange", @"新しいグリップ違和感", @"새 그립 어색함"),
            ML(@"lost first set", @"输掉第一盘", @"perdí el primer set", @"premier set perdu", @"第1セット落とした", @"첫 세트 패배"),
            ML(@"serve finally clicked", @"发球终于顺了", @"el saque por fin salió", @"service enfin trouvé", @"サーブがやっと合った", @"서브 감 잡음"),
            ML(@"rally consistency", @"多拍稳定性", @"consistencia en peloteos", @"régularité en échange", @"ラリー安定", @"랠리 안정감"),
            ML(@"court lights were harsh", @"场灯太刺眼", @"luces muy fuertes", @"lumières trop fortes", @"照明がまぶしい", @"조명이 눈부심"),
            ML(@"short balls practice", @"短球练习", @"bolas cortas", @"balles courtes", @"短い球の練習", @"짧은 공 연습"),
            ML(@"doubles rotation", @"双打轮转", @"rotación de dobles", @"rotation double", @"ダブルスローテーション", @"복식 로테이션"),
            ML(@"slice backhand", @"反手削球", @"revés cortado", @"revers slicé", @"バックハンドスライス", @"백핸드 슬라이스"),
            ML(@"too hot after noon", @"中午后太热", @"demasiado calor después del mediodía", @"trop chaud après midi", @"昼過ぎは暑すぎ", @"오후엔 너무 더움"),
            ML(@"coach changed my toss", @"教练改了抛球", @"el coach cambió mi lanzamiento", @"coach a changé mon lancer", @"トスを直された", @"코치가 토스 수정"),
            ML(@"solid closing game", @"收尾局打得稳", @"buen juego final", @"dernier jeu solide", @"最後のゲーム安定", @"마지막 게임 안정적")
        ],
        @"Code": @[
            ML(@"dynamic programming practice", @"动态规划练习", @"práctica de programación dinámica", @"programmation dynamique", @"動的計画法の練習", @"동적 계획법 연습"),
            ML(@"Project X login flow", @"Project X 登录流程", @"flujo de inicio de Project X", @"connexion de Project X", @"Project X のログイン", @"Project X 로그인 흐름"),
            ML(@"fixed calendar bug", @"修了日历问题", @"arreglé bug del calendario", @"bug calendrier corrigé", @"カレンダーの不具合修正", @"캘린더 버그 수정"),
            ML(@"easy UI cleanup", @"简单 UI 清理", @"limpieza sencilla de UI", @"nettoyage UI simple", @"簡単な UI 整理", @"간단한 UI 정리"),
            ML(@"refactored storage layer", @"重构存储层", @"refactoricé almacenamiento", @"refactor stockage", @"保存層をリファクタ", @"저장 계층 리팩터링"),
            ML(@"debugged sync issue", @"调试同步问题", @"depuré problema de sincronización", @"débogage synchro", @"同期問題をデバッグ", @"동기화 문제 디버그"),
            ML(@"wrote unit tests", @"写单元测试", @"escribí pruebas unitarias", @"tests unitaires", @"単体テスト作成", @"유닛 테스트 작성"),
            ML(@"API error handling", @"API 错误处理", @"manejo de errores API", @"gestion erreurs API", @"API エラー処理", @"API 오류 처리"),
            ML(@"reviewed pull request", @"看代码评审", @"revisé pull request", @"revue de PR", @"PR レビュー", @"PR 리뷰"),
            ML(@"fixed layout on iPad", @"修 iPad 布局", @"arreglé layout en iPad", @"layout iPad corrigé", @"iPad レイアウト修正", @"iPad 레이아웃 수정"),
            ML(@"database migration", @"数据库迁移", @"migración de base de datos", @"migration base de données", @"DB マイグレーション", @"DB 마이그레이션"),
            ML(@"slow build investigation", @"排查构建慢", @"investigué build lento", @"build lent analysé", @"遅いビルド調査", @"느린 빌드 조사"),
            ML(@"renamed confusing methods", @"重命名混乱方法", @"renombré métodos confusos", @"méthodes renommées", @"紛らわしいメソッド改名", @"헷갈리는 메서드 이름 변경"),
            ML(@"prototype for new widget", @"新组件原型", @"prototipo de widget", @"prototype widget", @"新ウィジェット試作", @"새 위젯 프로토타입"),
            ML(@"fixed timezone edge case", @"修时区边界问题", @"arreglé caso de zona horaria", @"cas fuseau horaire corrigé", @"タイムゾーン境界修正", @"시간대 엣지 케이스 수정"),
            ML(@"read framework docs", @"读框架文档", @"leí documentación", @"lecture docs framework", @"フレームワーク文書確認", @"프레임워크 문서 읽음"),
            ML(@"deleted dead code", @"删除废代码", @"eliminé código muerto", @"code mort supprimé", @"不要コード削除", @"죽은 코드 삭제"),
            ML(@"performance profiling", @"性能分析", @"perfilado de rendimiento", @"profilage performance", @"パフォーマンス計測", @"성능 프로파일링"),
            ML(@"pairing session", @"结对编程", @"sesión en pareja", @"pair programming", @"ペア作業", @"페어 프로그래밍"),
            ML(@"fixed flaky test", @"修不稳定测试", @"arreglé prueba inestable", @"test instable corrigé", @"不安定テスト修正", @"불안정 테스트 수정")
        ],
        @"Swim": @[
            ML(@"butterfly stroke", @"蝶泳", @"mariposa", @"papillon", @"バタフライ", @"접영"),
            ML(@"crawl laps", @"自由泳往返", @"vueltas de crol", @"longueurs en crawl", @"クロール周回", @"자유형 랩"),
            ML(@"kickboard drills", @"浮板打腿", @"ejercicios con tabla", @"battements avec planche", @"ビート板練習", @"킥판 훈련"),
            ML(@"too tired to continue", @"太累了，没继续", @"demasiado cansado para seguir", @"trop fatigué pour continuer", @"疲れて続けられず", @"너무 피곤해서 중단"),
            ML(@"breathing every three strokes", @"三划一换气", @"respirar cada tres brazadas", @"respiration tous les trois", @"3ストロークごと呼吸", @"세 번마다 호흡"),
            ML(@"slow warm-up laps", @"慢速热身", @"vueltas lentas de calentamiento", @"échauffement lent", @"ゆっくりウォームアップ", @"천천히 워밍업"),
            ML(@"worked on flip turns", @"练翻滚转身", @"practiqué virajes", @"virages travaillés", @"クイックターン練習", @"플립턴 연습"),
            ML(@"pool was packed", @"泳池人很多", @"piscina llena", @"piscine bondée", @"プールが混んでいた", @"수영장 붐빔"),
            ML(@"freestyle intervals", @"自由泳间歇", @"intervalos de libre", @"intervalles nage libre", @"自由形インターバル", @"자유형 인터벌"),
            ML(@"backstroke cooldown", @"仰泳放松", @"espalda para enfriar", @"dos pour retour au calme", @"背泳ぎクールダウン", @"배영 쿨다운"),
            ML(@"goggles kept leaking", @"泳镜一直漏水", @"gafas con fugas", @"lunettes qui fuient", @"ゴーグル水漏れ", @"수경 물 샘"),
            ML(@"lane sharing", @"和别人共用泳道", @"compartí carril", @"ligne partagée", @"レーン共有", @"레인 공유"),
            ML(@"sprint sets", @"冲刺组", @"series de sprint", @"séries sprint", @"スプリントセット", @"스프린트 세트"),
            ML(@"practiced dolphin kick", @"练海豚腿", @"patada de delfín", @"ondulation", @"ドルフィンキック", @"돌핀킥 연습"),
            ML(@"easy recovery swim", @"轻松恢复游", @"nado suave de recuperación", @"récupération douce", @"軽いリカバリー泳", @"가벼운 회복 수영"),
            ML(@"coach watched my catch", @"教练看划水", @"coach revisó mi agarre", @"coach a vu l'appui", @"キャッチを見てもらった", @"코치가 캐치 봐줌"),
            ML(@"chlorine was strong", @"氯味很重", @"mucho cloro", @"chlore fort", @"塩素が強い", @"염소 냄새 강함"),
            ML(@"long continuous swim", @"长距离连续游", @"nado continuo largo", @"longue nage continue", @"長めに連続泳", @"긴 연속 수영"),
            ML(@"felt fast today", @"今天游得快", @"me sentí rápido hoy", @"rapide aujourd'hui", @"今日は速かった", @"오늘 속도 좋음"),
            ML(@"arms burned out", @"手臂没力了", @"brazos agotados", @"bras brûlés", @"腕が限界", @"팔이 지침")
        ],
        @"Read": @[
            ML(@"finished chapter 4", @"读完第 4 章", @"terminé el capítulo 4", @"chapitre 4 terminé", @"4章を読み終えた", @"4장 완료"),
            ML(@"notes on the ending", @"记录结尾想法", @"notas sobre el final", @"notes sur la fin", @"結末のメモ", @"결말 메모"),
            ML(@"coffee shop reading", @"咖啡店阅读", @"lectura en cafetería", @"lecture au café", @"カフェで読書", @"카페에서 독서"),
            ML(@"skimmed the hard part", @"略读困难部分", @"leí por encima la parte difícil", @"passage difficile survolé", @"難しい部分は流し読み", @"어려운 부분은 훑어봄"),
            ML(@"reread favorite section", @"重读喜欢的段落", @"releí parte favorita", @"passage préféré relu", @"好きな箇所を再読", @"좋아하는 부분 재독"),
            ML(@"library reading", @"图书馆阅读", @"lectura en biblioteca", @"lecture bibliothèque", @"図書館で読書", @"도서관 독서"),
            ML(@"book club prep", @"读书会准备", @"preparación club de lectura", @"prépa club lecture", @"読書会準備", @"독서 모임 준비"),
            ML(@"highlighted quotes", @"标注句子", @"subrayé citas", @"citations surlignées", @"引用をハイライト", @"문장 표시"),
            ML(@"started a new novel", @"开始新小说", @"empecé novela nueva", @"nouveau roman commencé", @"新しい小説開始", @"새 소설 시작"),
            ML(@"read on the train", @"通勤路上读", @"leí en el tren", @"lecture dans le train", @"電車で読書", @"기차에서 독서"),
            ML(@"confusing middle chapters", @"中间章节有点乱", @"capítulos centrales confusos", @"chapitres du milieu confus", @"中盤が少し難解", @"중간 챕터 혼란"),
            ML(@"finished the essay", @"读完文章", @"terminé el ensayo", @"essai terminé", @"エッセイ読了", @"에세이 완료"),
            ML(@"made margin notes", @"写边注", @"notas al margen", @"notes en marge", @"余白メモ", @"여백 메모"),
            ML(@"paused to look up history", @"停下来查背景", @"busqué contexto histórico", @"contexte historique cherché", @"歴史背景を調べた", @"역사 배경 검색"),
            ML(@"a few pages before bed", @"睡前读几页", @"unas páginas antes de dormir", @"quelques pages avant dormir", @"寝る前に数ページ", @"자기 전 몇 페이지"),
            ML(@"dense but worth it", @"很密但值得", @"denso pero vale la pena", @"dense mais utile", @"濃いけど価値あり", @"빽빽하지만 좋음"),
            ML(@"checked the footnotes", @"看脚注", @"revisé notas al pie", @"notes de bas de page", @"脚注確認", @"각주 확인"),
            ML(@"lost track of time", @"读到忘记时间", @"perdí la noción del tiempo", @"perdu la notion du temps", @"時間を忘れた", @"시간 가는 줄 모름"),
            ML(@"slow nonfiction pages", @"慢读非虚构", @"no ficción lenta", @"non-fiction lente", @"ノンフィクションをゆっくり", @"논픽션 천천히"),
            ML(@"finished before dinner", @"晚饭前读完", @"terminé antes de cenar", @"fini avant dîner", @"夕食前に読了", @"저녁 전 완료")
        ],
        @"Study": @[
            ML(@"reviewed flashcards", @"复习记忆卡", @"repasé tarjetas", @"cartes mémoire révisées", @"暗記カード復習", @"플래시카드 복습"),
            ML(@"mock exam corrections", @"模拟题订正", @"corrección de simulacro", @"correction d'examen blanc", @"模試の直し", @"모의고사 오답 정리"),
            ML(@"chapter summary", @"章节总结", @"resumen del capítulo", @"résumé du chapitre", @"章の要約", @"챕터 요약"),
            ML(@"hard to concentrate tonight", @"今晚难集中", @"difícil concentrarme esta noche", @"difficile de se concentrer ce soir", @"今夜は集中しづらい", @"오늘 밤 집중 어려움"),
            ML(@"grammar exercises", @"语法练习", @"ejercicios de gramática", @"exercices grammaire", @"文法練習", @"문법 연습"),
            ML(@"memorized formulas", @"背公式", @"memorizar fórmulas", @"formules mémorisées", @"公式暗記", @"공식 암기"),
            ML(@"watched lecture replay", @"看课程回放", @"vi repetición de clase", @"replay du cours", @"講義録画を見た", @"강의 다시 보기"),
            ML(@"practice problems set B", @"练习题 B 组", @"problemas grupo B", @"exercices série B", @"練習問題B", @"연습문제 B세트"),
            ML(@"made a cheat sheet", @"整理速查表", @"hice hoja resumen", @"fiche mémo créée", @"チートシート作成", @"요약표 작성"),
            ML(@"reviewed wrong answers", @"复盘错题", @"revisé errores", @"erreurs revues", @"間違い直し", @"오답 복습"),
            ML(@"language listening drill", @"听力练习", @"práctica de escucha", @"exercice d'écoute", @"リスニング練習", @"듣기 연습"),
            ML(@"office hours notes", @"答疑笔记", @"notas de tutoría", @"notes permanence", @"オフィスアワーメモ", @"질문 시간 메모"),
            ML(@"prepared presentation", @"准备展示", @"preparé presentación", @"présentation préparée", @"発表準備", @"발표 준비"),
            ML(@"anki backlog", @"清 Anki 积压", @"atraso de Anki", @"retard Anki", @"Anki の滞留消化", @"Anki 밀린 것 처리"),
            ML(@"quiet library desk", @"图书馆安静座位", @"mesa tranquila en biblioteca", @"table calme bibliothèque", @"静かな図書館席", @"조용한 도서관 자리"),
            ML(@"worked through examples", @"推例题", @"resolví ejemplos", @"exemples travaillés", @"例題を解いた", @"예제 풀이"),
            ML(@"review before quiz", @"小测前复习", @"repaso antes del quiz", @"révision avant quiz", @"小テスト前復習", @"퀴즈 전 복습"),
            ML(@"teacher's comments", @"看老师反馈", @"comentarios del profesor", @"commentaires prof", @"先生のコメント確認", @"선생님 피드백 확인"),
            ML(@"mind map cleanup", @"整理思维导图", @"ordené mapa mental", @"carte mentale rangée", @"マインドマップ整理", @"마인드맵 정리"),
            ML(@"tired but finished", @"很累但完成了", @"cansado pero terminado", @"fatigué mais terminé", @"疲れたけど完了", @"피곤했지만 완료")
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
