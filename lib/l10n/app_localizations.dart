import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      // Fallback to English if localizations are not available yet
      return AppLocalizations(const Locale('en', 'US'));
    }
    return localizations;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en_US': {
      // General
      'app_name': 'RIPTV',
      'loading': 'Loading...',
      'error': 'Error',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'settings': 'Settings',
      'yes': 'Yes',
      'no': 'No',
      'more_options': 'More options',
      'channels': 'Channels',
      'channels_label': 'channels',

      // Dashboard
      'dashboard': 'Dashboard',
      'movies': 'Movies',
      'series': 'Series',
      'live_tv': 'LIVE TV',
      'continue_watching': 'Continue Watching',
      'my_favorites': 'My Favorites',
      'playlists': 'Playlists',
      'configuration': 'Configuration',
      'epg_guide': 'EPG Guide',

      // Player
      'play': 'Play',
      'pause': 'Pause',
      'stop': 'Stop',
      'fullscreen': 'Fullscreen',
      'exit_fullscreen': 'Exit Fullscreen',
      'volume': 'Volume',
      'audio_track': 'Audio Track',
      'subtitles': 'Subtitles',
      'none': 'None',

      // Categories
      'all': 'All',
      'categories': 'Categories',
      'by_category': 'By Category',

      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'about': 'About',
      'version': 'Version',

      // Profiles
      'profiles': 'Profiles',
      'create_profile': 'Create Profile',
      'edit_profile': 'Edit Profile',
      'delete_profile': 'Delete Profile',
      'profile_name': 'Profile Name',
      'who_is_watching': 'Who is watching?',
      'new_profile': 'New Profile',
      'select_icon': 'Select an icon',
      'select_color': 'Select a color',
      'show_adult_content': 'Show adult content',
      'manage_profiles': 'Manage profiles',
      'name_required': 'Name is required',
      'cannot_delete_only_profile': 'You cannot delete the only profile',
      'delete_profile_confirm': 'Are you sure you want to delete profile "{name}"?',
      'video_quality': 'Video quality',
      'automatic': 'Automatic',
      'unknown': 'Unknown',
      'created_at': 'Created: ',
      'activate_profile': 'Activate profile',
      'add_source': 'Add source',
      'm3u_playlist_url': 'M3U Playlist URL',
      'enter_url': 'Please enter a URL',
      'm3u_valid_saving': 'M3U valid. Saving...',
      'xtream_config': 'Xtream Codes Configuration',
      'credentials_verified_saving': 'Credentials verified. Saving...',
      'please_complete_all_fields': 'Please complete all fields',
      'sort_by_added': 'Sort by added',
      'sort_by_name': 'Sort by name',
      'sort_by_rating': 'Sort by rating',
      'titles_count': 'titles',
      'trending': 'Trending',
      'continue_watching': 'Continue Watching',
      'my_list': 'My List',
      'featured_badge': 'FEATURED',
      'play_button': 'Play',
      'more_info': 'More info',
      'featured_series': 'FEATURED SERIES',
      'series_label': 'series',
      'delete_playlist_title': 'Delete Playlist',
      'delete_playlist_confirm': 'Are you sure you want to delete "{name}"?',
      'delete_playlist_desc': 'This action will delete {count} associated channels.',
      'playlist_deleted': 'Playlist deleted',
      'edit_playlist_option': 'Edit playlist',
      'refresh_channels_option': 'Update channels',
      'update_epg_option': 'Update EPG',
      'view_info_option': 'View information',
      'delete_playlist_option': 'Delete playlist',
      'updating_epg': 'Updating EPG...',
      'epg_updated_success': 'EPG updated: {count} programs',
      'epg_update_failed': 'Could not load EPG',
      'epg_update_error': 'Error updating EPG: {error}',
      'xtream_playlist_updated': 'Xtream Playlist updated:\n{live} live channels\n{movies} movies\n{series} series',
      'xtream_playlist_added': 'Xtream Playlist added:\n{live} live channels\n{movies} movies\n{series} series',
      'playlist_updated_msg': 'Playlist updated: {count} channels{epg}',
      'playlist_added_msg': 'Playlist added: {count} channels{epg}',
      'updated_at_label': 'Updated: {date}',
      'no_playlist': 'No Playlist',
      'manage_playlists': 'Manage Playlists',
      'app_inspiration': 'Made for premium users by CKGROUP.',
      'version_label': 'Version: {version}',
      'channels_count_short': '{count} channels',
      'select_channel': 'Select a channel',
      'load_epg': 'Load EPG',
      'enter_epg_url': 'Enter the EPG file URL (XMLTV format):',
      'enter_valid_url': 'Please enter a valid URL',
      'loading_epg': 'Loading EPG...',
      'epg_loaded_success': 'EPG loaded: {channels} channels, {programs} programs',
      'epg_guide_title': 'Programming Guide (EPG)',
      'go_to_today': 'Go to today',
      'clear_epg_title': 'Clear EPG',
      'clear_epg_confirm': 'Do you want to delete all EPG data?',
      'no_epg_data': 'No EPG data',
      'load_epg_desc': 'Load an EPG file to see the programming',
      'canal_header': 'Channel',
      'no_programming': 'No programming',
      'en_vivo_badge': 'LIVE',
      'audio_tracks': 'Audio Tracks',
      'no_audio_tracks': 'No audio tracks available',
      'close_button': 'Close',
      'track_short': 'Track {number}',
      'subtitles': 'Subtitles',
      'disabled': 'Disabled',
      'subtitle_short': 'Subtitle {number}',
      'no_subtitles': 'No subtitles available',
      'exit_fullscreen_tooltip': 'Exit fullscreen',
      'fullscreen_tooltip': 'Fullscreen',
      'back_button': 'Back',
      'audio_track_note': 'Audio tracks are selected automatically.\n\nTo change the audio track, some IPTV streams include multiple variants. The player will select the best one available.',
      'subtitle_note': 'Subtitles will be displayed automatically if they are included in the stream.',
      'details_label': 'Details',
      'played_label': 'Played',
      'times_label': 'times',
      'last_time_label': 'Last time',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'days_ago': '{days} days ago',
      'not_available': 'Not available',
      'views_label': 'Views',
      'category_label': 'Category',
      'title_label': 'Title',
      'episodes_label': 'Episodes',
      'added_to_favorites': 'Added to favorites',
      'add_to_favorites': 'Add to favorites',
      'season_prefix': 'S',
      'episode_prefix': 'E',
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      'monday_short': 'Mon',
      'tuesday_short': 'Tue',
      'wednesday_short': 'Wed',
      'thursday_short': 'Thu',
      'friday_short': 'Fri',
      'saturday_short': 'Sat',
      'sunday_short': 'Sun',
      'min_short': 'min',
      'watch_channel': 'Watch channel',
      'reminders_coming_soon': 'Reminders coming soon',
      'failed_to_load_stream': 'Failed to load stream: {error}',
      'tomorrow': 'Tomorrow',
      'of_preposition': 'of',
      'am': 'AM',
      'pm': 'PM',

      // Settings
      'video_settings': 'Video Settings',
      'video_quality': 'Video Quality',
      'select_quality': 'Select Quality',
      'auto': 'Auto',
      'video_fit': 'Video Fit',
      'select_video_fit': 'Select Video Fit',
      'fit': 'Fit',
      'fill': 'Fill',
      'fit_width': 'Fit Width',
      'fit_height': 'Fit Height',
      'auto_play_on_select': 'Auto-play on select',
      'default_volume': 'Default Volume',
      'parental_controls': 'Parental Controls',
      'show_adult_content': 'Show Adult Content',
      'requires_pin': 'Requires PIN to enable',
      'data_management': 'Data Management',
      'clear_all_data': 'Clear All Data',
      'clear_data_confirm': 'This will delete all playlists, channels, and settings. This action cannot be undone.',
      'about': 'About',
      'version': 'Version',
      'built_with_flutter': 'Built with Flutter',
      'powered_by': 'Powered by {engines}',
      'enter_pin': 'Enter PIN',
      'enter_4_digit_pin': 'Enter 4-digit PIN',
      'incorrect_pin': 'Incorrect PIN',
      'delete_all_confirmation': 'Delete All',
      'all_data_cleared': 'All data cleared',
      'ok': 'OK',
      'no_category': 'Uncategorized',

      // Playlists
      'add_playlist': 'Add Playlist',
      'edit_playlist': 'Edit Playlist',
      'delete_playlist': 'Delete Playlist',
      'playlist_name': 'Playlist Name',
      'playlist_url': 'Playlist URL',
      'playlist_type': 'Playlist Type',
      'm3u_file': 'M3U File',
      'xtream_codes': 'Xtream Codes',
      'username': 'Username',
      'password': 'Password',
      'server_url': 'Server URL',
      'playlist_management': 'Playlist Management',
      'new_playlist': 'New Playlist',
      'no_playlists': 'No playlists',
      'add_first_playlist': 'Add your first IPTV playlist\nto start watching content',
      'help': 'Help',

      // Messages
      'no_channels': 'No channels available',
      'no_movies': 'No movies available',
      'no_series': 'No series available',
      'no_favorites': 'No favorites',
      'no_recent': 'No recent channels',
      'playlist_updated': 'Playlist updated',
      'coming_soon': 'Coming soon',
      'confirm_exit': 'Are you sure you want to exit?',
      'exit': 'Exit',

      // Time
      'now_playing': 'Now Playing',
      'next': 'Next',
      'previous': 'Previous',

      // Sort
      'sort_by_added': 'Sort by Date Added',
      'sort_by_name': 'Sort by Name',
      'sort_by_rating': 'Sort by Rating',

      // Details
      'overview': 'Overview',
      'views': 'Views',
      'rating': 'Rating',

      // Theme Selector
      'select_theme': 'Select Theme',
      'theme_original': 'Original',
      'theme_original_desc': 'Modern cyan blue theme',
      'theme_netflix': 'Netflix Dark',
      'theme_netflix_desc': 'Netflix-style dark theme',
      'theme_applied': 'Theme applied',
      'close': 'Close',

      // Series
      'season': 'season',
      'seasons': 'seasons',

      // Playlist Dialog
      'add_new_playlist_subtitle': 'Add a new IPTV playlist',
      'modify_playlist_subtitle': 'Modify your playlist data',
      'playlist_name_label': 'Playlist name',
      'playlist_name_hint': 'My IPTV',
      'playlist_name_validation': 'Enter a name',
      'playlist_url_label': 'Playlist URL',
      'playlist_url_hint': 'https://example.com/playlist.m3u',
      'playlist_url_validation': 'Enter the URL',
      'url_validation_protocol': 'URL must start with http:// or https://',
      'server_host_label': 'Server host',
      'server_host_hint': 'http://server.com:8080',
      'server_host_validation': 'Enter the host',
      'protocol_validation': 'Must start with http:// or https://',
      'username_label': 'Username',
      'username_hint': 'myusername',
      'username_validation': 'Enter username',
      'password_label': 'Password',
      'password_hint': 'Your password',
      'password_validation': 'Enter password',
      'verify_credentials': 'Verify credentials',
      'verifying': 'Verifying...',
      'complete_all_fields': 'Complete all fields',
      'credentials_verified': 'Credentials verified',
      'credentials_invalid': 'Invalid credentials',
      'add': 'Add',
      'save': 'Save',

      // Help Dialog
      'supported_formats': 'Supported formats:',
      'supported_formats_desc': 'M3U, M3U8, Xtream Codes API',
      'xtream_url': 'Xtream URL:',
      'xtream_url_desc': 'System automatically detects credentials and loads EPG',
      'epg': 'EPG:',
      'epg_desc': 'Program guide loads automatically if available',
      'update': 'Update:',
      'update_desc': 'Use the refresh button to reload channels',
      'understood': 'Understood',

      // Loading Dialog
      'loading_playlist': 'Loading playlist...',
      'updating_playlist': 'Updating playlist...',
      'downloading_channels': 'Downloading and processing channels...',

      // Date
      'never': 'Never',

      // Playlist Info Dialog
      'information': 'Information',
      'name': 'Name',
      'channels_count': 'Channels',
      'updated': 'Updated',
      'authentication': 'Authentication',
      'yes': 'Yes',
      'no': 'No',
      'url': 'URL:',
      'authenticated': 'Authenticated',
      'active': 'Active',
      'refresh': 'Refresh',
      'more_options': 'More options',
      'channels': 'channels',
      'playlist_manager': 'Playlist Manager',
    },
    'zh_CN': {
      // General
      'app_name': 'RIPTV',
      'loading': '加载中...',
      'error': '错误',
      'ok': '确定',
      'cancel': '取消',
      'save': '保存',
      'delete': '删除',
      'edit': '编辑',
      'add': '添加',
      'search': '搜索',
      'settings': '设置',
      'yes': '是',
      'no': '否',

      // Dashboard
      'dashboard': '主页',
      'channels': '频道',
      'channels_label': '频道',
      'movies': '电影',
      'series': '剧集',
      'live_tv': '直播电视',
      'continue_watching': '继续观看',
      'my_favorites': '我的收藏',
      'playlists': '播放列表',
      'configuration': '配置',
      'epg_guide': '节目指南',

      // Player
      'play': '播放',
      'pause': '暂停',
      'stop': '停止',
      'fullscreen': '全屏',
      'exit_fullscreen': '退出全屏',
      'volume': '音量',
      'audio_track': '音轨',
      'subtitles': '字幕',
      'none': '无',

      // Categories
      'all': '全部',
      'categories': '分类',
      'by_category': '按分类',

      // Settings
      'language': '语言',
      'theme': '主题',
      'dark_mode': '深色模式',
      'light_mode': '浅色模式',
      'about': '关于',
      'version': '版本',

      // Profiles
      'profiles': '用户配置',
      'create_profile': '创建配置',
      'edit_profile': '编辑配置',
      'delete_profile': '删除配置',
      'profile_name': '配置名称',

      // Playlists
      'add_playlist': '添加列表',
      'edit_playlist': '编辑列表',
      'delete_playlist': '删除列表',
      'playlist_name': '列表名称',
      'playlist_url': '列表网址',
      'playlist_type': '列表类型',
      'm3u_file': 'M3U文件',
      'xtream_codes': 'Xtream代码',
      'username': '用户名',
      'password': '密码',
      'server_url': '服务器网址',
      'playlist_management': '播放列表管理',
      'new_playlist': '新播放列表',
      'no_playlists': '没有播放列表',
      'add_first_playlist': '添加您的第一个IPTV播放列表\n开始观看内容',
      'help': '帮助',

      // Messages
      'no_channels': '没有可用频道',
      'no_movies': '没有可用电影',
      'no_series': '没有可用剧集',
      'no_favorites': '没有收藏',
      'no_recent': '没有最近频道',
      'playlist_updated': '列表已更新',
      'coming_soon': '即将推出',
      'confirm_exit': '确定要退出应用程序吗？',
      'exit': '退出',

      // Time
      'now_playing': '正在播放',
      'next': '下一个',
      'previous': '上一个',

      // Sort
      'sort_by_added': '按添加日期排序',
      'sort_by_name': '按名称排序',
      'sort_by_rating': '按评分排序',

      // Details
      'overview': '概述',
      'views': '观看次数',
      'rating': '评分',

      // Theme Selector
      'select_theme': '选择主题',
      'theme_original': '原始',
      'theme_original_desc': '现代青色蓝色主题',
      'theme_netflix': 'Netflix 暗色',
      'theme_netflix_desc': 'Netflix风格的暗色主题',
      'theme_applied': '主题已应用',
      'close': '关闭',

      // Series
      'season': '季',
      'seasons': '季',

      // Playlist Dialog
      'add_new_playlist_subtitle': '添加新的IPTV播放列表',
      'modify_playlist_subtitle': '修改您的播放列表数据',
      'playlist_name_label': '播放列表名称',
      'playlist_name_hint': '我的IPTV',
      'playlist_name_validation': '请输入名称',
      'playlist_url_label': '播放列表网址',
      'playlist_url_hint': 'https://example.com/playlist.m3u',
      'playlist_url_validation': '请输入网址',
      'url_validation_protocol': '网址必须以http://或https://开头',
      'server_host_label': '服务器主机',
      'server_host_hint': 'http://server.com:8080',
      'server_host_validation': '请输入主机',
      'protocol_validation': '必须以http://或https://开头',
      'username_label': '用户名',
      'username_hint': '我的用户名',
      'username_validation': '请输入用户名',
      'password_label': '密码',
      'password_hint': '您的密码',
      'password_validation': '请输入密码',
      'verify_credentials': '验证凭据',
      'verifying': '验证中...',
      'complete_all_fields': '请填写所有字段',
      'credentials_verified': '凭据已验证',
      'credentials_invalid': '凭据无效',
      'add': '添加',
      'save': '保存',

      // Help Dialog
      'supported_formats': '支持的格式：',
      'supported_formats_desc': 'M3U、M3U8、Xtream Codes API',
      'xtream_url': 'Xtream网址：',
      'xtream_url_desc': '系统自动检测凭据并加载EPG',
      'epg': 'EPG：',
      'epg_desc': '如果可用，节目指南会自动加载',
      'update': '更新：',
      'update_desc': '使用刷新按钮重新加载频道',
      'understood': '明白了',

      // Loading Dialog
      'loading_playlist': '加载播放列表中...',
      'updating_playlist': '更新播放列表中...',
      'downloading_channels': '正在下载和处理频道...',

      // Date
      'never': '从未',

      // Playlist Info Dialog
      'information': '信息',
      'name': '名称',
      'channels_count': '频道',
      'updated': '更新时间',
      'authentication': '认证',
      'yes': '是',
      'no': '否',
      'url': '网址：',
      'authenticated': '已认证',
      'active': '活动',
      'refresh': '刷新',
      'more_options': '更多选项',
      'channels': '频道',
    },
    'ru_RU': {
      // General
      'app_name': 'RIPTV',
      'loading': 'Загрузка...',
      'error': 'Ошибка',
      'ok': 'OK',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'search': 'Поиск',
      'settings': 'Настройки',
      'yes': 'Да',
      'no': 'Нет',

      // Dashboard
      'dashboard': 'Главная',
      'channels': 'Каналы',
      'channels_label': 'каналов',
      'movies': 'Фильмы',
      'series': 'Сериалы',
      'live_tv': 'ПРЯМОЙ ЭФИР',
      'continue_watching': 'Продолжить просмотр',
      'my_favorites': 'Избранное',
      'playlists': 'Плейлисты',
      'configuration': 'Конфигурация',
      'epg_guide': 'Программа передач',

      // Player
      'play': 'Воспроизвести',
      'pause': 'Пауза',
      'stop': 'Стоп',
      'fullscreen': 'Полный экран',
      'exit_fullscreen': 'Выйти из полноэкранного режима',
      'volume': 'Громкость',
      'audio_track': 'Аудиодорожка',
      'subtitles': 'Субтитры',
      'none': 'Нет',

      // Categories
      'all': 'Все',
      'categories': 'Категории',
      'by_category': 'По категориям',

      // Settings
      'language': 'Язык',
      'theme': 'Тема',
      'dark_mode': 'Темный режим',
      'light_mode': 'Светлый режим',
      'about': 'О программе',
      'version': 'Версия',

      // Profiles
      'profiles': 'Профили',
      'create_profile': 'Создать профиль',
      'edit_profile': 'Редактировать профиль',
      'delete_profile': 'Удалить профиль',
      'profile_name': 'Имя профиля',

      // Playlists
      'add_playlist': 'Добавить плейлист',
      'edit_playlist': 'Редактировать плейлист',
      'delete_playlist': 'Удалить плейлист',
      'playlist_name': 'Название плейлиста',
      'playlist_url': 'URL плейлиста',
      'playlist_type': 'Тип плейлиста',
      'm3u_file': 'Файл M3U',
      'xtream_codes': 'Xtream Codes',
      'username': 'Имя пользователя',
      'password': 'Пароль',
      'server_url': 'URL сервера',
      'playlist_management': 'Управление плейлистами',
      'new_playlist': 'Новый плейлист',
      'no_playlists': 'Нет плейлистов',
      'add_first_playlist': 'Добавьте свой первый IPTV плейлист\nчтобы начать просмотр',
      'help': 'Помощь',

      // Messages
      'no_channels': 'Нет доступных каналов',
      'no_movies': 'Нет доступных фильмов',
      'no_series': 'Нет доступных сериалов',
      'no_favorites': 'Нет избранного',
      'no_recent': 'Нет недавних каналов',
      'playlist_updated': 'Плейлист обновлен',
      'coming_soon': 'Скоро',
      'confirm_exit': 'Вы уверены, что хотите выйти?',
      'exit': 'Выход',

      // Time
      'now_playing': 'Сейчас играет',
      'next': 'Следующий',
      'previous': 'Предыдущий',

      // Sort
      'sort_by_added': 'Сортировать по дате добавления',
      'sort_by_name': 'Сортировать по названию',
      'sort_by_rating': 'Сортировать по рейтингу',

      // Details
      'overview': 'Обзор',
      'views': 'Просмотры',
      'rating': 'Рейтинг',

      // Theme Selector
      'select_theme': 'Выбрать тему',
      'theme_original': 'Оригинальная',
      'theme_original_desc': 'Современная голубая тема',
      'theme_netflix': 'Netflix Темная',
      'theme_netflix_desc': 'Темная тема в стиле Netflix',
      'theme_applied': 'Тема применена',
      'close': 'Закрыть',

      // Series
      'season': 'сезон',
      'seasons': 'сезона',

      // Playlist Dialog
      'add_new_playlist_subtitle': 'Добавить новый IPTV плейлист',
      'modify_playlist_subtitle': 'Изменить данные плейлиста',
      'playlist_name_label': 'Название плейлиста',
      'playlist_name_hint': 'Мой IPTV',
      'playlist_name_validation': 'Введите название',
      'playlist_url_label': 'URL плейлиста',
      'playlist_url_hint': 'https://example.com/playlist.m3u',
      'playlist_url_validation': 'Введите URL',
      'url_validation_protocol': 'URL должен начинаться с http:// или https://',
      'server_host_label': 'Хост сервера',
      'server_host_hint': 'http://server.com:8080',
      'server_host_validation': 'Введите хост',
      'protocol_validation': 'Должен начинаться с http:// или https://',
      'username_label': 'Имя пользователя',
      'username_hint': 'моеимя',
      'username_validation': 'Введите имя пользователя',
      'password_label': 'Пароль',
      'password_hint': 'Ваш пароль',
      'password_validation': 'Введите пароль',
      'verify_credentials': 'Проверить учетные данные',
      'verifying': 'Проверка...',
      'complete_all_fields': 'Заполните все поля',
      'credentials_verified': 'Учетные данные проверены',
      'credentials_invalid': 'Неверные учетные данные',
      'add': 'Добавить',
      'save': 'Сохранить',

      // Help Dialog
      'supported_formats': 'Поддерживаемые форматы:',
      'supported_formats_desc': 'M3U, M3U8, Xtream Codes API',
      'xtream_url': 'URL Xtream:',
      'xtream_url_desc': 'Система автоматически определяет учетные данные и загружает EPG',
      'epg': 'EPG:',
      'epg_desc': 'Программа передач загружается автоматически, если доступна',
      'update': 'Обновить:',
      'update_desc': 'Используйте кнопку обновления для перезагрузки каналов',
      'understood': 'Понятно',

      // Loading Dialog
      'loading_playlist': 'Загрузка плейлиста...',
      'updating_playlist': 'Обновление плейлиста...',
      'downloading_channels': 'Загрузка и обработка каналов...',

      // Date
      'never': 'Никогда',

      // Playlist Info Dialog
      'information': 'Информация',
      'name': 'Название',
      'channels_count': 'Каналы',
      'updated': 'Обновлено',
      'authentication': 'Аутентификация',
      'yes': 'Да',
      'no': 'Нет',
      'url': 'URL:',
      'authenticated': 'Аутентифицирован',
      'active': 'Активный',
      'refresh': 'Обновить',
      'more_options': 'Дополнительные параметры',
      'channels': 'каналы',
    },
  };

  String translate(String key) {
    // We only support English (en_US) now
    String languageCode = 'en_US';
    String? value = _localizedValues[languageCode]?[key];

    return value ?? key;
  }

  // Getters for common translations
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get settings => translate('settings');
  String get yes => translate('yes');
  String get no => translate('no');

  String get dashboard => translate('dashboard');
  String get channels => translate('channels');
  String get movies => translate('movies');
  String get series => translate('series');
  String get liveTV => translate('live_tv');
  String get continueWatching => translate('continue_watching');
  String get myFavorites => translate('my_favorites');
  String get playlists => translate('playlists');
  String get configuration => translate('configuration');
  String get epgGuide => translate('epg_guide');
  String get playlistManager => translate('playlist_manager');

  String get play => translate('play');
  String get pause => translate('pause');
  String get stop => translate('stop');
  String get fullscreen => translate('fullscreen');
  String get exitFullscreen => translate('exit_fullscreen');
  String get volume => translate('volume');
  String get audioTrack => translate('audio_track');
  String get subtitles => translate('subtitles');
  String get none => translate('none');

  String get all => translate('all');
  String get categories => translate('categories');
  String get byCategory => translate('by_category');

  String get language => translate('language');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get about => translate('about');
  String get version => translate('version');

  String get profiles => translate('profiles');
  String get createProfile => translate('create_profile');
  String get editProfile => translate('edit_profile');
  String get deleteProfile => translate('delete_profile');
  String get profileName => translate('profile_name');
  String get whoIsWatching => translate('who_is_watching');
  String get newProfile => translate('new_profile');
  String get selectIcon => translate('select_icon');
  String get selectColor => translate('select_color');
  String get showAdultContent => translate('show_adult_content');
  String get manageProfiles => translate('manage_profiles');
  String get nameRequired => translate('name_required');
  String get cannotDeleteOnlyProfile => translate('cannot_delete_only_profile');
  String deleteProfileConfirm(String name) => translate('delete_profile_confirm').replaceAll('{name}', name);
  String get videoQuality => translate('video_quality');
  String get automatic => translate('automatic');
  String get unknown => translate('unknown');
  String get createdAt => translate('created_at');
  String get activateProfile => translate('activate_profile');
  String get addSource => translate('add_source');
  String get m3uPlaylistUrl => translate('m3u_playlist_url');
  String get enterUrl => translate('enter_url');
  String get m3uValidSaving => translate('m3u_valid_saving');
  String get xtreamConfig => translate('xtream_config');
  String get credentialsVerifiedSaving => translate('credentials_verified_saving');
  String get pleaseCompleteAllFields => translate('please_complete_all_fields');
  String get sortByAdded => translate('sort_by_added');
  String get sortByName => translate('sort_by_name');
  String get sortByRating => translate('sort_by_rating');
  String get titlesCount => translate('titles_count');
  String get trending => translate('trending');
  String get myList => translate('my_list');
  String get featuredBadge => translate('featured_badge');
  String get playButton => translate('play_button');
  String get moreInfo => translate('more_info');
  String get featuredSeries => translate('featured_series');
  String get seriesLabel => translate('series_label');

  String get deletePlaylistTitle => translate('delete_playlist_title');
  String deletePlaylistConfirm(String name) => translate('delete_playlist_confirm').replaceAll('{name}', name);
  String deletePlaylistDesc(int count) => translate('delete_playlist_desc').replaceAll('{count}', count.toString());
  String get playlistDeleted => translate('playlist_deleted');
  String get editPlaylistOption => translate('edit_playlist_option');
  String get refreshChannelsOption => translate('refresh_channels_option');
  String get updateEpgOption => translate('update_epg_option');
  String get viewInfoOption => translate('view_info_option');
  String get deletePlaylistOption => translate('delete_playlist_option');
  String get updatingEpg => translate('updating_epg');
  String epgUpdatedSuccess(int count) => translate('epg_updated_success').replaceAll('{count}', count.toString());
  String get epgUpdateFailed => translate('epg_update_failed');
  String epgUpdateError(String error) => translate('epg_update_error').replaceAll('{error}', error);
  String xtreamPlaylistUpdated(int live, int movies, int series) => translate('xtream_playlist_updated')
      .replaceAll('{live}', live.toString())
      .replaceAll('{movies}', movies.toString())
      .replaceAll('{series}', series.toString());
  String xtreamPlaylistAdded(int live, int movies, int series) => translate('xtream_playlist_added')
      .replaceAll('{live}', live.toString())
      .replaceAll('{movies}', movies.toString())
      .replaceAll('{series}', series.toString());
  String playlistUpdatedMsg(int count, String epg) => translate('playlist_updated_msg')
      .replaceAll('{count}', count.toString())
      .replaceAll('{epg}', epg);
  String playlistAddedMsg(int count, String epg) => translate('playlist_added_msg')
      .replaceAll('{count}', count.toString())
      .replaceAll('{epg}', epg);
  String updatedAtLabel(String date) => translate('updated_at_label').replaceAll('{date}', date);
  String get noPlaylist => translate('no_playlist');
  String get managePlaylists => translate('manage_playlists');
  String get appInspiration => translate('app_inspiration');
  String versionLabel(String version) => translate('version_label').replaceAll('{version}', version);
  String channelsCountShort(int count) => translate('channels_count_short').replaceAll('{count}', count.toString());
  String get selectChannel => translate('select_channel');
  String get loadEpg => translate('load_epg');
  String get enterEpgUrl => translate('enter_epg_url');
  String get enterValidUrl => translate('enter_valid_url');
  String get loadingEpg => translate('loading_epg');
  String epgLoadedSuccess(int channels, int programs) => translate('epg_loaded_success')
      .replaceAll('{channels}', channels.toString())
      .replaceAll('{programs}', programs.toString());
  String get epgGuideTitle => translate('epg_guide_title');
  String get goToToday => translate('go_to_today');
  String get clearEpgTitle => translate('clear_epg_title');
  String get clearEpgConfirm => translate('clear_epg_confirm');
  String get noEpgData => translate('no_epg_data');
  String get loadEpgDesc => translate('load_epg_desc');
  String get canalHeader => translate('canal_header');
  String get noProgramming => translate('no_programming');
  String get enVivoBadge => translate('en_vivo_badge');
  String get audioTracks => translate('audio_tracks');
  String get noAudioTracks => translate('no_audio_tracks');
  String get closeButton => translate('close_button');
  String trackShort(int number) => translate('track_short').replaceAll('{number}', number.toString());
  String get disabled => translate('disabled');
  String subtitleShort(int number) => translate('subtitle_short').replaceAll('{number}', number.toString());
  String get noSubtitles => translate('no_subtitles');
  String get exitFullscreenTooltip => translate('exit_fullscreen_tooltip');
  String get fullscreenTooltip => translate('fullscreen_tooltip');
  String get backButton => translate('back_button');
  String get audioTrackNote => translate('audio_track_note');
  String get subtitleNote => translate('subtitle_note');
  String get detailsLabel => translate('details_label');
  String get playedLabel => translate('played_label');
  String get timesLabel => translate('times_label');
  String get lastTimeLabel => translate('last_time_label');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String daysAgo(int days) => translate('days_ago').replaceAll('{days}', days.toString());
  String get notAvailable => translate('not_available');
  String get viewsLabel => translate('views_label');
  String get categoryLabel => translate('category_label');
  String get titleLabel => translate('title_label');
  String get episodesLabel => translate('episodes_label');
  String get addedToFavorites => translate('added_to_favorites');
  String get addToFavorites => translate('add_to_favorites');
  String get seasonPrefix => translate('season_prefix');
  String get episodePrefix => translate('episode_prefix');

  String get exit => translate('exit');

  String get nowPlaying => translate('now_playing');
  String get next => translate('next');
  String get previous => translate('previous');

  String get overview => translate('overview');
  String get views => translate('views');
  String get rating => translate('rating');

  String get selectTheme => translate('select_theme');
  String get themeOriginal => translate('theme_original');
  String get themeOriginalDesc => translate('theme_original_desc');
  String get themeNetflix => translate('theme_netflix');
  String get themeNetflixDesc => translate('theme_netflix_desc');
  String get themeApplied => translate('theme_applied');

  String get playlistManagement => translate('playlist_management');
  String get newPlaylist => translate('new_playlist');
  String get noPlaylists => translate('no_playlists');
  String get addFirstPlaylist => translate('add_first_playlist');
  String get help => translate('help');

  // Playlist Info Dialog
  String get information => translate('information');
  String get name => translate('name');
  String get channelsCount => translate('channels_count');
  String get updated => translate('updated');
  String get authentication => translate('authentication');
  String get url => translate('url');
  String get authenticated => translate('authenticated');
  String get active => translate('active');
  String get refresh => translate('refresh');
  String get moreOptions => translate('more_options');
  String get channelsLowercase => translate('channels_label');

  // Time & Date
  String get january => translate('january');
  String get february => translate('february');
  String get march => translate('march');
  String get april => translate('april');
  String get may => translate('may');
  String get june => translate('june');
  String get july => translate('july');
  String get august => translate('august');
  String get september => translate('september');
  String get october => translate('october');
  String get november => translate('november');
  String get december => translate('december');
  String get mondayShort => translate('monday_short');
  String get tuesdayShort => translate('tuesday_short');
  String get wednesdayShort => translate('wednesday_short');
  String get thursdayShort => translate('thursday_short');
  String get fridayShort => translate('friday_short');
  String get saturdayShort => translate('saturday_short');
  String get sundayShort => translate('sunday_short');
  String get minShort => translate('min_short');
  String get tomorrow => translate('tomorrow');
  String get ofPreposition => translate('of_preposition');
  String get am => translate('am');
  String get pm => translate('pm');

  // Additional Labels
  String get watchChannel => translate('watch_channel');
  String get remindersComingSoon => translate('reminders_coming_soon');
  String failedToLoadStream(String error) {
    return translate('failed_to_load_stream').replaceAll('{error}', error);
  }

  // Settings
  String get videoSettings => translate('video_settings');
  String get selectQuality => translate('select_quality');
  String get auto => translate('auto');
  String get videoFit => translate('video_fit');
  String get selectVideoFit => translate('select_video_fit');
  String get fit => translate('fit');
  String get fill => translate('fill');
  String get fitWidth => translate('fit_width');
  String get fitHeight => translate('fit_height');
  String get autoPlayOnSelect => translate('auto_play_on_select');
  String get defaultVolume => translate('default_volume');
  String get parentalControls => translate('parental_controls');
  String get requiresPin => translate('requires_pin');
  String get dataManagement => translate('data_management');
  String get clearAllData => translate('clear_all_data');
  String get clearDataConfirm => translate('clear_data_confirm');
  String get builtWithFlutter => translate('built_with_flutter');
  String poweredBy(String engines) {
    return translate('powered_by').replaceAll('{engines}', engines);
  }
  String get enterPin => translate('enter_pin');
  String get enter4DigitPin => translate('enter_4_digit_pin');
  String get incorrectPin => translate('incorrect_pin');
  String get deleteAllConfirmation => translate('delete_all_confirmation');
  String get allDataCleared => translate('all_data_cleared');

  String episodesCountLabel(int count) {
    return '$count ${translate('episodes_label')}';
  }

  String get noCategory => translate('no_category');

  // Restoring more missing ones
  String get addPlaylist => translate('add_playlist');
  String get editPlaylist => translate('edit_playlist');
  String get deletePlaylist => translate('delete_playlist');
  String get playlistName => translate('playlist_name');
  String get playlistUrl => translate('playlist_url');
  String get playlistType => translate('playlist_type');
  String get m3uFile => translate('m3u_file');
  String get xtreamCodes => translate('xtream_codes');
  String get username => translate('username');
  String get password => translate('password');
  String get serverUrl => translate('server_url');

  String get noChannels => translate('no_channels');
  String get noMovies => translate('no_movies');
  String get noSeries => translate('no_series');
  String get noFavorites => translate('no_favorites');
  String get noRecent => translate('no_recent');
  String get playlistUpdated => translate('playlist_updated');
  String get comingSoon => translate('coming_soon');
  String get confirmExit => translate('confirm_exit');

  String get nowPlayingTitle => translate('now_playing');
  String get close => translate('close');
  String get season => translate('season');
  String get seasons => translate('seasons');

  String get addNewPlaylistSubtitle => translate('add_new_playlist_subtitle');
  String get modifyPlaylistSubtitle => translate('modify_playlist_subtitle');
  String get playlistNameLabel => translate('playlist_name_label');
  String get playlistNameHint => translate('playlist_name_hint');
  String get playlistNameValidation => translate('playlist_name_validation');
  String get playlistUrlLabel => translate('playlist_url_label');
  String get playlistUrlHint => translate('playlist_url_hint');
  String get playlistUrlValidation => translate('playlist_url_validation');
  String get urlValidationProtocol => translate('url_validation_protocol');
  String get serverHostLabel => translate('server_host_label');
  String get serverHostHint => translate('server_host_hint');
  String get serverHostValidation => translate('server_host_validation');
  String get protocolValidation => translate('protocol_validation');
  String get usernameLabel => translate('username_label');
  String get usernameHint => translate('username_hint');
  String get usernameValidation => translate('username_validation');
  String get passwordLabel => translate('password_label');
  String get passwordHint => translate('password_hint');
  String get passwordValidation => translate('password_validation');
  String get verifyCredentials => translate('verify_credentials');
  String get verifying => translate('verifying');
  String get completeAllFields => translate('complete_all_fields');
  String get credentialsVerified => translate('credentials_verified');
  String get credentialsInvalid => translate('credentials_invalid');

  String get supportedFormats => translate('supported_formats');
  String get supportedFormatsDesc => translate('supported_formats_desc');
  String get xtreamUrl => translate('xtream_url');
  String get xtreamUrlDesc => translate('xtream_url_desc');
  String get epg => translate('epg');
  String get epgDesc => translate('epg_desc');
  String get update => translate('update');
  String get updateDesc => translate('update_desc');
  String get understood => translate('understood');

  String get loadingPlaylist => translate('loading_playlist');
  String get updatingPlaylist => translate('updating_playlist');
  String get downloadingChannels => translate('downloading_channels');

  String get never => translate('never');
  String get load => translate('load_epg');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'zh', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
