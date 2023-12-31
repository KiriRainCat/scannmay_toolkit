import 'package:get/get.dart';

class Languages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        "zh_CN": {
          "goToJupiter": "前往 Jupiter",
          "dataFetchTimeTooltip": "此时间为数据检索成功的时间",
          "dateFetchSuccess": "数据检索成功",
          "dataFetchInProgress": "数据检索中...",
          "dataFetchFailure": "数据检索失败",
          "pleaseLogin": "请登录~",
          "usernameOrEmail": "用户名/邮箱",
          "password": "密码",
          "login": "登录",
          "updateNotice": "更新提示",
          "updating": "更新中...",
          "updateImmediately": "立即升级",
          "cancel": "取消",
          "jupiterAccountInfo": "Jupiter 账号信息",
          "usernameOrSid": "用户名/SID",
          "confirm": "确认",
          "cookieString": "Cookie 字符串",
          "author": "应用作者: 柒夜雨猫",
          "version": "应用版本",
          "checkUpdate": "检查更新",
          "browserClose": "浏览器关闭",
          "homePage": "主页",
          "class": "科目",
          "notification": "通知",
          "calender": "日历",
          "setting": "设置",
          "about": "关于",
          "re": "重新",
          "fetchDirection": "检索 Directions 信息",
          "newHomework": "新作业提示",
          "remove": "移除",
          "tooltip": "提示",
          "forceFetchData": "强制重新检索数据 (如果软件卡死，请手动重启软件)",
          "clearQueue": "清空队列",
          "deadlineTill": "截止于",
          "daysTillHomework": "日内的作业",
          "incomplete": "未完成",
          "complete": "完成",
          "language": "语言",
          "autoBoot": "开机自启动",
          "dataFetchInterval": "数据检索间隔",
          "changeAccount": "更改账号",
          "saveSettings": "保存设置",
          "change": "更改",
          "noUpdate": "暂无更新",
          "verifiedSaved": "校验成功，已保存",
          "saveSuccess": "保存成功",
          "desc1": "软件的界面语言，如果个别翻译不存在，将会默认使用中文 *r",
          "desc2": "在系统启动后自动打开应用并隐藏至托盘",
          "desc3": "登录 Jupiter 并查看是否有新成绩或作业的时间间隔 (10 min ≤ t ≤ 120 min) *s",
          "desc4": "用于登录 Jupiter ED 进行数据检索的学生账号",
          "info1": "请等待数据检索完成的提示信息，期间请不要重复点击检索数据按钮",
          "info2": "的数据检索完成啦，重新打开详情页以查看信息",
          "info3": "确定要清空消息队列吗？",
          "info4": "已有浏览器正在检索数据",
          "info5": "数据检索已开始，请耐心等待",
          "info6": "*s = 该设置仅在点击保存后生效 | *r = 该设置仅在应用重启后生效",
          "desc5": "用于绕过 Jupiter CF 反爬的 Cookies (请求 header 中的整段 Cookies 字符串)",
          "err1": "字符串不得为空或与旧值相同",
          "err2": "数据检索间隔不合法",
          "err3": "Chromium 自动化浏览器出现上下文异常，作业详情信息获取失败",
          "err4": "远程服务器离线或网络错误",
          "err5": "设置保存异常",
        },
        "en_US": {
          "goToJupiter": "Go to Jupiter",
          "dataFetchTimeTooltip": "This time represents the time for successful data retrieval",
          "dateFetchSuccess": "Data retrieval successful",
          "dataFetchInProgress": "Data retrieval in progress...",
          "dataFetchFailure": "Data retrieval failed",
          "pleaseLogin": "Please log in~",
          "usernameOrEmail": "Username/Email",
          "password": "Password",
          "login": "Login",
          "updateNotice": "Update Notice",
          "updating": "Updating...",
          "updateImmediately": "Update Now",
          "cancel": "Cancel",
          "jupiterAccountInfo": "Jupiter Account Information",
          "usernameOrSid": "Username/SID",
          "confirm": "Confirm",
          "cookieString": "Cookie String",
          "author": "App Author: KiriRainCat (柒夜雨猫)",
          "version": "App Version",
          "checkUpdate": "Check for Updates",
          "browserClose": "Browser Closed",
          "homePage": "Home",
          "class": "Subject",
          "notification": "Notification",
          "calender": "Calendar",
          "setting": "Settings",
          "about": "About",
          "re": "Re-",
          "fetchDirection": "Retrieve Directions Information",
          "newHomework": "New Homework Notification",
          "remove": "Remove",
          "tooltip": "Tooltip",
          "forceFetchData": "Force Data Retrieval (Manually restart the software if get stuck)",
          "clearQueue": "Clear Notification Queue",
          "deadlineTill": "Deadline by",
          "daysTillHomework": "days for homework",
          "incomplete": "Incomplete",
          "complete": "Complete",
          "language": "Language",
          "autoBoot": "Auto Startup",
          "dataFetchInterval": "Data Retrieval Interval",
          "changeAccount": "Change Account",
          "saveSettings": "Save Settings",
          "change": "Change",
          "noUpdate": "No Update for Now",
          "verifiedSaved": "Verified, being saved",
          "saveSuccess": "Successfully saved",
          "desc1": " Language of the software; if translations are missing, default to Chinese *r",
          "desc2": "Automatically open the application and hide it in the system tray after startup",
          "desc3": "Interval for checking new grades or homework (10 min ≤ t ≤ 120 min) *s",
          "desc4": "Student account used for logging in to Jupiter ED for data retrieval",
          "desc5": "For bypassing Jupiter CF anti-scraping (entire Cookie string in request header)",
          "info1":
              "Please wait for the data retrieval to complete; do not repeatedly click the data retrieval button during this time",
          "info2": "Data retrieval is complete; reopen the details page to view the information",
          "info3": "Are you sure you want to clear the notification queue?",
          "info4": "A browser is already retrieving data",
          "info5": "Data retrieval has started; please be patient",
          "info6":
              "*s = This setting takes effect only after clicking Save\n*r = This setting takes effect only after the application is restarted",
          "err1": "The string must not be empty or the same as the old value",
          "err2": "Invalid data retrieval interval",
          "err3": "Chromium automated browser encountered a context exception and failed to retrieve homework details",
          "err4": "Remote server offline or network issue",
        },
        "ko_KR": {
          "goToJupiter": "주피터로 이동",
          "dataFetchTimeTooltip": "데이터 검색 성공 시간입니다",
          "dateFetchSuccess": "데이터 검색 성공",
          "dataFetchInProgress": "데이터 검색 중...",
          "dataFetchFailure": "데이터 검색 실패",
          "pleaseLogin": "로그인해 주세요~",
          "usernameOrEmail": "사용자 이름/이메일",
          "password": "비밀번호",
          "login": "로그인",
          "updateNotice": "업데이트 알림",
          "updating": "업데이트 중...",
          "updateImmediately": "즉시 업데이트",
          "cancel": "취소",
          "jupiterAccountInfo": "주피터 계정 정보",
          "usernameOrSid": "사용자 이름/SID",
          "confirm": "확인",
          "cookieString": "쿠키 문자열",
          "author": "앱 저자: KiriRainCat (柒夜雨猫)",
          "version": "앱 버전",
          "checkUpdate": "업데이트 확인",
          "browserClose": "브라우저 닫기",
          "homePage": "홈 페이지",
          "class": "과목",
          "notification": "알림",
          "calendar": "달력",
          "setting": "설정",
          "about": "소개",
          "re": "다시",
          "fetchDirection": "방향 정보 검색",
          "newHomework": "새로운 숙제 알림",
          "remove": "제거",
          "tooltip": "툴팁",
          "forceFetchData": "데이터 강제 검색 (소프트웨어가 중단되면 수동으로 소프트웨어를 재부팅합니다)",
          "clearQueue": "대기열 지우기",
          "deadlineTill": "마감일까지",
          "daysTillHomework": "일 동안의 숙제",
          "incomplete": "미완료",
          "complete": "완료",
          "language": "언어",
          "autoBoot": "자동 시작",
          "dataFetchInterval": "데이터 검색 간격",
          "changeAccount": "계정 변경",
          "saveSettings": "설정 저장",
          "change": "변경",
          "noUpdate": "업데이트 없음",
          "verifiedSaved": "검증 성공, 저장됨",
          "saveSuccess": "저장 성공",
          "desc1": "소프트웨어의 인터페이스 언어, 특정 번역이 없는 경우 기본적으로 중국어로 표시됩니다 *r",
          "desc2": "시스템 시작 후 애플리케이션을 자동으로 열고 시스템 트레이에 숨깁니다",
          "desc3": "주피터에 로그인하여 새로운 성적 또는 숙제가 있는지 확인하는 간격 (10 분 ≤ t ≤ 120 분) *s",
          "desc4": "데이터 검색을 위해 주피터 ED에 로그인하는 학생 계정",
          "info1": "데이터 검색 완료 안내를 기다려주세요. 이 동안 데이터 검색 버튼을 반복해서 클릭하지 마세요",
          "info2": "데이터 검색이 완료되었습니다. 정보를 보려면 세부 페이지를 다시 엽니다",
          "info3": "메시지 대기열을 지우시겠습니까?",
          "info4": "이미 브라우저가 데이터를 검색 중입니다",
          "info5": "데이터 검색이 시작되었습니다. 기다려 주세요",
          "info6": "*s = 이 설정은 저장을 클릭한 후에만 적용됩니다\n*r = 이 설정은 애플리케이션을 다시 시작한 후에만 적용됩니다",
          "desc5": "주피터 CF 반 스크래핑 우회에 사용되는 쿠키 (요청 헤더의 전체 쿠키 문자열)"
        }
      };
}
