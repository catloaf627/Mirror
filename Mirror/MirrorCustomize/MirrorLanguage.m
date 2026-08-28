//
//  MirrorLanguage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import "MirrorLanguage.h"
#import "MirrorSettings.h"

#define ML(en, zh, es, fr, ja, ko, de, ru) @[en, zh, es, fr, ja, ko, de, ru]

@implementation MirrorLanguage

+ (NSString *)mirror_stringWithKey:(NSString *)key
{
    return [MirrorLanguage mirror_stringWithKey:key languageKey:[MirrorSettings preferredLanguageKey]];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key languageKey:(MirrorLanguageKey)languageKey
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];
    
    // locale
    [mirrorDict setValue:ML(@"en", @"zh-Hans", @"es", @"fr", @"ja", @"ko", @"de", @"ru") forKey:@"locale_Identifier"];
    
    // tabs
    [mirrorDict setValue:ML(@"Start", @"计时", @"Iniciar", @"Démarrer", @"開始", @"시작", @"Start", @"Старт") forKey:@"start"];
    [mirrorDict setValue:ML(@"Today", @"今天", @"Hoy", @"Aujourd'hui", @"今日", @"오늘", @"Heute", @"Сегодня") forKey:@"today"];
    [mirrorDict setValue:ML(@"Yesterday", @"昨天", @"Ayer", @"Hier", @"昨日", @"어제", @"Gestern", @"Вчера") forKey:@"yesterday"];
    [mirrorDict setValue:ML(@"Tomorrow", @"明天", @"Mañana", @"Demain", @"明日", @"내일", @"Morgen", @"Завтра") forKey:@"tomorrow"];
    [mirrorDict setValue:ML(@"Records", @"记录", @"Historial", @"Historique", @"記録", @"기록", @"Verlauf", @"Записи") forKey:@"record"];
    
    // Settings
    [mirrorDict setValue:ML(@"OK", @"好的", @"OK", @"OK", @"OK", @"확인", @"OK", @"OK") forKey:@"ok"];

    // Manual video titles
    [mirrorDict setValue:ML(@"Record times cannot overlap", @"两个记录时间不能重叠", @"Los horarios de dos registros no pueden superponerse", @"Les horaires de deux enregistrements ne peuvent pas se chevaucher", @"2つの記録時間は重複できません", @"두 기록 시간은 겹칠 수 없습니다", @"Zeiten zweier Einträge dürfen sich nicht überschneiden", @"Время двух записей не может пересекаться") forKey:@"manual_no_overlap"];
    [mirrorDict setValue:ML(@"Long press to edit a task", @"长按编辑任务", @"Mantén presionado para editar una tarea", @"Appuyez longuement pour modifier une tâche", @"長押しでタスクを編集", @"길게 눌러 작업 편집", @"Lange drücken, um eine Aufgabe zu bearbeiten", @"Удерживайте, чтобы изменить задачу") forKey:@"manual_start_edit_task"];
    [mirrorDict setValue:ML(@"Long press to merge tasks", @"长按合并任务", @"Mantén presionado para fusionar tareas", @"Appuyez longuement pour fusionner des tâches", @"長押しでタスクを結合", @"길게 눌러 작업 병합", @"Lange drücken, um Aufgaben zusammenzuführen", @"Удерживайте, чтобы объединить задачи") forKey:@"manual_start_merge_task"];
    [mirrorDict setValue:ML(@"Long press to delete a task", @"长按删除任务", @"Mantén presionado para eliminar una tarea", @"Appuyez longuement pour supprimer une tâche", @"長押しでタスクを削除", @"길게 눌러 작업 삭제", @"Lange drücken, um eine Aufgabe zu löschen", @"Удерживайте, чтобы удалить задачу") forKey:@"manual_start_delete_task"];
    [mirrorDict setValue:ML(@"Long press to edit/delete a record", @"长按编辑/删除记录", @"Mantén presionado para editar/eliminar un registro", @"Appuyez longuement pour modifier/supprimer un enregistrement", @"長押しで記録を編集/削除", @"길게 눌러 기록 편집/삭제", @"Einträge lange drücken, um sie zu bearbeiten/löschen", @"Удерживайте, чтобы изменить/удалить запись") forKey:@"manual_today_edit_record"];
    [mirrorDict setValue:ML(@"Tap or drag to adjust start/end time", @"短按或拖动调整开始/结束时间", @"Toca o arrastra para ajustar la hora de inicio/fin", @"Touchez ou faites glisser pour régler l’heure de début/fin", @"タップまたはドラッグして開始/終了時刻を調整", @"탭하거나 드래그해 시작/종료 시간 조정", @"Antippen oder ziehen, um Start-/Endzeit anzupassen", @"Нажмите или перетащите, чтобы изменить время начала/окончания") forKey:@"manual_today_adjust_time"];
    [mirrorDict setValue:ML(@"Tap empty space to add a new record", @"点击空白处添加新的记录", @"Toca un espacio vacío para añadir un registro nuevo", @"Touchez un espace vide pour ajouter un nouvel enregistrement", @"空白部分をタップして新しい記録を追加", @"빈 공간을 탭해 새 기록 추가", @"Leeren Bereich antippen, um einen neuen Eintrag hinzuzufügen", @"Нажмите пустое место, чтобы добавить новую запись") forKey:@"manual_today_add_record"];
    [mirrorDict setValue:ML(@"Swipe left/right or use calendar to switch dates", @"左右滑动或使用日历切换日期", @"Desliza a izquierda/derecha o usa el calendario para cambiar de fecha", @"Balayez à gauche/droite ou utilisez le calendrier pour changer de date", @"左右スワイプまたはカレンダーで日付を切り替え", @"좌우로 스와이프하거나 달력으로 날짜 전환", @"Links/rechts wischen oder den Kalender verwenden, um das Datum zu wechseln", @"Смахивайте влево/вправо или используйте календарь для смены даты") forKey:@"manual_today_switch_date"];
    [mirrorDict setValue:ML(@"Tap top-left to open Special Days; long press to edit/delete", @"点击左上角查看特殊日，长按编辑/删除", @"Toca arriba a la izquierda para abrir Días especiales; mantén presionado para editar/eliminar", @"Touchez en haut à gauche pour ouvrir les jours spéciaux ; appuyez longuement pour modifier/supprimer", @"左上をタップして特別な日を表示、長押しで編集/削除", @"왼쪽 위를 탭해 특별한 날 보기, 길게 눌러 편집/삭제", @"Oben links antippen, um besondere Tage zu öffnen; lange drücken zum Bearbeiten/Löschen", @"Нажмите слева сверху, чтобы открыть особые дни; удерживайте для изменения/удаления") forKey:@"manual_today_special_days"];
    [mirrorDict setValue:ML(@"Long press and drag to view records across multiple dates", @"长按拖动可查看多个日期的记录", @"Mantén presionado y arrastra para ver registros de varias fechas", @"Appuyez longuement et faites glisser pour voir les enregistrements de plusieurs dates", @"長押ししてドラッグすると複数日の記録を表示", @"길게 누르고 드래그해 여러 날짜의 기록 보기", @"Lange drücken und ziehen, um Einträge über mehrere Daten zu sehen", @"Удерживайте и перетаскивайте, чтобы видеть записи за несколько дат") forKey:@"manual_record_drag_dates"];
    [mirrorDict setValue:ML(@"Tap a day to view that day's records", @"短按查看当天记录", @"Toca un día para ver los registros de ese día", @"Touchez un jour pour voir les enregistrements de ce jour", @"日をタップするとその日の記録を表示", @"날짜를 탭해 해당 날짜의 기록 보기", @"Einen Tag antippen, um die Einträge dieses Tages zu sehen", @"Нажмите день, чтобы увидеть записи этого дня") forKey:@"manual_record_view_day"];
    [mirrorDict setValue:ML(@"Tap a record to open all records for that task; long press to edit/delete", @"点击某记录可进入该任务的全部记录清单，长按编辑/删除", @"Toca un registro para abrir todos los registros de esa tarea; mantén presionado para editar/eliminar", @"Touchez un enregistrement pour ouvrir tous ceux de cette tâche ; appuyez longuement pour modifier/supprimer", @"記録をタップするとそのタスクの全記録リストへ移動、長押しで編集/削除", @"기록을 탭해 해당 작업의 전체 기록 목록으로 이동, 길게 눌러 편집/삭제", @"Einen Eintrag antippen, um alle Einträge dieser Aufgabe zu öffnen; lange drücken zum Bearbeiten/Löschen", @"Нажмите запись, чтобы открыть все записи этой задачи; удерживайте для изменения/удаления") forKey:@"manual_record_task_list"];
    [mirrorDict setValue:ML(@"Tap a task in the legend to hide/show it", @"点击某任务的图例隐藏/取消隐藏该任务", @"Toca una tarea en la leyenda para ocultarla/mostrarla", @"Touchez une tâche dans la légende pour la masquer/l’afficher", @"凡例のタスクをタップして非表示/表示", @"범례의 작업을 탭해 숨기기/표시", @"Eine Aufgabe in der Legende antippen, um sie auszublenden/einzublenden", @"Нажмите задачу в легенде, чтобы скрыть/показать ее") forKey:@"manual_record_legend_task_visibility"];
    [mirrorDict setValue:ML(@"Tap top-left to switch the first day of week; tap top-right to switch heatmap", @"点击左上角切换每周起始日，点击右上角切换热力图", @"Toca arriba a la izquierda para cambiar el primer día de la semana; toca arriba a la derecha para cambiar el mapa de calor", @"Touchez en haut à gauche pour changer le premier jour de la semaine ; touchez en haut à droite pour changer la carte thermique", @"左上をタップして週の開始日を切り替え、右上をタップしてヒートマップを切り替え", @"왼쪽 위를 탭해 주 시작일 전환, 오른쪽 위를 탭해 히트맵 전환", @"Oben links antippen, um den Wochenbeginn zu ändern; oben rechts antippen, um die Heatmap umzuschalten", @"Нажмите слева сверху, чтобы изменить начало недели; нажмите справа сверху, чтобы переключить тепловую карту") forKey:@"manual_record_options"];

    // Profile edit cell
    [mirrorDict setValue:ML(@"Save", @"保存", @"Guardar", @"Enregistrer", @"保存", @"저장", @"Speichern", @"Сохранить") forKey:@"save"];
    [mirrorDict setValue:ML(@"Edit", @"编辑", @"Editar", @"Modifier", @"編集", @"편집", @"Bearbeiten", @"Изменить") forKey:@"edit"];
    [mirrorDict setValue:ML(@"Delete", @"删除", @"Eliminar", @"Supprimer", @"削除", @"삭제", @"Löschen", @"Удалить") forKey:@"delete"];
    [mirrorDict setValue:ML(@"Merge", @"合并", @"Fusionar", @"Fusionner", @"結合", @"병합", @"Zusammenführen", @"Объединить") forKey:@"merge"];
    [mirrorDict setValue:ML(@"Cancel", @"取消", @"Cancelar", @"Annuler", @"キャンセル", @"취소", @"Abbrechen", @"Отмена") forKey:@"cancel"];
    [mirrorDict setValue:ML(@"Done", @"完成", @"Listo", @"Terminé", @"完了", @"완료", @"Fertig", @"Готово") forKey:@"done"];
    [mirrorDict setValue:ML(@"Add", @"添加", @"Añadir", @"Ajouter", @"追加", @"추가", @"Hinzufügen", @"Добавить") forKey:@"add"];
    
    // Profile add cell
    [mirrorDict setValue:ML(@"Enter task title", @"输入任务名称", @"Ingresa el título de la tarea", @"Saisir le titre de la tâche", @"タスク名を入力", @"작업 제목 입력", @"Aufgabentitel eingeben", @"Введите название задачи") forKey:@"enter_task_title"];
    [mirrorDict setValue:ML(@"Task name", @"任务名称", @"Nombre de la tarea", @"Nom de la tâche", @"タスク名", @"작업 이름", @"Aufgabenname", @"Название задачи") forKey:@"task_name"];
    [mirrorDict setValue:ML(@"Edit task", @"编辑任务", @"Editar tarea", @"Modifier la tâche", @"タスクを編集", @"작업 편집", @"Aufgabe bearbeiten", @"Изменить задачу") forKey:@"edit_task"];
    [mirrorDict setValue:ML(@"Create a new task", @"创建新任务", @"Crear una nueva tarea", @"Créer une nouvelle tâche", @"新しいタスクを作成", @"새 작업 만들기", @"Neue Aufgabe erstellen", @"Создать новую задачу") forKey:@"create_a_new_task"];
    [mirrorDict setValue:ML(@"Create", @"创建", @"Crear", @"Créer", @"作成", @"생성", @"Erstellen", @"Создать") forKey:@"create"];
    [mirrorDict setValue:ML(@"Name field cannot be empty", @"任务名不能为空", @"El nombre no puede estar vacío", @"Le nom ne peut pas être vide", @"名前は空にできません", @"이름은 비워둘 수 없습니다", @"Der Name darf nicht leer sein", @"Название не может быть пустым") forKey:@"name_field_cannot_be_empty"];
    [mirrorDict setValue:ML(@"Gotcha", @"知道啦", @"Entendido", @"Compris", @"了解", @"알겠어요", @"Verstanden", @"Понятно") forKey:@"gotcha"];
    [mirrorDict setValue:ML(@"Task cannot be duplicated", @"任务名不可重复", @"La tarea no puede duplicarse", @"La tâche ne peut pas être dupliquée", @"タスクは重複できません", @"작업은 중복될 수 없습니다", @"Aufgabe darf nicht doppelt sein", @"Задача не должна повторяться") forKey:@"task_cannot_be_duplicated"];
    
    // Full screen
    [mirrorDict setValue:ML(@"Go!", @"开始!", @"¡Vamos!", @"C'est parti !", @"開始!", @"시작!", @"Los!", @"Начать!") forKey:@"go"];
    [mirrorDict setValue:ML(@"Stop", @"结束", @"Finalizar", @"Terminer", @"終了", @"종료", @"Stopp", @"Стоп") forKey:@"stop"];
    [mirrorDict setValue:ML(@"Hold to stop", @"长按结束", @"Mantén para parar", @"Maintenir pour arrêter", @"長押しで終了", @"길게 눌러 종료", @"Zum Stoppen halten", @"Удерживайте для остановки") forKey:@"hold_to_stop"];

    // Delete record
    [mirrorDict setValue:ML(@"Delete this record?", @"确定删除这条记录？", @"¿Eliminar este registro?", @"Supprimer cet enregistrement ?", @"この記録を削除しますか？", @"이 기록을 삭제할까요?", @"Diesen Eintrag löschen?", @"Удалить эту запись?") forKey:@"delete_period_?"];
    [mirrorDict setValue:ML(@"Ends at", @"结束于", @"Termina a las", @"Termine à", @"終了時刻", @"종료 시각", @"Endet um", @"Заканчивается в") forKey:@"ends_at"];
    [mirrorDict setValue:ML(@"Note", @"备注", @"Nota", @"Note", @"メモ", @"메모", @"Notiz", @"Заметка") forKey:@"note"];
    
    // Time VC
    [mirrorDict setValue:ML(@"Long press a task to edit tasks", @"长按任务进入编辑模式", @"Mantén presionada una tarea para editar tareas", @"Appuyez longuement sur une tâche pour modifier les tâches", @"タスクを長押しして編集モードに入る", @"작업을 길게 눌러 편집 모드로 들어가세요", @"Aufgabe lange drücken, um Aufgaben zu bearbeiten", @"Удерживайте задачу, чтобы редактировать задачи") forKey:@"timeVC_hint0"];
    [mirrorDict setValue:ML(@"Long press in edit mode to reorder tasks", @"编辑模式下长按可以调整任务顺序", @"Mantén presionado en modo edición para reordenar tareas", @"Appuyez longuement en mode édition pour réordonner les tâches", @"編集モードで長押ししてタスクを並べ替えられます", @"편집 모드에서 길게 눌러 작업 순서를 변경하세요", @"Im Bearbeitungsmodus lange drücken, um Aufgaben zu sortieren", @"В режиме редактирования удерживайте, чтобы изменить порядок") forKey:@"timeVC_hint1"];
    [mirrorDict setValue:ML(@"Up to 8 tasks can be created", @"最多可建立8个任务", @"Se pueden crear hasta 8 tareas", @"Jusqu'à 8 tâches peuvent être créées", @"最大8個のタスクを作成できます", @"최대 8개의 작업을 만들 수 있습니다", @"Bis zu 8 Aufgaben können erstellt werden", @"Можно создать до 8 задач") forKey:@"timeVC_hint2"];
    [mirrorDict setValue:ML(@"Tap records to adjust or drag time", @"轻点记录可调整或拖动时间", @"Toca los registros para ajustar o arrastrar la hora", @"Touchez un enregistrement pour régler ou déplacer l’heure", @"記録をタップして時刻調整/ドラッグ", @"기록을 탭해 시간 조정/드래그", @"Einträge antippen, um Zeit anzupassen/zu ziehen", @"Нажмите запись, чтобы изменить или перетащить время") forKey:@"timeVC_hint3"];
    [mirrorDict setValue:ML(@"Long press records to edit/delete", @"长按记录可编辑/删除", @"Mantén presionados los registros para editar/eliminar", @"Appuyez longuement sur un enregistrement pour modifier/supprimer", @"記録を長押しして編集/削除", @"기록을 길게 눌러 편집/삭제", @"Einträge lange drücken, um sie zu bearbeiten/löschen", @"Удерживайте запись, чтобы изменить/удалить") forKey:@"timeVC_hint4"];
    
    // All tasks
    [mirrorDict setValue:ML(@"Delete this task?", @"确定删除这个任务？", @"¿Eliminar esta tarea?", @"Supprimer cette tâche ?", @"このタスクを削除しますか？", @"이 작업을 삭제할까요?", @"Diese Aufgabe löschen? ", @"Удалить эту задачу? ") forKey:@"delete_task_?"];
    [mirrorDict setValue:ML(@"This will permanently delete this task and all records inside it. This cannot be undone.", @"这会永久删除此任务以及其中的所有记录，且无法撤销。", @"Esto eliminará permanentemente esta tarea y todos sus registros. No se puede deshacer.", @"Cela supprimera définitivement cette tâche et tous ses enregistrements. Cette action est irréversible.", @"このタスクとそのすべての記録が完全に削除され、元に戻せません。", @"이 작업과 포함된 모든 기록이 영구 삭제되며 되돌릴 수 없습니다.", @"Diese Aufgabe und alle enthaltenen Einträge werden dauerhaft gelöscht. Das kann nicht rückgängig gemacht werden.", @"Эта задача и все ее записи будут удалены навсегда. Это действие нельзя отменить.") forKey:@"delete_task_warning"];
    [mirrorDict setValue:ML(@"Merge tasks?", @"合并任务？", @"¿Fusionar tareas?", @"Fusionner les tâches ?", @"タスクを結合しますか？", @"작업을 병합할까요?", @"Aufgaben zusammenführen?", @"Объединить задачи?") forKey:@"merge_tasks_?"];
    [mirrorDict setValue:ML(@"This will merge the selected task into another task. This cannot be undone.", @"这会将所选任务合并到另一个任务，且无法撤销。", @"Esto fusionará la tarea seleccionada con otra tarea. No se puede deshacer.", @"Cela fusionnera la tâche sélectionnée avec une autre tâche. Cette action est irréversible.", @"選択したタスクを別のタスクに結合します。元に戻せません。", @"선택한 작업을 다른 작업에 병합하며 되돌릴 수 없습니다.", @"Die ausgewählte Aufgabe wird mit einer anderen Aufgabe zusammengeführt. Das kann nicht rückgängig gemacht werden.", @"Выбранная задача будет объединена с другой. Это действие нельзя отменить.") forKey:@"merge_task_warning"];
    
    // Special days
    [mirrorDict setValue:ML(@"Special Days", @"特别日", @"Días especiales", @"Jours spéciaux", @"特別な日", @"특별한 날", @"Besondere Tage", @"Особые дни") forKey:@"special_days"];
    [mirrorDict setValue:ML(@"Add Special Day", @"添加特别日", @"Añadir día especial", @"Ajouter un jour spécial", @"特別な日を追加", @"특별한 날 추가", @"Besonderen Tag hinzufügen", @"Добавить особый день") forKey:@"add_special_day"];
    [mirrorDict setValue:ML(@"Info", @"信息", @"Información", @"Info", @"情報", @"정보", @"Info", @"Информация") forKey:@"special_day_info"];
    [mirrorDict setValue:ML(@"Icon", @"图标", @"Icono", @"Icône", @"アイコン", @"아이콘", @"Symbol", @"Иконка") forKey:@"special_day_icon"];
    [mirrorDict setValue:ML(@"Search symbols (English only)", @"搜索图标（仅支持英文）", @"Buscar símbolos (solo inglés)", @"Rechercher des symboles (anglais uniquement)", @"シンボルを検索（英語のみ）", @"기호 검색(영어만 지원)", @"Symbole suchen (nur Englisch)", @"Поиск символов (только английский)") forKey:@"special_day_icon_search"];
    [mirrorDict setValue:ML(@"No special days", @"暂无特别日", @"Sin días especiales", @"Aucun jour spécial", @"特別な日はありません", @"특별한 날 없음", @"Keine besonderen Tage", @"Нет особых дней") forKey:@"no_special_days"];
    [mirrorDict setValue:ML(@"Only one special day can be added per day", @"一天只能添加一个特别日", @"Solo se puede añadir un día especial por fecha", @"Un seul jour spécial peut être ajouté par date", @"1日に追加できる特別な日は1つだけです", @"하루에 특별한 날은 하나만 추가할 수 있습니다", @"Pro Datum kann nur ein besonderer Tag hinzugefügt werden", @"На одну дату можно добавить только один особый день") forKey:@"special_day_cannot_be_duplicated"];
    
    // Grid
    [mirrorDict setValue:ML(@"Heatmap on", @"热力图已开启", @"Mapa de calor activado", @"Carte thermique activée", @"ヒートマップをオン", @"히트맵 켜짐", @"Heatmap aktiviert", @"Тепловая карта включена") forKey:@"grid_toast_heatmap_on"];
    [mirrorDict setValue:ML(@"Heatmap off", @"热力图已关闭", @"Mapa de calor desactivado", @"Carte thermique désactivée", @"ヒートマップをオフ", @"히트맵 꺼짐", @"Heatmap deaktiviert", @"Тепловая карта выключена") forKey:@"grid_toast_heatmap_off"];
    [mirrorDict setValue:ML(@"Weeks start on Monday", @"每周从周一开始", @"Las semanas empiezan el lunes", @"Les semaines commencent le lundi", @"週は月曜始まり", @"주는 월요일부터 시작", @"Wochen beginnen am Montag", @"Неделя начинается в понедельник") forKey:@"grid_toast_week_starts_monday"];
    [mirrorDict setValue:ML(@"Weeks start on Sunday", @"每周从周日开始", @"Las semanas empiezan el domingo", @"Les semaines commencent le dimanche", @"週は日曜始まり", @"주는 일요일부터 시작", @"Wochen beginnen am Sonntag", @"Неделя начинается в воскресенье") forKey:@"grid_toast_week_starts_sunday"];
    
    // Weekdays
    [mirrorDict setValue:ML(@"Sun", @"周日", @"Dom", @"Dim", @"日", @"일", @"So", @"Вс") forKey:@"sunday"];
    [mirrorDict setValue:ML(@"Mon", @"周一", @"Lun", @"Lun", @"月", @"월", @"Mo", @"Пн") forKey:@"monday"];
    [mirrorDict setValue:ML(@"Tue", @"周二", @"Mar", @"Mar", @"火", @"화", @"Di", @"Вт") forKey:@"tuesday"];
    [mirrorDict setValue:ML(@"Wed", @"周三", @"Mié", @"Mer", @"水", @"수", @"Mi", @"Ср") forKey:@"wednesday"];
    [mirrorDict setValue:ML(@"Thu", @"周四", @"Jue", @"Jeu", @"木", @"목", @"Do", @"Чт") forKey:@"thursday"];
    [mirrorDict setValue:ML(@"Fri", @"周五", @"Vie", @"Ven", @"金", @"금", @"Fr", @"Пт") forKey:@"friday"];
    [mirrorDict setValue:ML(@"Sat", @"周六", @"Sáb", @"Sam", @"土", @"토", @"Sa", @"Сб") forKey:@"saturday"];
    
    // Months
    [mirrorDict setValue:ML(@"Jan", @"1月", @"Ene", @"Jan", @"1月", @"1월", @"Jan", @"Янв") forKey:@"january"];
    [mirrorDict setValue:ML(@"Feb", @"2月", @"Feb", @"Fév", @"2月", @"2월", @"Feb", @"Фев") forKey:@"february"];
    [mirrorDict setValue:ML(@"Mar", @"3月", @"Mar", @"Mar", @"3月", @"3월", @"Mär", @"Мар") forKey:@"march"];
    [mirrorDict setValue:ML(@"Apr", @"4月", @"Abr", @"Avr", @"4月", @"4월", @"Apr", @"Апр") forKey:@"april"];
    [mirrorDict setValue:ML(@"May", @"5月", @"May", @"Mai", @"5月", @"5월", @"Mai", @"Май") forKey:@"may"];
    [mirrorDict setValue:ML(@"Jun", @"6月", @"Jun", @"Juin", @"6月", @"6월", @"Jun", @"Июн") forKey:@"june"];
    [mirrorDict setValue:ML(@"Jul", @"7月", @"Jul", @"Juil", @"7月", @"7월", @"Jul", @"Июл") forKey:@"july"];
    [mirrorDict setValue:ML(@"Aug", @"8月", @"Ago", @"Août", @"8月", @"8월", @"Aug", @"Авг") forKey:@"august"];
    [mirrorDict setValue:ML(@"Sep", @"9月", @"Sep", @"Sep", @"9月", @"9월", @"Sep", @"Сен") forKey:@"september"];
    [mirrorDict setValue:ML(@"Oct", @"10月", @"Oct", @"Oct", @"10月", @"10월", @"Okt", @"Окт") forKey:@"october"];
    [mirrorDict setValue:ML(@"Nov", @"11月", @"Nov", @"Nov", @"11月", @"11월", @"Nov", @"Ноя") forKey:@"november"];
    [mirrorDict setValue:ML(@"Dec", @"12月", @"Dic", @"Déc", @"12月", @"12월", @"Dez", @"Дек") forKey:@"december"];
    
    // Empty hints
    [mirrorDict setValue:ML(@"No data", @"暂无数据", @"Sin datos", @"Aucune donnée", @"データなし", @"데이터 없음", @"Keine Daten", @"Нет данных") forKey:@"no_data"];
    [mirrorDict setValue:ML(@"Please create a task on the Start page first", @"请先去计时页面新建一个任务", @"Crea primero una tarea en la página Iniciar", @"Créez d'abord une tâche sur la page Démarrer", @"まず開始ページでタスクを作成してください", @"먼저 시작 페이지에서 작업을 만들어 주세요", @"Bitte erst auf der Startseite eine Aufgabe erstellen", @"Сначала создайте задачу на странице Старт") forKey:@"no_task"];
    
    // Today total
    [mirrorDict setValue:ML(@"Total: ", @"总时长：", @"Total: ", @"Total : ", @"合計: ", @"합계: ", @"Gesamt: ", @"Всего: ") forKey:@"total"];
    
    // Time editing
    [mirrorDict setValue:ML(@"Starts at", @"开始于", @"Comienza a las", @"Commence à", @"開始時刻", @"시작 시각", @"Beginnt um", @"Начинается в") forKey:@"starts_at"];
    [mirrorDict setValue:ML(@"The current time is already covered by an existing record, so counting cannot start.", @"当前时间已被已有记录占用，无法开始计时。", @"La hora actual ya está cubierta por un registro existente, así que no se puede empezar a contar.", @"L’heure actuelle est déjà couverte par un enregistrement existant, le chronométrage ne peut pas démarrer.", @"現在時刻は既存の記録に含まれているため、計時を開始できません。", @"현재 시간이 기존 기록에 포함되어 있어 타이머를 시작할 수 없습니다.", @"Die aktuelle Zeit ist bereits durch einen vorhandenen Eintrag belegt, daher kann die Zeitmessung nicht starten.", @"Текущее время уже занято существующей записью, поэтому отсчет нельзя начать.") forKey:@"current_time_occupied_cannot_start_counting"];

    return [MirrorLanguage localizedValue:[mirrorDict valueForKey:key] languageKey:languageKey fallback:key];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];

    // Time
    [mirrorDict setValue:ML(@"Merge %@ to", @"将 %@ 合并到", @"Fusionar %@ con", @"Fusionner %@ avec", @"%@ の結合先", @"%@ 병합 대상", @"%@ zusammenführen mit", @"Объединить %@ с") forKey:@"merge_task_to"];
    [mirrorDict setValue:ML(@"merge with prefix '%@'", @"合并时添加前缀“%@”", @"fusionar con prefijo «%@»", @"fusionner avec le préfixe « %@ »", @"「%@」を接頭辞として結合", @"'%@' 접두어로 병합", @"mit Präfix „%@“ zusammenführen", @"объединить с префиксом «%@»") forKey:@"merge_with_prefix"];
    [mirrorDict setValue:ML(@"%@h ", @"%@时", @"%@ h ", @"%@ h ", @"%@時間", @"%@시간", @"%@ Std. ", @"%@ ч ") forKey:@"h"];
    [mirrorDict setValue:ML(@"%@m ", @"%@分", @"%@ min ", @"%@ min ", @"%@分", @"%@분", @"%@ Min. ", @"%@ мин ") forKey:@"m"];
    [mirrorDict setValue:ML(@"%@s", @"%@秒", @"%@ s", @"%@ s", @"%@秒", @"%@초", @"%@ Sek.", @"%@ с") forKey:@"s"];
    [mirrorDict setValue:ML(@"%@ hour ", @"%@小时", @"%@ hora ", @"%@ heure ", @"%@時間", @"%@시간", @"%@ Stunde ", @"%@ ч ") forKey:@"hour"];
    [mirrorDict setValue:ML(@"%@ min ", @"%@分钟", @"%@ min ", @"%@ min ", @"%@分", @"%@분", @"%@ Min. ", @"%@ мин ") forKey:@"min"];
    [mirrorDict setValue:ML(@"%@ second", @"%@秒", @"%@ segundo", @"%@ seconde", @"%@秒", @"%@초", @"%@ Sekunde", @"%@ с") forKey:@"second"];
    [mirrorDict setValue:ML(@"%@ hours ", @"%@小时", @"%@ horas ", @"%@ heures ", @"%@時間", @"%@시간", @"%@ Stunden ", @"%@ ч ") forKey:@"hours"];
    [mirrorDict setValue:ML(@"%@ mins ", @"%@分钟", @"%@ min ", @"%@ min ", @"%@分", @"%@분", @"%@ Min. ", @"%@ мин ") forKey:@"mins"];
    [mirrorDict setValue:ML(@"%@ seconds", @"%@秒", @"%@ segundos", @"%@ secondes", @"%@秒", @"%@초", @"%@ Sekunden", @"%@ с") forKey:@"seconds"];
    [mirrorDict setValue:ML(@"%@ reached the next record, so it was stopped automatically to avoid overlap.", @"%@ 已到达下一条记录的开始时间，为避免重叠，已自动停止。", @"%@ llegó al siguiente registro, así que se detuvo automáticamente para evitar solaparse.", @"%@ a atteint l’enregistrement suivant et s’est arrêté automatiquement pour éviter un chevauchement.", @"%@ は次の記録の開始時刻に達したため、重複を避けて自動停止しました。", @"%@이 다음 기록 시작 시간에 도달해 겹치지 않도록 자동 중지되었습니다.", @"%@ hat den nächsten Eintrag erreicht und wurde automatisch gestoppt, um Überschneidungen zu vermeiden.", @"%@ достигла следующей записи и была автоматически остановлена, чтобы избежать пересечения.") forKey:@"counting_auto_stopped_due_to_next_record"];
    [mirrorDict setValue:ML(@"%@ reached the next record before 60 seconds, so it was cancelled to avoid overlap.", @"%@ 在满 60 秒前到达了下一条记录的开始时间，为避免重叠，已自动取消。", @"%@ llegó al siguiente registro antes de 60 segundos, así que se canceló para evitar solaparse.", @"%@ a atteint l’enregistrement suivant avant 60 secondes et a été annulé pour éviter un chevauchement.", @"%@ は60秒経過前に次の記録の開始時刻に達したため、重複を避けて自動キャンセルされました。", @"%@이 60초 이내에 다음 기록 시작 시간에 도달해 겹치지 않도록 자동 취소되었습니다.", @"%@ hat vor 60 Sekunden den nächsten Eintrag erreicht und wurde abgebrochen, um Überschneidungen zu vermeiden.", @"%@ достигла следующей записи раньше 60 секунд и была отменена, чтобы избежать пересечения.") forKey:@"counting_auto_cancelled_due_to_next_record"];
    
    NSString *format = [MirrorLanguage localizedValue:[mirrorDict valueForKey:key] languageKey:[MirrorSettings preferredLanguageKey] fallback:key];
    return [NSString stringWithFormat:format, placeholder];
}

// 1996年6月27日 周四:
// English: Thu, Jun 27, 1996
// Chinese: 1996年6月27日 周四
// Spanish: Jue, 27 Jun 1996
// French: Jeu, 27 Juin 1996
// Japanese: 1996年6月27日 木
// Korean: 1996년 6월 27일 목
// German: Do, 27. Jun 1996
// Russian: Чт, 27 Июн 1996
+ (NSString *)mirror_dateStringWithYear:(long)year
                                  month:(long)month
                                    day:(long)day
                                weekday:(long)weekday
{
    MirrorLanguageKey languageKey = [MirrorSettings preferredLanguageKey];
    NSString *monthText = [MirrorLanguage monthTextForMonth:month languageKey:languageKey];
    NSString *weekdayText = [MirrorLanguage weekdayTextForWeekday:weekday languageKey:languageKey];
    
    switch (languageKey) {
        case MirrorLanguageKeySimplifiedChinese:
            return [NSString stringWithFormat:@"%ld年%@%ld日 %@", year, monthText, day, weekdayText];
        case MirrorLanguageKeyJapanese:
            return [NSString stringWithFormat:@"%ld年%@%ld日 %@", year, monthText, day, weekdayText];
        case MirrorLanguageKeyKorean:
            return [NSString stringWithFormat:@"%ld년 %@ %ld일 %@", year, monthText, day, weekdayText];
        case MirrorLanguageKeyGerman:
            return [NSString stringWithFormat:@"%@, %ld. %@ %ld", weekdayText, day, monthText, year];
        case MirrorLanguageKeySpanish:
        case MirrorLanguageKeyFrench:
        case MirrorLanguageKeyRussian:
            return [NSString stringWithFormat:@"%@, %ld %@ %ld", weekdayText, day, monthText, year];
        case MirrorLanguageKeyEnglish:
        default:
            return [NSString stringWithFormat:@"%@, %@ %ld, %ld", weekdayText, monthText, day, year];
    }
}

// 1996年6月27日:
// English: Jun 27, 1996
// Chinese: 1996年6月27日
// Spanish: 27 Jun 1996
// French: 27 Juin 1996
// Japanese: 1996年6月27日
// Korean: 1996년 6월 27일
// German: 27. Jun 1996
// Russian: 27 Июн 1996
+ (NSString *)mirror_dateStringWithYear:(long)year
                                  month:(long)month
                                    day:(long)day
{
    MirrorLanguageKey languageKey = [MirrorSettings preferredLanguageKey];
    NSString *monthText = [MirrorLanguage monthTextForMonth:month languageKey:languageKey];
    
    switch (languageKey) {
        case MirrorLanguageKeySimplifiedChinese:
        case MirrorLanguageKeyJapanese:
            return [NSString stringWithFormat:@"%ld年%@%ld日", year, monthText, day];
        case MirrorLanguageKeyKorean:
            return [NSString stringWithFormat:@"%ld년 %@ %ld일", year, monthText, day];
        case MirrorLanguageKeyGerman:
            return [NSString stringWithFormat:@"%ld. %@ %ld", day, monthText, year];
        case MirrorLanguageKeySpanish:
        case MirrorLanguageKeyFrench:
        case MirrorLanguageKeyRussian:
            return [NSString stringWithFormat:@"%ld %@ %ld", day, monthText, year];
        case MirrorLanguageKeyEnglish:
        default:
            return [NSString stringWithFormat:@"%@ %ld, %ld", monthText, day, year];
    }
}

// 1996年6月:
// English: Jun 1996
// Chinese: 1996年6月
// Spanish: Jun 1996
// French: Juin 1996
// Japanese: 1996年6月
// Korean: 1996년 6월
// German: Jun 1996
// Russian: Июн 1996
+ (NSString *)mirror_monthStringWithYear:(long)year
                                   month:(long)month
{
    MirrorLanguageKey languageKey = [MirrorSettings preferredLanguageKey];
    NSString *monthText = [MirrorLanguage monthTextForMonth:month languageKey:languageKey];
    
    switch (languageKey) {
        case MirrorLanguageKeySimplifiedChinese:
        case MirrorLanguageKeyJapanese:
            return [NSString stringWithFormat:@"%ld年%@", year, monthText];
        case MirrorLanguageKeyKorean:
            return [NSString stringWithFormat:@"%ld년 %@", year, monthText];
        case MirrorLanguageKeyEnglish:
            return [NSString stringWithFormat:@"%@ %ld", monthText, year];
        case MirrorLanguageKeySpanish:
        case MirrorLanguageKeyFrench:
        case MirrorLanguageKeyGerman:
        case MirrorLanguageKeyRussian:
        default:
            return [NSString stringWithFormat:@"%@ %ld", monthText, year];
    }
}

+ (NSString *)weekdayTextForWeekday:(long)weekday languageKey:(MirrorLanguageKey)languageKey
{
    NSArray<NSString *> *keys = @[@"sunday", @"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday"];
    if (weekday < 1 || weekday > keys.count) {
        return @"";
    }
    
    return [MirrorLanguage mirror_stringWithKey:keys[weekday - 1] languageKey:languageKey];
}

+ (NSString *)monthTextForMonth:(long)month languageKey:(MirrorLanguageKey)languageKey
{
    NSArray<NSString *> *keys = @[@"january", @"february", @"march", @"april", @"may", @"june", @"july", @"august", @"september", @"october", @"november", @"december"];
    if (month < 1 || month > keys.count) {
        return @"";
    }
    
    return [MirrorLanguage mirror_stringWithKey:keys[month - 1] languageKey:languageKey];
}

+ (NSString *)localizedValue:(NSArray<NSString *> *)translations languageKey:(MirrorLanguageKey)languageKey fallback:(NSString *)fallback
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
