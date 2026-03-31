import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case es = "es"
    case pt = "pt"
    case fr = "fr"
    case de = "de"
    case ja = "ja"
    case zh = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .es: return "Español"
        case .pt: return "Português"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .ja: return "日本語"
        case .zh: return "中文"
        }
    }
}

// MARK: - Localization keys

enum L10n {
    // Setup
    static var setupTitle: String { localized("setup_title") }
    static var step1Title: String { localized("step1_title") }
    static var step1Description: String { localized("step1_description") }
    static var selectFile: String { localized("select_file") }
    static var step2Title: String { localized("step2_title") }
    static var step2Description: String { localized("step2_description") }
    static var signIn: String { localized("sign_in") }
    static var reopenSignIn: String { localized("reopen_sign_in") }
    static var pasteCode: String { localized("paste_code") }
    static var submit: String { localized("submit") }

    // Earnings
    static var earningsTitle: String { localized("earnings_title") }
    static var today: String { localized("today") }
    static var yesterday: String { localized("yesterday") }
    static var last7Days: String { localized("last_7_days") }
    static var thisMonth: String { localized("this_month") }
    static var updated: String { localized("updated") }
    static var signOut: String { localized("sign_out") }
    static var quit: String { localized("quit") }
    static var refresh: String { localized("refresh") }
    static var language: String { localized("language") }

    // Errors
    static var errorNotLoggedIn: String { localized("error_not_logged_in") }
    static var invalidJSON: String { localized("invalid_json") }

    // Onboarding
    static var onboardingWelcomeTitle: String { localized("onboarding_welcome_title") }
    static var onboardingWelcomeDesc: String { localized("onboarding_welcome_desc") }
    static var onboardingStep1Title: String { localized("onboarding_step1_title") }
    static var onboardingStep1Desc: String { localized("onboarding_step1_desc") }
    static var onboardingStep2Title: String { localized("onboarding_step2_title") }
    static var onboardingStep2Desc: String { localized("onboarding_step2_desc") }
    static var onboardingStep3Title: String { localized("onboarding_step3_title") }
    static var onboardingStep3Desc: String { localized("onboarding_step3_desc") }
    static var onboardingStep4Title: String { localized("onboarding_step4_title") }
    static var onboardingStep4Desc: String { localized("onboarding_step4_desc") }
    static var onboardingStep5Title: String { localized("onboarding_step5_title") }
    static var onboardingStep5Desc: String { localized("onboarding_step5_desc") }
    static var onboardingNext: String { localized("onboarding_next") }
    static var onboardingBack: String { localized("onboarding_back") }
    static var onboardingGetStarted: String { localized("onboarding_get_started") }
    static var onboardingSkip: String { localized("onboarding_skip") }

    // Donation
    static var buyCoffee: String { localized("buy_coffee") }

    // Settings
    static var settings: String { localized("settings") }
    static var launchAtLogin: String { localized("launch_at_login") }
    static var refreshInterval: String { localized("refresh_interval") }
    static var replayOnboarding: String { localized("replay_onboarding") }

    // Apps & Actions
    static var apps: String { localized("apps") }
    static var appBreakdown: String { localized("app_breakdown") }
    static var openAdMob: String { localized("open_admob") }
    static var vsYesterday: String { localized("vs_yesterday") }
    static var noAppsFound: String { localized("no_apps_found") }
    static var poweredBy: String { localized("powered_by") }
    static var topApps: String { localized("top_apps") }
    static var notchMode: String { localized("notch_mode") }
}

// MARK: - Localization engine

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        currentLanguage = AppLanguage(rawValue: saved) ?? .system
    }

    var resolvedLanguage: String {
        if currentLanguage == .system {
            let preferred = Locale.preferredLanguages.first ?? "en"
            // Extract base language code
            let code = String(preferred.prefix(2))
            return AppLanguage(rawValue: code) != nil ? code : "en"
        }
        return currentLanguage.rawValue
    }
}

private func localized(_ key: String) -> String {
    let lang = LocalizationService.shared.resolvedLanguage
    guard let strings = translations[lang] ?? translations["en"],
          let value = strings[key]
    else { return key }
    return value
}

// MARK: - Translations

private let translations: [String: [String: String]] = [
    "en": [
        "setup_title": "AdMob Widget Setup",
        "step1_title": "Step 1: Import OAuth Credentials",
        "step1_description": "Go to Google API Console, create OAuth 2.0 credentials (Desktop app), and download the JSON file.",
        "select_file": "Select client_secret.json",
        "step2_title": "Step 2: Sign in with Google",
        "step2_description": "1. Click the button to open Google sign-in\n2. Authorize AdMob access\n3. Copy the code and paste it below",
        "sign_in": "Sign in with Google",
        "reopen_sign_in": "Re-open Google sign-in",
        "paste_code": "Paste authorization code here",
        "submit": "Submit",
        "earnings_title": "AdMob Earnings",
        "today": "Today",
        "yesterday": "Yesterday",
        "last_7_days": "Last 7 days",
        "this_month": "This month",
        "updated": "Updated",
        "sign_out": "Sign Out",
        "quit": "Quit AdMob Widget",
        "refresh": "Refresh",
        "language": "Language",
        "error_not_logged_in": "Not logged in",
        "invalid_json": "Invalid JSON file",
        "onboarding_welcome_title": "Welcome to AdMob Widget",
        "onboarding_welcome_desc": "Track your AdMob earnings right from your menu bar. Let's set it up in a few minutes.",
        "onboarding_step1_title": "Create Google Cloud Project",
        "onboarding_step1_desc": "Go to console.cloud.google.com and create a new project. Name it 'AdMob' or anything you like.",
        "onboarding_step2_title": "Enable AdMob API",
        "onboarding_step2_desc": "In your project, go to APIs & Services > Library. Search 'AdMob API' and click Enable.",
        "onboarding_step3_title": "Configure OAuth",
        "onboarding_step3_desc": "Go to Google Auth Platform > Branding. Set app name to 'AdMob Widget'. Then go to Audience and add your Gmail as a test user.",
        "onboarding_step4_title": "Create Credentials",
        "onboarding_step4_desc": "Go to Clients > Create Client. Select 'Desktop app', name it 'AdMob Widget', and download the JSON file.",
        "onboarding_step5_title": "Import & Sign In",
        "onboarding_step5_desc": "Click 'Get Started' below, then import your JSON file and sign in with Google. That's it!",
        "onboarding_next": "Next",
        "onboarding_back": "Back",
        "onboarding_get_started": "Get Started",
        "onboarding_skip": "Skip",
        "buy_coffee": "Buy Me a Coffee",
        "settings": "Settings",
        "launch_at_login": "Launch at Login",
        "refresh_interval": "Refresh Interval",
        "replay_onboarding": "Replay Setup Guide",
        "apps": "Apps",
        "app_breakdown": "Earnings by App",
        "open_admob": "Open AdMob",
        "vs_yesterday": "vs yesterday",
        "no_apps_found": "No apps found",
        "powered_by": "Powered by",
        "top_apps": "Top Earning Apps",
        "notch_mode": "Notch Hover Mode",
    ],
    "es": [
        "setup_title": "Configuración AdMob Widget",
        "step1_title": "Paso 1: Importar credenciales OAuth",
        "step1_description": "Ve a Google API Console, crea credenciales OAuth 2.0 (App de escritorio) y descarga el archivo JSON.",
        "select_file": "Seleccionar client_secret.json",
        "step2_title": "Paso 2: Iniciar sesión con Google",
        "step2_description": "1. Haz clic en el botón para abrir Google\n2. Autoriza el acceso a AdMob\n3. Copia el código y pégalo abajo",
        "sign_in": "Iniciar sesión con Google",
        "reopen_sign_in": "Reabrir inicio de sesión",
        "paste_code": "Pega el código de autorización aquí",
        "submit": "Enviar",
        "earnings_title": "Ingresos AdMob",
        "today": "Hoy",
        "yesterday": "Ayer",
        "last_7_days": "Últimos 7 días",
        "this_month": "Este mes",
        "updated": "Actualizado",
        "sign_out": "Cerrar sesión",
        "quit": "Salir de AdMob Widget",
        "refresh": "Actualizar",
        "language": "Idioma",
        "error_not_logged_in": "No has iniciado sesión",
        "invalid_json": "Archivo JSON inválido",
        "onboarding_welcome_title": "Bienvenido a AdMob Widget",
        "onboarding_welcome_desc": "Consulta tus ingresos de AdMob desde la barra de menú. Vamos a configurarlo en unos minutos.",
        "onboarding_step1_title": "Crear proyecto en Google Cloud",
        "onboarding_step1_desc": "Ve a console.cloud.google.com y crea un nuevo proyecto. Nómbralo 'AdMob' o como prefieras.",
        "onboarding_step2_title": "Habilitar API de AdMob",
        "onboarding_step2_desc": "En tu proyecto, ve a APIs y servicios > Biblioteca. Busca 'AdMob API' y haz clic en Habilitar.",
        "onboarding_step3_title": "Configurar OAuth",
        "onboarding_step3_desc": "Ve a Google Auth Platform > Branding. Establece el nombre de la app como 'AdMob Widget'. Luego ve a Audiencia y agrega tu Gmail como usuario de prueba.",
        "onboarding_step4_title": "Crear credenciales",
        "onboarding_step4_desc": "Ve a Clientes > Crear cliente. Selecciona 'App de escritorio', nómbrala 'AdMob Widget' y descarga el archivo JSON.",
        "onboarding_step5_title": "Importar e iniciar sesión",
        "onboarding_step5_desc": "Haz clic en 'Comenzar' abajo, importa tu archivo JSON e inicia sesión con Google. ¡Eso es todo!",
        "onboarding_next": "Siguiente",
        "onboarding_back": "Atrás",
        "onboarding_get_started": "Comenzar",
        "onboarding_skip": "Omitir",
        "buy_coffee": "Invítame un café",
        "settings": "Ajustes",
        "launch_at_login": "Iniciar al encender",
        "refresh_interval": "Intervalo de actualización",
        "replay_onboarding": "Ver guía de configuración",
        "apps": "Apps",
        "app_breakdown": "Ingresos por app",
        "open_admob": "Abrir AdMob",
        "vs_yesterday": "vs ayer",
        "no_apps_found": "No se encontraron apps",
        "powered_by": "Desarrollado por",
        "top_apps": "Apps con más ingresos",
        "notch_mode": "Modo Notch",
    ],
    "pt": [
        "setup_title": "Configuração AdMob Widget",
        "step1_title": "Passo 1: Importar credenciais OAuth",
        "step1_description": "Vá ao Google API Console, crie credenciais OAuth 2.0 (App de desktop) e baixe o arquivo JSON.",
        "select_file": "Selecionar client_secret.json",
        "step2_title": "Passo 2: Entrar com Google",
        "step2_description": "1. Clique no botão para abrir o Google\n2. Autorize o acesso ao AdMob\n3. Copie o código e cole abaixo",
        "sign_in": "Entrar com Google",
        "reopen_sign_in": "Reabrir login do Google",
        "paste_code": "Cole o código de autorização aqui",
        "submit": "Enviar",
        "earnings_title": "Receitas AdMob",
        "today": "Hoje",
        "yesterday": "Ontem",
        "last_7_days": "Últimos 7 dias",
        "this_month": "Este mês",
        "updated": "Atualizado",
        "sign_out": "Sair",
        "quit": "Fechar AdMob Widget",
        "refresh": "Atualizar",
        "language": "Idioma",
        "error_not_logged_in": "Não conectado",
        "invalid_json": "Arquivo JSON inválido",
        "onboarding_welcome_title": "Bem-vindo ao AdMob Widget",
        "onboarding_welcome_desc": "Acompanhe seus ganhos do AdMob direto na barra de menu. Vamos configurar em poucos minutos.",
        "onboarding_step1_title": "Criar projeto no Google Cloud",
        "onboarding_step1_desc": "Acesse console.cloud.google.com e crie um novo projeto. Nomeie como 'AdMob' ou o que preferir.",
        "onboarding_step2_title": "Ativar API do AdMob",
        "onboarding_step2_desc": "No seu projeto, vá em APIs e serviços > Biblioteca. Pesquise 'AdMob API' e clique em Ativar.",
        "onboarding_step3_title": "Configurar OAuth",
        "onboarding_step3_desc": "Vá em Google Auth Platform > Branding. Defina o nome do app como 'AdMob Widget'. Depois vá em Audiência e adicione seu Gmail como usuário de teste.",
        "onboarding_step4_title": "Criar credenciais",
        "onboarding_step4_desc": "Vá em Clientes > Criar cliente. Selecione 'App de desktop', nomeie como 'AdMob Widget' e baixe o arquivo JSON.",
        "onboarding_step5_title": "Importar e fazer login",
        "onboarding_step5_desc": "Clique em 'Começar' abaixo, importe seu arquivo JSON e faça login com o Google. Pronto!",
        "onboarding_next": "Próximo",
        "onboarding_back": "Voltar",
        "onboarding_get_started": "Começar",
        "onboarding_skip": "Pular",
        "buy_coffee": "Me pague um café",
        "settings": "Configurações",
        "launch_at_login": "Iniciar ao ligar",
        "refresh_interval": "Intervalo de atualização",
        "replay_onboarding": "Ver guia de configuração",
        "apps": "Apps",
        "app_breakdown": "Receitas por app",
        "open_admob": "Abrir AdMob",
        "vs_yesterday": "vs ontem",
        "no_apps_found": "Nenhum app encontrado",
        "powered_by": "Desenvolvido por",
        "top_apps": "Apps com mais receita",
        "notch_mode": "Modo Notch",
    ],
    "fr": [
        "setup_title": "Configuration AdMob Widget",
        "step1_title": "Étape 1 : Importer les identifiants OAuth",
        "step1_description": "Allez sur Google API Console, créez des identifiants OAuth 2.0 (Application de bureau) et téléchargez le fichier JSON.",
        "select_file": "Sélectionner client_secret.json",
        "step2_title": "Étape 2 : Se connecter avec Google",
        "step2_description": "1. Cliquez sur le bouton pour ouvrir Google\n2. Autorisez l'accès AdMob\n3. Copiez le code et collez-le ci-dessous",
        "sign_in": "Se connecter avec Google",
        "reopen_sign_in": "Rouvrir la connexion Google",
        "paste_code": "Collez le code d'autorisation ici",
        "submit": "Envoyer",
        "earnings_title": "Revenus AdMob",
        "today": "Aujourd'hui",
        "yesterday": "Hier",
        "last_7_days": "7 derniers jours",
        "this_month": "Ce mois-ci",
        "updated": "Mis à jour",
        "sign_out": "Déconnexion",
        "quit": "Quitter AdMob Widget",
        "refresh": "Rafraîchir",
        "language": "Langue",
        "error_not_logged_in": "Non connecté",
        "invalid_json": "Fichier JSON invalide",
        "onboarding_welcome_title": "Bienvenue sur AdMob Widget",
        "onboarding_welcome_desc": "Suivez vos revenus AdMob directement depuis la barre de menus. Configurons-le en quelques minutes.",
        "onboarding_step1_title": "Créer un projet Google Cloud",
        "onboarding_step1_desc": "Allez sur console.cloud.google.com et créez un nouveau projet. Nommez-le 'AdMob' ou ce que vous voulez.",
        "onboarding_step2_title": "Activer l'API AdMob",
        "onboarding_step2_desc": "Dans votre projet, allez dans APIs et services > Bibliothèque. Recherchez 'AdMob API' et cliquez sur Activer.",
        "onboarding_step3_title": "Configurer OAuth",
        "onboarding_step3_desc": "Allez dans Google Auth Platform > Branding. Définissez le nom de l'app comme 'AdMob Widget'. Puis allez dans Audience et ajoutez votre Gmail comme utilisateur test.",
        "onboarding_step4_title": "Créer des identifiants",
        "onboarding_step4_desc": "Allez dans Clients > Créer un client. Sélectionnez 'Application de bureau', nommez-la 'AdMob Widget' et téléchargez le fichier JSON.",
        "onboarding_step5_title": "Importer et se connecter",
        "onboarding_step5_desc": "Cliquez sur 'Commencer' ci-dessous, importez votre fichier JSON et connectez-vous avec Google. C'est tout !",
        "onboarding_next": "Suivant",
        "onboarding_back": "Retour",
        "onboarding_get_started": "Commencer",
        "onboarding_skip": "Passer",
        "buy_coffee": "Offrez-moi un café",
        "settings": "Paramètres",
        "launch_at_login": "Lancer au démarrage",
        "refresh_interval": "Intervalle de rafraîchissement",
        "replay_onboarding": "Revoir le guide de configuration",
        "apps": "Apps",
        "app_breakdown": "Revenus par app",
        "open_admob": "Ouvrir AdMob",
        "vs_yesterday": "vs hier",
        "no_apps_found": "Aucune app trouvée",
        "powered_by": "Propulsé par",
        "top_apps": "Apps les plus rentables",
        "notch_mode": "Mode Encoche",
    ],
    "de": [
        "setup_title": "AdMob Widget Einrichtung",
        "step1_title": "Schritt 1: OAuth-Anmeldedaten importieren",
        "step1_description": "Gehen Sie zur Google API Console, erstellen Sie OAuth 2.0-Anmeldedaten (Desktop-App) und laden Sie die JSON-Datei herunter.",
        "select_file": "client_secret.json auswählen",
        "step2_title": "Schritt 2: Mit Google anmelden",
        "step2_description": "1. Klicken Sie auf die Schaltfläche\n2. AdMob-Zugriff autorisieren\n3. Code kopieren und unten einfügen",
        "sign_in": "Mit Google anmelden",
        "reopen_sign_in": "Google-Anmeldung erneut öffnen",
        "paste_code": "Autorisierungscode hier einfügen",
        "submit": "Absenden",
        "earnings_title": "AdMob Einnahmen",
        "today": "Heute",
        "yesterday": "Gestern",
        "last_7_days": "Letzte 7 Tage",
        "this_month": "Dieser Monat",
        "updated": "Aktualisiert",
        "sign_out": "Abmelden",
        "quit": "AdMob Widget beenden",
        "refresh": "Aktualisieren",
        "language": "Sprache",
        "error_not_logged_in": "Nicht angemeldet",
        "invalid_json": "Ungültige JSON-Datei",
        "onboarding_welcome_title": "Willkommen bei AdMob Widget",
        "onboarding_welcome_desc": "Verfolgen Sie Ihre AdMob-Einnahmen direkt in der Menüleiste. Richten wir es in wenigen Minuten ein.",
        "onboarding_step1_title": "Google Cloud-Projekt erstellen",
        "onboarding_step1_desc": "Gehen Sie zu console.cloud.google.com und erstellen Sie ein neues Projekt. Nennen Sie es 'AdMob' oder wie Sie möchten.",
        "onboarding_step2_title": "AdMob API aktivieren",
        "onboarding_step2_desc": "Gehen Sie in Ihrem Projekt zu APIs und Dienste > Bibliothek. Suchen Sie 'AdMob API' und klicken Sie auf Aktivieren.",
        "onboarding_step3_title": "OAuth konfigurieren",
        "onboarding_step3_desc": "Gehen Sie zu Google Auth Platform > Branding. Setzen Sie den App-Namen auf 'AdMob Widget'. Gehen Sie dann zu Zielgruppe und fügen Sie Ihre Gmail als Testbenutzer hinzu.",
        "onboarding_step4_title": "Anmeldedaten erstellen",
        "onboarding_step4_desc": "Gehen Sie zu Clients > Client erstellen. Wählen Sie 'Desktop-App', nennen Sie sie 'AdMob Widget' und laden Sie die JSON-Datei herunter.",
        "onboarding_step5_title": "Importieren und anmelden",
        "onboarding_step5_desc": "Klicken Sie unten auf 'Loslegen', importieren Sie Ihre JSON-Datei und melden Sie sich mit Google an. Das war's!",
        "onboarding_next": "Weiter",
        "onboarding_back": "Zurück",
        "onboarding_get_started": "Loslegen",
        "onboarding_skip": "Überspringen",
        "buy_coffee": "Kauf mir einen Kaffee",
        "settings": "Einstellungen",
        "launch_at_login": "Beim Anmelden starten",
        "refresh_interval": "Aktualisierungsintervall",
        "replay_onboarding": "Einrichtungsanleitung erneut anzeigen",
        "apps": "Apps",
        "app_breakdown": "Einnahmen pro App",
        "open_admob": "AdMob öffnen",
        "vs_yesterday": "vs gestern",
        "no_apps_found": "Keine Apps gefunden",
        "powered_by": "Bereitgestellt von",
        "top_apps": "Top-Verdiener-Apps",
        "notch_mode": "Notch-Modus",
    ],
    "ja": [
        "setup_title": "AdMob Widget セットアップ",
        "step1_title": "ステップ1: OAuth認証情報をインポート",
        "step1_description": "Google APIコンソールでOAuth 2.0認証情報（デスクトップアプリ）を作成し、JSONファイルをダウンロードしてください。",
        "select_file": "client_secret.jsonを選択",
        "step2_title": "ステップ2: Googleでサインイン",
        "step2_description": "1. ボタンをクリックしてGoogleを開く\n2. AdMobアクセスを許可\n3. コードをコピーして下に貼り付け",
        "sign_in": "Googleでサインイン",
        "reopen_sign_in": "Googleサインインを再度開く",
        "paste_code": "認証コードをここに貼り付け",
        "submit": "送信",
        "earnings_title": "AdMob 収益",
        "today": "今日",
        "yesterday": "昨日",
        "last_7_days": "過去7日間",
        "this_month": "今月",
        "updated": "更新",
        "sign_out": "サインアウト",
        "quit": "AdMob Widgetを終了",
        "refresh": "更新",
        "language": "言語",
        "error_not_logged_in": "ログインしていません",
        "invalid_json": "無効なJSONファイル",
        "onboarding_welcome_title": "AdMob Widgetへようこそ",
        "onboarding_welcome_desc": "メニューバーからAdMobの収益を確認できます。数分で設定しましょう。",
        "onboarding_step1_title": "Google Cloudプロジェクトを作成",
        "onboarding_step1_desc": "console.cloud.google.comにアクセスして新しいプロジェクトを作成します。名前は「AdMob」など自由に付けてください。",
        "onboarding_step2_title": "AdMob APIを有効化",
        "onboarding_step2_desc": "プロジェクト内でAPIとサービス > ライブラリに移動します。「AdMob API」を検索して有効化をクリックします。",
        "onboarding_step3_title": "OAuthを設定",
        "onboarding_step3_desc": "Google Auth Platform > ブランディングに移動します。アプリ名を「AdMob Widget」に設定します。次にオーディエンスでGmailをテストユーザーとして追加します。",
        "onboarding_step4_title": "認証情報を作成",
        "onboarding_step4_desc": "クライアント > クライアントを作成に移動します。「デスクトップアプリ」を選択し、「AdMob Widget」と名付けてJSONファイルをダウンロードします。",
        "onboarding_step5_title": "インポートしてサインイン",
        "onboarding_step5_desc": "下の「始める」をクリックし、JSONファイルをインポートしてGoogleでサインインします。以上です！",
        "onboarding_next": "次へ",
        "onboarding_back": "戻る",
        "onboarding_get_started": "始める",
        "onboarding_skip": "スキップ",
        "buy_coffee": "コーヒーをおごる",
        "settings": "設定",
        "launch_at_login": "ログイン時に起動",
        "refresh_interval": "更新間隔",
        "replay_onboarding": "セットアップガイドを再表示",
        "apps": "アプリ",
        "app_breakdown": "アプリ別収益",
        "open_admob": "AdMobを開く",
        "vs_yesterday": "vs 昨日",
        "no_apps_found": "アプリが見つかりません",
        "powered_by": "Powered by",
        "top_apps": "Top Earning Apps",
        "notch_mode": "Notch Hover Mode",
    ],
    "zh": [
        "setup_title": "AdMob Widget 设置",
        "step1_title": "第1步：导入OAuth凭据",
        "step1_description": "前往Google API控制台，创建OAuth 2.0凭据（桌面应用），然后下载JSON文件。",
        "select_file": "选择 client_secret.json",
        "step2_title": "第2步：使用Google登录",
        "step2_description": "1. 点击按钮打开Google登录\n2. 授权AdMob访问\n3. 复制代码并粘贴到下方",
        "sign_in": "使用Google登录",
        "reopen_sign_in": "重新打开Google登录",
        "paste_code": "在此粘贴授权代码",
        "submit": "提交",
        "earnings_title": "AdMob 收入",
        "today": "今天",
        "yesterday": "昨天",
        "last_7_days": "最近7天",
        "this_month": "本月",
        "updated": "已更新",
        "sign_out": "退出登录",
        "quit": "退出 AdMob Widget",
        "refresh": "刷新",
        "language": "语言",
        "error_not_logged_in": "未登录",
        "invalid_json": "无效的JSON文件",
        "onboarding_welcome_title": "欢迎使用 AdMob Widget",
        "onboarding_welcome_desc": "直接从菜单栏查看您的AdMob收入。几分钟内即可完成设置。",
        "onboarding_step1_title": "创建 Google Cloud 项目",
        "onboarding_step1_desc": "访问 console.cloud.google.com 并创建一个新项目。命名为「AdMob」或任意名称。",
        "onboarding_step2_title": "启用 AdMob API",
        "onboarding_step2_desc": "在项目中，转到 API 和服务 > 库。搜索「AdMob API」并点击启用。",
        "onboarding_step3_title": "配置 OAuth",
        "onboarding_step3_desc": "转到 Google Auth Platform > 品牌。将应用名称设为「AdMob Widget」。然后转到受众群体，将您的 Gmail 添加为测试用户。",
        "onboarding_step4_title": "创建凭据",
        "onboarding_step4_desc": "转到客户端 > 创建客户端。选择「桌面应用」，命名为「AdMob Widget」，然后下载 JSON 文件。",
        "onboarding_step5_title": "导入并登录",
        "onboarding_step5_desc": "点击下方「开始」，导入您的 JSON 文件并使用 Google 登录。就这么简单！",
        "onboarding_next": "下一步",
        "onboarding_back": "返回",
        "onboarding_get_started": "开始",
        "onboarding_skip": "跳过",
        "buy_coffee": "请我喝杯咖啡",
        "settings": "设置",
        "launch_at_login": "登录时启动",
        "refresh_interval": "刷新间隔",
        "replay_onboarding": "重新查看设置指南",
        "apps": "应用",
        "app_breakdown": "按应用查看收入",
        "open_admob": "打开 AdMob",
        "vs_yesterday": "vs 昨天",
        "no_apps_found": "未找到应用",
        "powered_by": "由",
        "top_apps": "收入最高的应用",
        "notch_mode": "刘海模式",
    ],
]
