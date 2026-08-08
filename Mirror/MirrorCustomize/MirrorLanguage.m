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
    
    // tabs
    [mirrorDict setValue:ML(@"Start", @"计时", @"Iniciar", @"Démarrer", @"開始", @"시작") forKey:@"start"];
    [mirrorDict setValue:ML(@"Today", @"今天", @"Hoy", @"Aujourd'hui", @"今日", @"오늘") forKey:@"today"];
    [mirrorDict setValue:ML(@"Data", @"数据", @"Datos", @"Données", @"データ", @"데이터") forKey:@"data"];
    [mirrorDict setValue:ML(@"Record", @"记录", @"Registro", @"Historique", @"記録", @"기록") forKey:@"record"];
    
    // Settings
    [mirrorDict setValue:ML(@"Language", @"语言", @"Idioma", @"Langue", @"言語", @"언어") forKey:@"language"];
    [mirrorDict setValue:ML(@"Use Chinese", @"使用中文", @"Usar chino", @"Utiliser le chinois", @"中国語を使う", @"중국어 사용") forKey:@"apply_chinese"];
    [mirrorDict setValue:ML(@"Weeks start on Monday", @"周一作为一周的第一天", @"Las semanas empiezan el lunes", @"Les semaines commencent le lundi", @"週の始まりを月曜日にする", @"월요일부터 주 시작") forKey:@"week_starts_on_Monday"];
    [mirrorDict setValue:ML(@"Show record indexes", @"展示记录的序号", @"Mostrar índices de registros", @"Afficher les index des enregistrements", @"記録番号を表示", @"기록 번호 표시") forKey:@"show_record_indexes"];
    [mirrorDict setValue:ML(@"Histogram on Data", @"数据页使用柱状图", @"Histograma en Datos", @"Histogramme dans Données", @"データでヒストグラムを表示", @"데이터에 히스토그램 표시") forKey:@"show_histogram_on_data"];
    [mirrorDict setValue:ML(@"Piechart on Record", @"记录页使用饼状图", @"Gráfico circular en Registro", @"Camembert dans Historique", @"記録で円グラフを表示", @"기록에 원형 차트 표시") forKey:@"show_piechart_on_record"];
    [mirrorDict setValue:ML(@"Heatmap on Record", @"记录页使用热力图", @"Mapa de calor en Registro", @"Carte thermique dans Historique", @"記録でヒートマップを表示", @"기록에 히트맵 표시") forKey:@"heatmap"];
    [mirrorDict setValue:ML(@"Download from iCloud", @"从 iCloud 下载", @"Descargar de iCloud", @"Télécharger depuis iCloud", @"iCloudからダウンロード", @"iCloud에서 다운로드") forKey:@"download_from_icloud"];
    [mirrorDict setValue:ML(@"Download from iCloud?", @"确认从 iCloud 下载？", @"¿Descargar de iCloud?", @"Télécharger depuis iCloud ?", @"iCloudからダウンロードしますか？", @"iCloud에서 다운로드할까요?") forKey:@"download_from_icloud_?"];
    [mirrorDict setValue:ML(@"There are %@ records on your iCloud. Downloading will replace your current data.", @"你的 iCloud 上有 %@ 条记录。下载后会替换当前数据。", @"Hay %@ registros en tu iCloud. La descarga reemplazará tus datos actuales.", @"Il y a %@ enregistrements sur votre iCloud. Le téléchargement remplacera vos données actuelles.", @"iCloudに%@件の記録があります。ダウンロードすると現在のデータが置き換えられます。", @"iCloud에 %@개의 기록이 있습니다. 다운로드하면 현재 데이터가 대체됩니다.") forKey:@"icloud_records_message"];
    [mirrorDict setValue:ML(@"Download", @"下载", @"Descargar", @"Télécharger", @"ダウンロード", @"다운로드") forKey:@"download"];
    [mirrorDict setValue:ML(@"No iCloud data", @"没有 iCloud 数据", @"No hay datos en iCloud", @"Aucune donnée iCloud", @"iCloudデータがありません", @"iCloud 데이터 없음") forKey:@"no_icloud_data"];
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
    [mirrorDict setValue:ML(@"Remove", @"移掉", @"Quitar", @"Retirer", @"削除", @"제거") forKey:@"remove"];
    [mirrorDict setValue:ML(@"Delete", @"删除", @"Eliminar", @"Supprimer", @"削除", @"삭제") forKey:@"delete"];
    [mirrorDict setValue:ML(@"Archive", @"归档", @"Archivar", @"Archiver", @"アーカイブ", @"보관") forKey:@"archive"];
    [mirrorDict setValue:ML(@"Cancel", @"取消", @"Cancelar", @"Annuler", @"キャンセル", @"취소") forKey:@"cancel"];
    
    // Profile add cell
    [mirrorDict setValue:ML(@"Enter task title", @"输入任务名称", @"Ingresa el título de la tarea", @"Saisir le titre de la tâche", @"タスク名を入力", @"작업 제목 입력") forKey:@"enter_task_title"];
    [mirrorDict setValue:ML(@"Create", @"创建", @"Crear", @"Créer", @"作成", @"생성") forKey:@"create"];
    [mirrorDict setValue:ML(@"Discard", @"放弃", @"Descartar", @"Ignorer", @"破棄", @"버리기") forKey:@"discard"];
    [mirrorDict setValue:ML(@"Enter a title to create a new task", @"输入名称以创建新的任务", @"Ingresa un título para crear una nueva tarea", @"Saisir un titre pour créer une tâche", @"新しいタスク名を入力", @"새 작업을 만들 제목 입력") forKey:@"add_taskname_hint"];
    [mirrorDict setValue:ML(@"Name field cannot be empty", @"任务名不能为空", @"El nombre no puede estar vacío", @"Le nom ne peut pas être vide", @"名前は空にできません", @"이름은 비워둘 수 없습니다") forKey:@"name_field_cannot_be_empty"];
    [mirrorDict setValue:ML(@"Gotcha", @"知道啦", @"Entendido", @"Compris", @"了解", @"알겠어요") forKey:@"gotcha"];
    [mirrorDict setValue:ML(@"Task cannot be duplicated", @"任务不可重复", @"La tarea no puede duplicarse", @"La tâche ne peut pas être dupliquée", @"タスクは重複できません", @"작업은 중복될 수 없습니다") forKey:@"task_cannot_be_duplicated"];
    [mirrorDict setValue:ML(@"This task exists in the current task list", @"这个任务已经存在于当前任务列表中", @"Esta tarea ya existe en la lista actual", @"Cette tâche existe déjà dans la liste actuelle", @"このタスクは現在のリストに存在します", @"이 작업은 현재 목록에 이미 있습니다") forKey:@"this_task_exists_in_current_task_list"];
    [mirrorDict setValue:ML(@"This task exists in the archived task list. You can activate it in [Data]", @"这个任务已经存在于归档任务列表中。你可以在【数据】中重新激活此任务。", @"Esta tarea existe en la lista archivada. Puedes activarla en [Datos]", @"Cette tâche existe dans la liste archivée. Vous pouvez l'activer dans [Données]", @"このタスクはアーカイブ済みです。[データ]で再有効化できます", @"이 작업은 보관 목록에 있습니다. [데이터]에서 다시 활성화할 수 있습니다") forKey:@"this_task_exists_in_the_archived_task_list"];
    
    // Full screen
    [mirrorDict setValue:ML(@"Go!", @"开始!", @"¡Vamos!", @"C'est parti !", @"開始!", @"시작!") forKey:@"go"];
    [mirrorDict setValue:ML(@"Give up", @"放弃", @"Rendirse", @"Abandonner", @"あきらめる", @"포기") forKey:@"give_up"];
    [mirrorDict setValue:ML(@"Stop", @"结束", @"Detener", @"Arrêter", @"終了", @"종료") forKey:@"stop"];
    
    // Task record
    [mirrorDict setValue:ML(@"Counting...", @"计时中...", @"Contando...", @"Décompte...", @"計測中...", @"기록 중...") forKey:@"counting"];
    [mirrorDict setValue:ML(@"Lasted: ", @"持续时间：", @"Duración: ", @"Durée : ", @"時間: ", @"지속 시간: ") forKey:@"lasted"];
    [mirrorDict setValue:ML(@" (Archived) ", @"（已归档）", @" (Archivada) ", @" (Archivée) ", @" (アーカイブ済み) ", @" (보관됨) ") forKey:@"archived_tag"];
    
    // Delete period
    [mirrorDict setValue:ML(@"Delete this time period? ", @"确定删除这个时间段？", @"¿Eliminar este periodo?", @"Supprimer cette période ?", @"この時間帯を削除しますか？", @"이 시간대를 삭제할까요?") forKey:@"delete_period_?"];
    
    // Time VC
    [mirrorDict setValue:ML(@"Go to edit page(upper right) to reorder tasks", @"进入编辑页面（右上角）可以编辑顺序", @"Ve a editar (arriba a la derecha) para reordenar tareas", @"Allez à la page d'édition (en haut à droite) pour réordonner les tâches", @"右上の編集ページでタスクを並べ替えられます", @"오른쪽 위 편집 화면에서 작업 순서를 바꿀 수 있습니다") forKey:@"timeVC_hint0"];
    [mirrorDict setValue:ML(@"Go to edit page(upper right) to edit tasks", @"进入编辑页面（右上角）可以编辑任务", @"Ve a editar (arriba a la derecha) para editar tareas", @"Allez à la page d'édition (en haut à droite) pour modifier les tâches", @"右上の編集ページでタスクを編集できます", @"오른쪽 위 편집 화면에서 작업을 편집할 수 있습니다") forKey:@"timeVC_hint1"];
    [mirrorDict setValue:ML(@"Archived tasks will not be displayed on the main page", @"已经归档的任务将不会展示在主页面", @"Las tareas archivadas no se mostrarán en la página principal", @"Les tâches archivées ne s'afficheront pas sur la page principale", @"アーカイブ済みタスクはメイン画面に表示されません", @"보관된 작업은 메인 화면에 표시되지 않습니다") forKey:@"timeVC_hint2"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"timeVC_hint3"];
    
    // All tasks
    [mirrorDict setValue:ML(@"Long press to reorder tasks", @"长按拖动可以编辑顺序", @"Mantén presionado para reordenar tareas", @"Appuyez longuement pour réordonner les tâches", @"長押しでタスクを並べ替え", @"길게 눌러 작업 순서 변경") forKey:@"alltasks_hint0"];
    [mirrorDict setValue:ML(@"Tap task name to edit", @"轻点任务名可编辑", @"Toca el nombre para editar", @"Touchez le nom pour modifier", @"タスク名をタップして編集", @"작업 이름을 눌러 편집") forKey:@"alltasks_hint1"];
    [mirrorDict setValue:ML(@"Archived tasks will not be displayed on the main page", @"已经归档的任务将不会展示在主页面", @"Las tareas archivadas no se mostrarán en la página principal", @"Les tâches archivées ne s'afficheront pas sur la page principale", @"アーカイブ済みタスクはメイン画面に表示されません", @"보관된 작업은 메인 화면에 표시되지 않습니다") forKey:@"alltasks_hint2"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다") forKey:@"alltasks_hint3"];
    [mirrorDict setValue:ML(@"Delete this task? ", @"确定删除这个任务？", @"¿Eliminar esta tarea?", @"Supprimer cette tâche ?", @"このタスクを削除しますか？", @"이 작업을 삭제할까요?") forKey:@"delete_task_?"];
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
    [mirrorDict setValue:ML(@"No task today", @"今天暂无任务", @"No hay tareas hoy", @"Aucune tâche aujourd'hui", @"今日はタスクなし", @"오늘 작업 없음") forKey:@"no_data_today"];
    
    // Today total
    [mirrorDict setValue:ML(@"Total: ", @"总时长：", @"Total: ", @"Total : ", @"合計: ", @"합계: ") forKey:@"total"];
    
    // Time editing
    [mirrorDict setValue:ML(@"Starts at", @"开始时间", @"Empieza a las", @"Commence à", @"開始時刻", @"시작 시간") forKey:@"starts_at"];
    [mirrorDict setValue:ML(@"OR", @"或", @"O", @"OU", @"または", @"또는") forKey:@"or"];
    [mirrorDict setValue:ML(@"\"Now\" is occupied by the other task", @"当前时间已被其他任务占用", @"\"Ahora\" está ocupado por otra tarea", @"« Maintenant » est occupé par une autre tâche", @"「今」は別のタスクで使用中です", @"\"지금\"은 다른 작업이 사용 중입니다") forKey:@"now_is_occupied"];
    [mirrorDict setValue:ML(@"Start now", @"开始计时", @"Empezar ahora", @"Commencer maintenant", @"今すぐ開始", @"지금 시작") forKey:@"start_now"];
    [mirrorDict setValue:ML(@" hours", @" 小时", @" horas", @" heures", @" 時間", @"시간") forKey:@"picker_hours"];
    [mirrorDict setValue:ML(@" mins", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_mins"];
    [mirrorDict setValue:ML(@" hour", @" 小时", @" hora", @" heure", @" 時間", @"시간") forKey:@"picker_hour"];
    [mirrorDict setValue:ML(@" min", @" 分钟", @" min", @" min", @" 分", @"분") forKey:@"picker_min"];
    
    // All records
    [mirrorDict setValue:ML(@"All records", @"所有记录", @"Todos los registros", @"Tous les enregistrements", @"すべての記録", @"모든 기록") forKey:@"all_records"];
    [mirrorDict setValue:ML(@"Records", @"记录", @"Registros", @"Enregistrements", @"記録", @"기록") forKey:@"records"];
    
    // Motto
    [mirrorDict setValue:ML(@"Something you want to keep in mind?", @"想记下来什么？", @"¿Algo que quieras recordar?", @"Quelque chose à garder en tête ?", @"覚えておきたいことは？", @"기억하고 싶은 것이 있나요?") forKey:@"motto"];
    
    return [MirrorLanguage localizedValue:[mirrorDict valueForKey:key] languageKey:languageKey fallback:key];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];

    // Time
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

@end
