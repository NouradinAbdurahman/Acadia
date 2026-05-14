// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String helloUser(String name) {
    return 'Tekrar hoş geldin, $name';
  }

  @override
  String get academicOverview => 'Akademik genel bakışınız';

  @override
  String get aiInsightTitle => 'İçgörü';

  @override
  String get aiInsightSectionTitle => 'AI içgörüsü';

  @override
  String get aiInsightPrimaryReasonLabel => 'Neden';

  @override
  String get aiInsightWhatToDoLabel => 'Eylem';

  @override
  String get aiInsightConfidenceHeading => 'Güven';

  @override
  String get confidenceWordHigh => 'Yüksek';

  @override
  String get confidenceWordMedium => 'Orta';

  @override
  String get confidenceWordLow => 'Düşük';

  @override
  String aiInsightConfidenceLine(String level) {
    return 'Güven: $level';
  }

  @override
  String get aiRecommendationTitle => 'Öneri';

  @override
  String get aiActionStartStudy => 'Çalışma oturumu başlat';

  @override
  String get aiActionAddTask => 'Görev ekle';

  @override
  String get aiActionViewTasks => 'Görevlere git';

  @override
  String get aiActionOpenAnalytics => 'Analizleri aç';

  @override
  String get aiPassiveRiskSpike =>
      'Akademik risk belirgin şekilde değişti. Kısa bir kontrol düşünün.';

  @override
  String get aiPassiveOpenAssistant => 'Asistanı aç';

  @override
  String get aiPassiveReviewTasksNow => 'Görevleri şimdi gözden geçir';

  @override
  String get aiPassiveViewAnalytics => 'Analizleri görüntüle';

  @override
  String get academicRisk => 'Akademik Risk';

  @override
  String get lowRisk => 'Düşük Risk';

  @override
  String get score => 'Skor';

  @override
  String get tasksToday => 'Bugünkü Görevler';

  @override
  String tasksPending(int count) {
    return '$count görev bekliyor';
  }

  @override
  String get upcomingDeadlines => 'Yaklaşan Son Tarihler';

  @override
  String thisWeek(int count) {
    return 'Bu hafta $count tane';
  }

  @override
  String get noDeadlinesWeek => 'Bu hafta son tarih yok';

  @override
  String get studyTimeToday => 'Bugünkü Çalışma Süresi';

  @override
  String get noStudyLogged => 'Bugün çalışma kaydedilmedi';

  @override
  String get noTasksForThisCourse => 'Bu ders için görev yok';

  @override
  String get noDeadlinesForThisCourse => 'Bu ders için son tarih yok';

  @override
  String get noSessionsForThisCourse => 'Bu ders için oturum yok';

  @override
  String get profile => 'Profil';

  @override
  String get account => 'Hesap';

  @override
  String get preferences => 'Tercihler';

  @override
  String get support => 'Destek';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Karanlık Mod';

  @override
  String get aboutApp => 'Uygulama Hakkında';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get deleteAccountTitle => 'Hesabı Sil';

  @override
  String get deleteAccountWarning =>
      'Bu işlem kalıcıdır ve geri alınamaz. Hesap verileriniz, dönem geçmişiniz, görevleriniz ve analizleriniz silinir; erişiminiz hemen kapanır. Devam etmek istediğinize emin misiniz?';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get noNotifications => 'Henüz bildirim yok';

  @override
  String get notificationsCaughtUp => 'Her şey yolunda';

  @override
  String get noMoodNotificationsYet => 'Henüz ruh hali bildirimi yok';

  @override
  String get noAcademicNotificationsYet => 'Henüz akademik bildirim yok';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get earlier => 'Daha Önce';

  @override
  String get thisMonthLabel => 'Bu Ay';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get overview => 'Genel Bakış';

  @override
  String get searchHint => 'Görev, sınav veya içgörü ara';

  @override
  String get email => 'E-posta';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get themeLight => 'Aydınlık';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get tasks => 'Görevler';

  @override
  String get all => 'Hepsi';

  @override
  String get quickMenu => 'Hızlı Menü';

  @override
  String get deadlineKindBadge => 'Son tarih';

  @override
  String get linkToAcademicDeadline => 'Son tarihe bağla (isteğe bağlı)';

  @override
  String get noneLinkedDeadline => 'Yok';

  @override
  String get relatedTasksSection => 'İlgili görevler';

  @override
  String get addTaskToThisDeadline => 'Bu son tarihe görev ekle';

  @override
  String deadlineLinkedTasksProgress(int completed, int total) {
    return '$completed/$total görev tamamlandı';
  }

  @override
  String get deadlineNoLinkedTasks => 'Bu son tarihe henüz görev bağlanmadı.';

  @override
  String get taskLinkedToDeadline => 'Bir son tarihe bağlı';

  @override
  String get pending => 'Bekleyen';

  @override
  String get deadlines => 'Son Tarihler';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get overdue => 'Gecikmiş';

  @override
  String get createTask => 'Görev Oluştur';

  @override
  String get taskTitle => 'Görev Başlığı';

  @override
  String get course => 'Ders';

  @override
  String get priority => 'Öncelik';

  @override
  String get low => 'Düşük';

  @override
  String get medium => 'Orta';

  @override
  String get high => 'Yüksek';

  @override
  String get estimatedStudyTime => 'Tahmini Çalışma Süresi';

  @override
  String get notes => 'Notlar';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get study => 'Çalış';

  @override
  String get liveStudySessions => 'Canlı Çalışma Oturumları';

  @override
  String get startStudySession => 'Çalışma Oturumu';

  @override
  String get start => 'Başlat';

  @override
  String get pause => 'Duraklat';

  @override
  String get resume => 'Devam Et';

  @override
  String get stop => 'Durdur';

  @override
  String get focusLabel => 'Odaklanma';

  @override
  String get breakLabel => 'Ara';

  @override
  String get reviewLabel => 'Tekrar';

  @override
  String get remainingLabel => 'Kalan Süre';

  @override
  String get stopSessionTitle => 'Oturumu Durdur';

  @override
  String get stopSessionConfirm =>
      'Bu çalışma oturumunu sonlandırmak istediğinizden emin misiniz?';

  @override
  String get sessionPaused => 'Oturum duraklatıldı. Bir nefes alın.';

  @override
  String get refreshYourself => 'Kendinizi tazeleyin. Harika gidiyorsunuz.';

  @override
  String get stayFocused => 'Odaklı kalın. İyi gidiyorsunuz.';

  @override
  String get deepWorkInProgress => 'Derin çalışma devam ediyor...';

  @override
  String get dontStopNow => 'Şimdi durmayın, harika gidiyorsunuz!';

  @override
  String get focusOnProcess => 'Sürece odaklanın, sonuçlara değil.';

  @override
  String get almostThere => 'Neredeyse bitti! Devam edin.';

  @override
  String get futureSelf => 'Gelecekteki kendiniz size teşekkür edecek.';

  @override
  String get sessionCompleted => 'Oturum tamamlandı';

  @override
  String get recentStudySessions => 'Son Çalışma Oturumlari';

  @override
  String get stayOrganized => 'Düzenli kal';

  @override
  String get createFirstTask =>
      'Ödevleri takip etmeye başlamak için ilk görevinizi oluşturun.';

  @override
  String get couldNotLoadTasks => 'Görevler yüklenemedi.';

  @override
  String get couldNotLoadDeadlines => 'Son tarihler yüklenemedi.';

  @override
  String get delete => 'Sil';

  @override
  String get complete => 'Tamamla';

  @override
  String due(String date) {
    return 'Son Tarih: $date';
  }

  @override
  String estStudy(num time) {
    return 'Tahmini Çalışma: ${time}sa';
  }

  @override
  String get noDeadlinesYet => 'Henüz son tarih yok';

  @override
  String get createFirstDeadline =>
      'Önde kalmak için ilk akademik son tarihinizi oluşturun.';

  @override
  String get createDeadline => 'Son Tarih Oluştur';

  @override
  String get dueToday => 'Bugün son';

  @override
  String daysRemaining(int count) {
    return '$count gün kaldı';
  }

  @override
  String get exam => 'Sınav';

  @override
  String get quiz => 'Quiz';

  @override
  String get project => 'Proje';

  @override
  String get assignment => 'Ödev';

  @override
  String get noDeadline => 'Son tarih yok';

  @override
  String get newAcademicTask => 'Yeni Akademik Görev';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String get optional => 'isteğe bağlı';

  @override
  String get newAcademicDeadline => 'Yeni Akademik Son Tarih';

  @override
  String get pleaseSelectDate => 'Lütfen bir son tarih seçin';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get title => 'Başlık';

  @override
  String get deadlineDate => 'Son Tarih';

  @override
  String get type => 'Tür';

  @override
  String get studySession => 'Çalışma Oturumu';

  @override
  String get saveSession => 'Oturumu Kaydet';

  @override
  String get noStudySessionsYet => 'Henüz çalışma oturumu yok.';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String minutes(int count) {
    return '$count dakika';
  }

  @override
  String get duration => 'Süre';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get review => 'Tekrar';

  @override
  String get deepFocus => 'Derin odak';

  @override
  String get analytics => 'Analiz';

  @override
  String get studyHours => 'Çalışma saatleri';

  @override
  String get taskCompletionRate => 'Görev tamamlama oranı';

  @override
  String get taskStatThisWeekByDeadline => 'Bu hafta (son tarihe göre)';

  @override
  String get taskStatThisSemester => 'Bu dönem';

  @override
  String get taskStatTrendChartPeriod => 'Görevler (grafik dönemi)';

  @override
  String get stressTrends => 'Stres eğilimleri';

  @override
  String get academicReport => 'Akademik Rapor';

  @override
  String get academicHistory => 'Akademik Geçmiş';

  @override
  String get requiresFocus => 'Odaklanma Gerektirir';

  @override
  String get gradeAverage => 'Not ortalaması';

  @override
  String get semesterTrend => 'Dönem Trendi';

  @override
  String get noAcademicHistory => 'Henüz akademik geçmiş yok';

  @override
  String get startLoggingContext =>
      'Geçmiş profilinizi oluşturmak için çalışma oturumlarını kaydedin ve görevleri tamamlayın.';

  @override
  String get activeLabel => 'Aktif';

  @override
  String get switchToSemester => 'Bu Döneme Geç';

  @override
  String get setUpSemester => 'Dönemi Ayarla';

  @override
  String get startAcademicTracking => 'Akademik Takibe Başla';

  @override
  String get gpaPoints => 'GPA Puanı';

  @override
  String get cgpaLabel => 'CGPA';

  @override
  String gpaValueLabel(String value) {
    return 'GPA: $value';
  }

  @override
  String studyTimeDeltaMsg(String action, int percent) {
    return 'Haftalık çalışma süreniz %$percent $action';
  }

  @override
  String riskIncreased(int value) {
    return 'Risk %$value arttı';
  }

  @override
  String riskDecreased(int value) {
    return 'Risk %$value azaldı';
  }

  @override
  String get increased => 'arttı';

  @override
  String get decreased => 'azaldı';

  @override
  String get taskCompletionImproved =>
      'Geçen döneme göre daha fazla görev tamamlıyorsunuz';

  @override
  String get taskCompletionDecreased => 'Görev tamamlama oranınız düştü';

  @override
  String get academicRiskIncreased => 'Akademik riskiniz arttı';

  @override
  String get academicPerformanceSummary => 'Performans Özeti';

  @override
  String get performanceSummarySubtitle =>
      'Tüm dönemler arasındaki uzun vadeli akademik eğilimler';

  @override
  String get bestSemester => 'En İyi Dönem';

  @override
  String get worstSemester => 'En Kötü Dönem';

  @override
  String get mostImproved => 'En Çok Gelişen';

  @override
  String get highestGPA => 'En Yüksek GPA';

  @override
  String get startStudySessionCTA => 'Bir çalışma oturumu başlatın';

  @override
  String get addFirstTaskCTA => 'İlk görevinizi ekleyin';

  @override
  String get startStudyingHint =>
      'Burada etkinlik görmek için çalışmaya başlayın';

  @override
  String get viewHistoryMode => 'Gecmiş Görüntüleniyor';

  @override
  String get comingSoon => 'Çok yakında';

  @override
  String get taskDetail => 'Görev Detayı';

  @override
  String get deadlineDetail => 'Son Tarih Detayı';

  @override
  String get taskNotFound => 'Görev bulunamadı.';

  @override
  String get deadlineNotFound => 'Son tarih bulunamadı.';

  @override
  String get noDeadlineSet => 'Son tarih belirlenmedi';

  @override
  String overdueByDays(int count) {
    return '$count gün gecikti';
  }

  @override
  String dueInDays(int count) {
    return '$count gün içinde';
  }

  @override
  String get editTask => 'Görevi Düzenle';

  @override
  String get editDeadline => 'Son Tarihi Düzenle';

  @override
  String get markAsPending => 'Bekliyor Olarak İşaretle';

  @override
  String get markAsComplete => 'Tamamlandı Olarak İşaretle';

  @override
  String get deleteTask => 'Görevi Sil';

  @override
  String get deleteDeadline => 'Son Tarihi Sil';

  @override
  String get notSet => 'Belirlenmedi';

  @override
  String get estimated => 'Tahmini';

  @override
  String get updateTask => 'Görevi Güncelle';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get welcome => 'Hoş geldiniz';

  @override
  String get appName => 'Acadia';

  @override
  String get welcomeSubtitle => 'Sınav hazırlığınıza devam edin';

  @override
  String get signupSubtitle =>
      'Çalışmalarınızı yönetmeye başlamak için hesabınızı oluşturun';

  @override
  String get password => 'Şifre';

  @override
  String get rememberMe => 'Beni hatırla';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get login => 'Giriş Yap';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu?';

  @override
  String get orContinueWith => 'Veya şununla devam edin';

  @override
  String get googleLabel => 'Google';

  @override
  String get appleLabel => 'Apple';

  @override
  String get signup => 'Hesap Oluştur';

  @override
  String get invalidCredentials => 'Geçersiz e-posta veya şifre.';

  @override
  String get tooManyRequests =>
      'Çok fazla deneme yapıldı. E-posta servisi geçici olarak kısıtlandı. Lütfen birkaç dakika bekleyin.';

  @override
  String get emailRateLimit =>
      'Çok fazla deneme yapıldı. E-posta servisi geçici olarak kısıtlandı. Lütfen birkaç dakika bekleyin.';

  @override
  String emailRateLimitWithTimer(String time) {
    return 'Çok fazla deneme yapıldı. E-posta servisi geçici olarak kısıtlandı. $time sonra tekrar deneyin.';
  }

  @override
  String get pleaseWait => 'Lütfen tekrar denemeden önce biraz bekleyin.';

  @override
  String get networkError => 'Bağlantı hatası. Tekrar deneyin.';

  @override
  String get checkInternetConnection => 'Internet baglantinizi kontrol edin.';

  @override
  String get requestTimedOut => 'Istek zaman asimina ugradi. Tekrar deneyin.';

  @override
  String get invalidEmail => 'Geçersiz bir e-posta girin';

  @override
  String get passwordTooShort => 'Şifre en az 8 karakter olmalıdır';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get requiredField => 'Bu alan zorunludur';

  @override
  String get passwordStrong => 'Güçlü';

  @override
  String get passwordFair => 'Orta';

  @override
  String get passwordWeak => 'Zayıf';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get emailAlreadyInUse =>
      'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.';

  @override
  String get otpExpired => 'Kodun süresi doldu. Yeni bir tane isteyin.';

  @override
  String get tooManyAttempts => 'Lütfen tekrar denemeden önce biraz bekleyin.';

  @override
  String get invalidOtp => 'Geçersiz doğrulama kodu';

  @override
  String get codeResent => 'Kod tekrar gönderildi!';

  @override
  String get verifyEmail => 'E-postayı Doğrula';

  @override
  String get enterOtp => 'E-postanıza gönderilen 6 haneli kodu girin';

  @override
  String get verifyCode => 'Kodu Doğrula';

  @override
  String get resendCode => 'Kodu Tekrar Gönder';

  @override
  String get forgotPasswordTitle => 'Şifremi Unuttum';

  @override
  String get forgotPasswordPrompt =>
      'Şifre sıfırlama kodu almak için e-posta adresinizi girin.';

  @override
  String get sendResetLink => 'Kod Gönder';

  @override
  String get backToLogin => 'Giriş Yap';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get passwordSameAsOld =>
      'Yeni şifre mevcut şifrenizden farklı olmalıdır.';

  @override
  String resendIn(Object count) {
    return '$count saniye içinde tekrar gönder';
  }

  @override
  String tryAgainIn(Object count) {
    return '${count}sn sonra tekrar dene';
  }

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get continueText => 'Devam Et';

  @override
  String get onboardingTitle1 => 'Akademik hayatınıza hakim olun';

  @override
  String get onboardingDesc1 =>
      'Görevlerinizi, sınavlarınızı ve çalışma oturumlarınızı tek bir akıllı çalışma alanında takip edin.';

  @override
  String get onboardingTitle2 => 'Görevlerinizin başında kalın';

  @override
  String get onboardingDesc2 =>
      'Ödevleri ve teslim tarihlerini düzenleyin, böylece hiçbir şey gözden kaçmasın.';

  @override
  String get onboardingTitle3 => 'Gelişiminizi anlayın';

  @override
  String get onboardingDesc3 =>
      'Görsel içgörüler çalışma modellerinizi, üretkenliğinizi ve akademik eğilimlerinizi gösterir.';

  @override
  String get onboardingTitle4 => 'Performans ve refahı dengeleyin';

  @override
  String get onboardingDesc4 =>
      'Stres seviyelerini izleyin ve daha akıllı çalışma alışkanlıkları edinin.';

  @override
  String get getStarted => 'Hemen Başla';

  @override
  String get next => 'İleri';

  @override
  String get skip => 'Atla';

  @override
  String get workloadBalanced => 'İş Yükü Dengeli';

  @override
  String get student => 'Öğrenci';

  @override
  String get hoursAbbreviation => 'sa';

  @override
  String get minutesAbbreviation => 'dk';

  @override
  String get avatarUpdated => 'Profil resmi başarıyla güncellendi';

  @override
  String get avatarUploadFailed => 'Profil resmi yüklenemedi';

  @override
  String get mediumRisk => 'Orta Risk';

  @override
  String get highRisk => 'Yüksek Risk';

  @override
  String get riskLevelCritical => 'Kritik';

  @override
  String get riskLevelWarning => 'Uyarı';

  @override
  String get riskLevelSafe => 'Güvenli';

  @override
  String get riskScore => 'Risk Skoru';

  @override
  String get remaining => 'kaldı';

  @override
  String get studyLogged => 'Çalışma kaydedildi';

  @override
  String get allTasksCompleted => 'Tüm görevler tamamlandı!';

  @override
  String get dontForgetTasks => 'Onları bitirmeyi unutmayın';

  @override
  String get academicProfileOnboarding => 'Akademik Profil';

  @override
  String get academicAnalyticsContext =>
      'Bu bilgiler, akademik analizlerinizi ve önerileri kişiselleştirmeye yardımcı olur.';

  @override
  String get basicIdentity => 'Temel Kimlik';

  @override
  String get universitySetup => 'Üniversite';

  @override
  String get universitySetupDesc => 'Nerede okuduğunuzu söyleyin.';

  @override
  String get academicProgram => 'Akademik Program';

  @override
  String get currentSemesterLoad => 'Mevcut Dönem';

  @override
  String get learningPatternCalibration => 'Öğrenme Modelleri';

  @override
  String get universityName => 'Üniversite Adı';

  @override
  String get degreeType => 'Derece Türü';

  @override
  String get major => 'Bölüm';

  @override
  String get majorPlaceholder => 'ör. Bilgisayar Mühendisliği';

  @override
  String get minor => 'Yandal';

  @override
  String get academicYear => 'Akademik Yıl';

  @override
  String get academicYearHint =>
      'Mevcut öğrenim yılınız (1 = birinci sınıf, 2 = ikinci sınıf, vb.).';

  @override
  String get expectedGraduationYear => 'Beklenen Mezuniyet Yılı';

  @override
  String get currentSemesterNumber => 'Mevcut Dönem';

  @override
  String get currentSemesterHint => 'Mevcut dönem numaranızı girin.';

  @override
  String get semesterTrackingSetup => 'Dönem Takibi Ayarları';

  @override
  String get optionalPreferencesTitle => 'İsteğe Bağlı Tercihler';

  @override
  String get optionalPreferencesDesc =>
      'Bunları istediğiniz zaman Çalışma Tercihleri ekranından değiştirebilirsiniz.';

  @override
  String get graduationYearHint =>
      'Beklenen mezuniyet yılınızı seçin (bu yıl veya sonrası).';

  @override
  String get graduationYearInvalid =>
      'Mezuniyet yılı bu yıl veya daha sonrası olmalıdır.';

  @override
  String get graduationYearSemesterMismatch => '';

  @override
  String get semesterNumberInvalid => 'Dönem numarası en az 1 olmalıdır.';

  @override
  String get weeklyStudyGoalInvalid =>
      'Haftalık çalışma hedefi 5 ile 40 saat arasında olmalıdır.';

  @override
  String get onboardingRiskImpactHint =>
      'Döneminiz ve çalışma hedefiniz, akademik risk ve ilerleme içgörülerini hesaplamak için kullanılır.';

  @override
  String get studyGoalRecommendation => 'Önerilen: haftada 10-25 saat';

  @override
  String get coursesThisSemester => 'Beklenen Dersler';

  @override
  String get studyHoursPerWeek => 'Haftalık Çalışma Hedefi (Saat)';

  @override
  String get preferredStudyTime => 'Tercih Edilen Çalışma Zamanı';

  @override
  String get breakPattern => 'Mola Modeli';

  @override
  String get morning => 'Sabah';

  @override
  String get afternoon => 'Öğleden Sonra';

  @override
  String get night => 'Gece';

  @override
  String get deepWork => 'Derin Çalışma';

  @override
  String get mixed => 'Karışık';

  @override
  String get bachelor => 'Lisans';

  @override
  String get master => 'Yüksek Lisans';

  @override
  String get phd => 'Doktora';

  @override
  String get addSemester => 'Dönem Ekle';

  @override
  String get editSemester => 'Dönemi Düzenle';

  @override
  String get semesterName => 'Dönem Adı';

  @override
  String get semesterNameHint => 'ör. Güz 2024';

  @override
  String get startDate => 'Başlangıç Tarihi';

  @override
  String get endDate => 'Bitiş Tarihi';

  @override
  String get createSemester => 'Dönem Oluştur';

  @override
  String get updateSemester => 'Dönemi Güncelle';

  @override
  String get courseManagement => 'Ders Yönetimi';

  @override
  String get myCourses => 'Derslerim';

  @override
  String get manageSemesters => 'Dönemleri Yönet';

  @override
  String get allSemesters => 'Tüm Dönemler';

  @override
  String get addCourse => 'Ders Ekle';

  @override
  String get editCourse => 'Dersi Düzenle';

  @override
  String get courseTitle => 'Ders Başlığı';

  @override
  String get courseCode => 'Ders Kodu';

  @override
  String get courseNameHint => 'örn. İleri Matematik';

  @override
  String get courseCodeHint => 'örn. CS204';

  @override
  String get details => 'Detaylar';

  @override
  String get courseColor => 'Ders Rengi';

  @override
  String get academicSemester => 'Akademik Dönem';

  @override
  String get creditsLabel => 'Kredi';

  @override
  String get sortAlphabetical => 'Alfabetik';

  @override
  String get sortStudyTime => 'Çalışma Süresi';

  @override
  String get semester => 'Dönem';

  @override
  String get semesterSeason => 'Dönem Türü';

  @override
  String get fallSemester => 'Güz';

  @override
  String get springSemester => 'Bahar';

  @override
  String get academicYearLabel => 'Akademik Yıl';

  @override
  String get selectSemester => 'Dönem Seç';

  @override
  String get setAsActive => 'Aktif dönem olarak ayarla';

  @override
  String get currentSemesterLabel => 'Aktif';

  @override
  String get selectDate => 'Tarih Seç';

  @override
  String get noSemestersYet => 'Henüz dönem oluşturulmadı';

  @override
  String get createFirstSemester =>
      'Derslerinizi düzenlemek için ilk döneminizi oluşturun.';

  @override
  String get deleteSemesterTitle => 'Dönemi Sil';

  @override
  String get deleteSemesterWarning =>
      'Bu işlem dönemi ve ona bağlı tüm dersler, görevler, son tarihler ve çalışma oturumları dahil tüm verileri kalıcı olarak silecektir.';

  @override
  String get deleteSemesterWarningStrong => 'Bu işlem geri alınamaz.';

  @override
  String get noCoursesYet => 'Henüz ders eklenmedi';

  @override
  String get addFirstCourse =>
      'Takip etmeye başlamak için ilk dersinizi ekleyin.';

  @override
  String get addFirstCourseBtn => 'İlk Dersimi Ekle';

  @override
  String get deleteCourse => 'Dersi Sil?';

  @override
  String get deleteCourseWarning =>
      'Bu işlem aynı zamanda bu dersi tüm bağlantılı görev ve oturumlardan ayıracaktır.';

  @override
  String get addCourseFirst => 'Önce bir ders ekleyin';

  @override
  String get selectCourse => 'Ders Seçin';

  @override
  String get pleaseSelectCourse => 'Lütfen bir ders seçin';

  @override
  String get ectsRequired => 'AKTS zorunludur';

  @override
  String get errorLoadingCourses => 'Dersler yüklenirken hata oluştu';

  @override
  String get academicInformation => 'Akademik Bilgiler';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get manageExams => 'Sınavları Yönet';

  @override
  String get manageCourses => 'Dersleri Yönet';

  @override
  String get manageCoursesSubtitle =>
      'Mevcut derslerinizi ekleyin veya düzenleyin';

  @override
  String yearCount(int count) {
    return 'Yıl $count';
  }

  @override
  String get studyGoal => 'Haftalık Çalışma Hedefi';

  @override
  String studyGoalCompleted(String time) {
    return 'Tamamlanan: $time';
  }

  @override
  String studyGoalRemaining(String time) {
    return 'Kalan: $time';
  }

  @override
  String get sessionReflectionTitle => 'Bu oturum nasıldı?';

  @override
  String get focused => 'Odaklı';

  @override
  String get distracted => 'Dikkati Dağınık';

  @override
  String get veryProductive => 'Çok Verimli';

  @override
  String get sessionNotes => 'Oturum Notları';

  @override
  String get identityDesc => 'Kim olduğunuz ve nerede okuduğunuzla başlayalım.';

  @override
  String get programDesc => 'Bize çalışma alanınızdan bahsedin.';

  @override
  String get loadDesc => 'Beklenen iş yükünüzü kalibre etmemize yardımcı olun.';

  @override
  String get learningPatternDesc => 'En iyi ne zaman ve nasıl öğrenirsiniz?';

  @override
  String hoursCount(int count) {
    return '$count Saat';
  }

  @override
  String get recommendedFocus => 'Önerilen Odak';

  @override
  String get practice => 'Pratik';

  @override
  String get studyPreferences => 'Çalışma Tercihleri';

  @override
  String get appSettings => 'Uygulama Ayarları';

  @override
  String get accountSettings => 'Hesap Ayarları';

  @override
  String get dataExport => 'Veri Dışa Aktar';

  @override
  String get reminderSettings => 'Hatırlatıcı Ayarları';

  @override
  String get notificationsEnabled => 'Bildirimler Etkin';

  @override
  String get notificationsDisabled => 'Bildirimler Devre Dışı';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get changePassword => 'Şifreyi Değiştir';

  @override
  String get changePasswordTitle => 'Şifreyi Değiştir';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get passwordUpdatedSuccess => 'Şifre başarıyla güncellendi';

  @override
  String get termsOfService => 'Kullanım Koşulları';

  @override
  String get studyTimerDefaults => 'Çalışma Zamanlayıcısı Varsayılanları';

  @override
  String focusOnTitle(String title) {
    return '$title konusuna odaklan - yakında teslim edilecek!';
  }

  @override
  String get allCaughtUp =>
      'Her şey yolunda! Derin bir odaklanma seansı başlatmaya ne dersin?';

  @override
  String bestStudyTime(String time) {
    return 'En iyi $time vaktinde çalışıyorsun. İlk seansını o zaman yap!';
  }

  @override
  String get discoverPattern =>
      'Çalışma modelini keşfetmek için bir oturum başlat.';

  @override
  String get startNewSession => 'Yeni Oturum Başlat';

  @override
  String get sessionType => 'Oturum Tipi';

  @override
  String get galleryPermissionRequired => 'Galeri İzni Gerekli';

  @override
  String get galleryPermissionMessage =>
      'Profil resminizi değiştirmek için lütfen ayarlardan galeri erişimine izin verin.';

  @override
  String get chooseACourse => 'Bir kurs seçin';

  @override
  String get backToHome => 'Ana Sayfaya Dön';

  @override
  String get notEnoughData => 'Henüz yeterli veri yok';

  @override
  String get addCoursesPrompt =>
      'İlerlemeyi izlemeye başlamak için kurslarınızı ekleyin.';

  @override
  String get noUpcomingDeadlines => 'Yakında teslim tarihi yok';

  @override
  String get caughtUp => 'Her şey tamam!';

  @override
  String youStudiedFor(String time) {
    return '$time boyunca çalıştınız.';
  }

  @override
  String get efficiencyTip => 'Verimlilik İpucu';

  @override
  String get discoveryStudyPatterns =>
      'Daha fazla oturum kaydederek en iyi çalışma düzeninizi keşfedin.';

  @override
  String goalCompletionLabel(int percentage) {
    return 'Hedef Tamamlama: %$percentage';
  }

  @override
  String keepGoingLeft(String time) {
    return 'Devam et! $time kaldı.';
  }

  @override
  String get greatFocusSession => 'Great focus session!';

  @override
  String get focusLevel => 'Odak Seviyesi';

  @override
  String get deepFlow => 'Deep Flow';

  @override
  String get building => 'Building';

  @override
  String get studyHoursByCourse => 'Derse Göre Çalışma Saatleri';

  @override
  String get weeklyTaskCompletion => 'Bu hafta (son tarihe göre)';

  @override
  String get dailyInsight => 'Daily Insight';

  @override
  String get focusOnStudies => 'Focus on your studies today.';

  @override
  String get thisWeekLabel => 'Bu Hafta';

  @override
  String get noCourseSelected => 'No Course Selected';

  @override
  String lastUpdatedAt(String time) {
    return 'Son güncelleme: $time';
  }

  @override
  String get noPendingAlerts => 'Bekleyen uyarı yok.';

  @override
  String overdueTasksSummary(int count) {
    return '$count gecikmiş görev var.';
  }

  @override
  String deadlinesSoonSummary(int count) {
    return 'Önümüzdeki 3 gün içinde $count teslim tarihi var.';
  }

  @override
  String get allTasksUpToDate => 'Mevcut tüm görevler güncel.';

  @override
  String get ectsLabel => 'AKTS';

  @override
  String get sessionFocus => 'Session Focus';

  @override
  String get academicLoad => 'Akademik İş Yükü';

  @override
  String get studyDemand => 'Çalışma Talebi';

  @override
  String get workloadIntensity => 'İş Yükü Yoğunluğu';

  @override
  String get totalEctsLabel => 'Toplam AKTS';

  @override
  String get overloaded => 'Aşırı Yüklü';

  @override
  String get highLoad => 'Yüksek Yük';

  @override
  String get balanced => 'Dengeli';

  @override
  String get lowLoad => 'Düşük Yük';

  @override
  String get riskLow => 'Düşük Risk';

  @override
  String get riskMedium => 'Orta Risk';

  @override
  String get riskHigh => 'Yüksek Risk';

  @override
  String get riskBreakdownTitle => 'Risk Dağılımı';

  @override
  String get riskOverdueTasks => 'Gecikmiş görevler';

  @override
  String get riskUpcomingTasks => 'Yaklaşan görevler';

  @override
  String get riskStudyDeficit => 'Çalışma açığı';

  @override
  String get riskSessionStress => 'Oturum stresi';

  @override
  String get riskConsistencyImpact => 'Süreklilik etkisi';

  @override
  String riskStatusMessage(int count) {
    return '$count gecikmiş görev';
  }

  @override
  String get riskInterpretationOnTrack =>
      'Yolundasınız. Mevcut çalışma hızınızı koruyun.';

  @override
  String get riskInterpretationHigh =>
      'Kaçırılan teslim tarihleri ve yetersiz çalışma saatleri nedeniyle yüksek risk altındasınız.';

  @override
  String get riskInterpretationMedium =>
      'Riskiniz orta seviyede. Görevleri tamamlamaya ve çalışma süresini artırmaya odaklanın.';

  @override
  String get riskInterpretationLow =>
      'Güvenli bir aralıktasınız. Mevcut ilerlemenizi sürdürün.';

  @override
  String get riskInterpretationStudyDeficit => 'Çalışma süresini hemen artırın';

  @override
  String get studyDeficitTitle => 'Yüksek Çalışma Açığı';

  @override
  String get studyDeficitBody =>
      'Yolunuzda kalmak için çalışma süresini hemen artırın.';

  @override
  String get decisionHighSessionStressTitle => 'Yüksek Çalışma Stresi';

  @override
  String get decisionHighSessionStressBody =>
      'Tükenmişliği önlemek için oturum süresini 30-40 dakikaya indirin.';

  @override
  String get decisionLowConsistencyTitle => 'Çalışma Sürekliliğini Artırın';

  @override
  String get decisionLowConsistencyBody =>
      'İş yükünü artırmadan önce programınızı düzeltin.';

  @override
  String get burnoutExplanationNew =>
      'Burnout risk is driven by sustained high stress and severe study deficit.';

  @override
  String get startTrackingToSeeTrends => 'Start tracking to see trends';

  @override
  String get noGpaDataAvailable => 'GPA verisi bulunamadı';

  @override
  String get riskInterpretationFocusTasks => 'Görevleri tamamlamaya odaklanın';

  @override
  String riskHoursRemaining(Object hours) {
    return '$hours saat kaldı';
  }

  @override
  String get riskGoalReached => 'Hedefe ulaşıldı!';

  @override
  String get historicalConsistency => 'Geçmiş süreklilik';

  @override
  String historicalConsistencyScoreLine(Object score, Object trend) {
    return 'Geçmiş süreklilik: %$score ($trend)';
  }

  @override
  String get weeklyConsistency => 'Bu haftaki süreklilik';

  @override
  String get decisionHighStressOverrideTitle => 'İş yükünü azaltın';

  @override
  String get decisionHighStressOverrideBody =>
      'Tükenmişliği önlemek için daha kısa seanslara odaklanın.';

  @override
  String get riskExplanationLowStudyHighStress =>
      'Düşük çalışma aktivitesi ve yüksek stres nedeniyle Yüksek Risk';

  @override
  String get riskExplanationDeficitOnly =>
      'Ciddi çalışma eksiği nedeniyle Yüksek Risk';

  @override
  String get riskExplanationStressOnly =>
      'Kritik stres seviyeleri nedeniyle Yüksek Risk';

  @override
  String get riskExplanationGeneric =>
      'Birleşik akademik sinyaller nedeniyle Yüksek Risk';

  @override
  String riskReasonOverdue(int count) {
    return '$count adet gecikmiş göreviniz var';
  }

  @override
  String get riskReasonStudyLow => 'Haftalık hedefinizden daha az çalıştınız';

  @override
  String riskReasonUpcoming(int count) {
    return 'Yakında bitecek $count görev';
  }

  @override
  String riskTrendUp(int delta) {
    return 'Geçen haftaya göre $delta puan arttı';
  }

  @override
  String riskTrendDown(int delta) {
    return 'Geçen haftaya göre $delta puan iyileşti';
  }

  @override
  String get riskTrendStable => 'Stabil';

  @override
  String riskTrendWorseningDelta(int delta) {
    return 'Kötüleşiyor · +$delta';
  }

  @override
  String riskTrendImprovingDelta(int delta) {
    return 'İyileşiyor · −$delta';
  }

  @override
  String get riskTrendNew => 'Yeni';

  @override
  String get riskNoData => 'Aktif risk faktörü yok';

  @override
  String get overviewTitle => 'Genel Bakış';

  @override
  String lastUpdated(String time) {
    return 'Son güncelleme: $time';
  }

  @override
  String overviewOverdueTasksAction(int count) {
    return '$count görev ilgi bekliyor';
  }

  @override
  String overviewUpcomingTasks(int count) {
    return 'Yaklaşan $count teslim tarihi';
  }

  @override
  String get overviewNoUpcomingTasks => 'Yakında teslim tarihi yok';

  @override
  String overviewCompletedToday(int count) {
    return 'Bugün tamamlanan $count görev';
  }

  @override
  String get overviewNoCompletedToday => 'Bugün tamamlanan görev yok';

  @override
  String get taskCompletion => 'Görev Tamamlama';

  @override
  String tasksCompleted(int completed, int total) {
    return '$total görevden $completed tanesi tamamlandı';
  }

  @override
  String tasksCompletedThisWeek(int completed, int total) {
    return 'Bu hafta (son tarihe göre): $completed/$total tamamlandı';
  }

  @override
  String get noStudyDataThisWeek => 'Bu hafta çalışma oturumu yok';

  @override
  String get noTasksThisWeek => 'Bu haftaya planlanmış görev yok';

  @override
  String get examResults => 'Ders Sonuçları';

  @override
  String get addResult => 'Sonuç Ekle';

  @override
  String get editResult => 'Sonucu Düzenle';

  @override
  String get deleteResultTitle => 'Sonucu Sil';

  @override
  String get deleteResultWarning =>
      'Bu işlem geri alınamaz. Bu derse ait tüm not bileşenleri kalıcı olarak silinecektir.';

  @override
  String get deleteResultWarningStrong =>
      'Ders sonucu ve not verileri kalıcı olarak silinecektir.';

  @override
  String get noResultsYet => 'Henüz sonuç eklenmedi';

  @override
  String get addFirstResultPrompt =>
      'Bu dönem için ilk ders sonucunuzu ekleyin.';

  @override
  String get gradingComponents => 'Not Bileşenleri';

  @override
  String get addComponent => '+ Bileşen Ekle';

  @override
  String get finalSection => 'Final';

  @override
  String get finalAverage => 'Dönem Sonu Ortalaması';

  @override
  String get letterGrade => 'Harf Notu';

  @override
  String get resultStatus => 'Ders Durumu';

  @override
  String get resultSuccessful => 'Başarılı';

  @override
  String get resultFailed => 'Başarısız';

  @override
  String get component => 'Bileşen';

  @override
  String get componentTitle => 'Başlık';

  @override
  String get componentTitleHint => 'örn. Vize, Proje, Final, Kısa Sınav';

  @override
  String get scoreHint => 'örn. 85';

  @override
  String get percentage => 'Yüzde';

  @override
  String get percentageHint => 'örn. 40';

  @override
  String get finalAverageHint => 'örn. 78.5';

  @override
  String get numberRequired => 'Geçerli bir sayı girin';

  @override
  String get completeComponentsError =>
      'Kaydetmeden önce tüm bileşenleri tamamlayın';

  @override
  String get percentageNot100Warning => 'Uyarı: toplam yüzde 100 değil';

  @override
  String get gradeDistribution => 'Not Dağılımı';

  @override
  String get noGradeDistributionYet => 'Henüz not dağılımı verisi yok';

  @override
  String get pleaseSelectLetterGrade => 'Lütfen bir harf notu seçin';

  @override
  String get noCoursesForSemester => 'Bu dönem için ders bulunamadı';

  @override
  String get semesterAlreadyExists => 'Bu dönem zaten mevcut';

  @override
  String get semesterStartBeforeEndError =>
      'Başlangıç tarihi bitiş tarihinden önce olmalıdır';

  @override
  String get gradeRangeError => 'Değer 0 ile 100 arasında olmalıdır';

  @override
  String get trendAnalysis => 'Trend Analizi';

  @override
  String get studyTrend => 'Çalışma Trendi';

  @override
  String get taskCompletionTrend => 'Görev Tamamlama Trendi';

  @override
  String get workloadTrend => 'İş Yükü Trendi';

  @override
  String get performanceTrend => 'Performans Trendi';

  @override
  String daysFilter(int count) {
    return '$count gün';
  }

  @override
  String trendTodayDuration(String duration) {
    return 'bugün $duration';
  }

  @override
  String trendCompletedToday(int count) {
    return 'bugün $count tamamlandı';
  }

  @override
  String trendNewToday(int count) {
    return 'bugün $count yeni';
  }

  @override
  String get trendStudySubtitle => 'Seçili dönemde günlük çalışılan saat';

  @override
  String get trendTaskSubtitle => 'Seçili dönemde günlük tamamlanan görev';

  @override
  String get trendWorkloadSubtitle =>
      'Günlük eklenen görev ve son teslim tarihleri';

  @override
  String get trendPerformanceSubtitle =>
      'Ders sonuçlarına göre not ortalaması değişimi';

  @override
  String get trendTasksOneDayHint =>
      'Görevlerin çoğu tek bir günde tamamlandı.';

  @override
  String get trendWorkloadEmptyMessage =>
      'Henüz veri yok.\nİş yükü trendini görmek için görev veya son tarih ekleyin.';

  @override
  String get trendStudyEmptyMessage =>
      'Henüz veri yok.\nTrendleri görmek için çalışma oturumu ekleyin.';

  @override
  String get trendTaskEmptyMessage =>
      'Bu dönemde tamamlanan görev yok.\nİlerlemeyi görmek için görevleri tamamlayın.';

  @override
  String get trendPerformanceEmptyMessage =>
      'Performansı takip etmek için ders sonucu ekleyin.';

  @override
  String get trendPerformanceNeedThreeResults =>
      'Performans trendini görmek için en az 3 ders sonucu ekleyin.';

  @override
  String get trendSummaryTitle => 'Trend Özeti';

  @override
  String get trendOverallStatusTitle => 'Genel Durum';

  @override
  String get trendNotEnoughData => 'Yetersiz veri';

  @override
  String get trendStable => 'Stabil';

  @override
  String get trendImproving => 'İyileşiyor';

  @override
  String get trendDeclining => 'Düşüyor';

  @override
  String get trendLessThan30Minutes => 'Bu dönemde 30 dakikadan az';

  @override
  String trendHoursInPeriod(String hours) {
    return 'Bu dönemde $hours sa';
  }

  @override
  String trendTasksCompletedFraction(int completed, int total) {
    return '$completed / $total tamamlandı';
  }

  @override
  String trendTasksDeadlinesAdded(int count) {
    return '$count görev/son tarih eklendi';
  }

  @override
  String get trendVeryLowActivity => 'Çok düşük aktivite';

  @override
  String get trendLowActivity => 'Düşük aktivite';

  @override
  String get trendNoTasks => 'Görev yok';

  @override
  String get trendNoTasksCompletedPeriod => 'Bu dönemde tamamlanan görev yok';

  @override
  String get trendZeroCompleted => '%0 tamamlandı';

  @override
  String trendPercentCompleted(int percent) {
    return '%$percent tamamlandı';
  }

  @override
  String get trendNoWorkload => 'İş yükü yok';

  @override
  String get trendIncreased => 'Arttı';

  @override
  String get trendReducedComparedLastPeriod => 'Önceki döneme göre azaldı';

  @override
  String get trendStatusOnTrack => 'Yolunda';

  @override
  String get trendStatusLowAndBehind => 'Aktivite düşük ve geride kalıyorsun';

  @override
  String get trendStatusStudyNeedsImprovement =>
      'Çalışma düzeni geliştirilmeli';

  @override
  String get trendStatusTaskIncomplete => 'Görev ilerlemesi yetersiz';

  @override
  String get trendStatusStableProgress => 'İlerleme stabil';

  @override
  String get trendStatusOnTrackDetail =>
      'Son dönemdeki aktiviten dengeli görünüyor. Bu tempoyu koru.';

  @override
  String get trendStatusNeedsFocusDetail =>
      'Aktiviten düşük ve görev ilerlemen yetersiz. Görevleri tamamlamaya ve çalışma süreni artırmaya odaklan.';

  @override
  String get trendStatusLowActivityHighCompletion =>
      'Etkinliğiniz düşük ancak görev tamamlama oranınız güçlü.';

  @override
  String get trendStatusNeedsAttention => 'Needs attention';

  @override
  String get trendStatusNeedsImprovement => 'Needs improvement';

  @override
  String get trendStatusCriticalRiskDetail =>
      'Risk factors identified. Review your study habits.';

  @override
  String get trendInsightBuildConsistencyTitle => 'Çalışma düzeni oluştur';

  @override
  String get trendInsightStudyIncreasedSignificantlyTitle =>
      'Çalışma süresi belirgin arttı';

  @override
  String get trendInsightStudyImprovedTitle => 'Çalışma süresi iyileşti';

  @override
  String get trendInsightStudyDeclinedTitle => 'Çalışma süresi düştü';

  @override
  String get trendInsightNoTasksTitle => 'Bu dönemde görev yok';

  @override
  String get trendInsightTaskLowTitle => 'Görev tamamlama düşük';

  @override
  String get trendInsightNoWorkloadTitle => 'Yeni iş yükü yok';

  @override
  String get trendInsightWorkloadSharpTitle => 'İş yükü keskin şekilde arttı';

  @override
  String get trendInsightWorkloadRisingTitle => 'İş yükü artıyor';

  @override
  String get trendInsightPerformanceDecliningTitle => 'Performans düşüyor';

  @override
  String get trendInsightPerformanceImprovingTitle => 'Performans iyileşiyor';

  @override
  String get trendInsightPerformanceStableTitle => 'Performans stabil';

  @override
  String get trendInsightStableTitle => 'Trendler stabil';

  @override
  String get trendInsightBuildConsistencyMessage =>
      'Günlük çalışma alışkanlığı oluşturmaya başla.';

  @override
  String trendInsightStudyIncreasedMessage(int percent) {
    return 'Çalışma süresi %$percent arttı. Bu tempoyu koru.';
  }

  @override
  String trendInsightStudyDroppedMessage(int percent) {
    return 'Çalışma süresi %$percent düştü. Ek çalışma oturumları planlamayı düşün.';
  }

  @override
  String get trendInsightNoTasksMessage =>
      'Bu dönemde teslim tarihi olan görev yoktu.';

  @override
  String get trendInsightNoTasksCompletedMessage =>
      'Henüz tamamlanan görev yok. Performansı takip etmek için görevleri tamamlamaya başla.';

  @override
  String trendInsightTaskCompletedFractionMessage(int completed, int total) {
    return '$total görevin $completed tanesini tamamladın. Sonraki dönemde daha fazlasını tamamlamayı hedefle.';
  }

  @override
  String get trendInsightNoWorkloadMessage =>
      'Bu dönemde yeni görev veya son tarih eklenmedi.';

  @override
  String trendInsightWorkloadAddedMessage(int count) {
    return 'Bu dönemde $count görev/son tarih ekledin. Aşırı yüklenmemek için planlama yap.';
  }

  @override
  String get trendInsightPerformanceDecliningMessage =>
      'Performans trendi düşüyor. Bu hafta zayıf derslerini gözden geçir.';

  @override
  String get trendInsightPerformanceImprovingMessage =>
      'Performans trendi iyileşiyor. Aynı çalışma düzenini sürdür.';

  @override
  String get trendInsightPerformanceStableMessage =>
      'Performans trendi stabil. Düzenli çalışmaya devam et.';

  @override
  String get trendInsightStableMessage =>
      'Henüz önemli bir değişiklik yok. Düzenli günlük tutmaya devam edin.';

  @override
  String get trendInsightLimitedDataTitle => 'Dönem için sınırlı veri';

  @override
  String get trendInsightLimitedDataMessage =>
      'Bu zaman aralığında güvenilir trendleri hesaplamak için yeterli oturum izlenmedi.';

  @override
  String get trendWorsening => 'Kötüleşiyor';

  @override
  String get trendUnstable => 'Kararsız';

  @override
  String get trendModerate => 'Orta';

  @override
  String get recoveryMessage => 'İyileşiyorsunuz. Bu düzeni koruyun.';

  @override
  String get burnoutTrendNoHistory =>
      'Henüz trendi tespit etmek için yeterli veri yok.';

  @override
  String get burnoutTrendNoRecovery =>
      'Henüz bir iyileşme trendi tespit edilmedi.';

  @override
  String get dashboardRiskLevelTitle => 'Risk Seviyesi';

  @override
  String dashboardRiskLevelValue(String level) {
    return 'Risk Seviyesi: $level';
  }

  @override
  String get dashboardTodaySnapshotTitle => 'Bugün Özeti';

  @override
  String dashboardStudyToday(String time) {
    return 'Çalışma: bugün $time';
  }

  @override
  String dashboardTasksCompletedToday(int count) {
    return 'Görevler: $count tamamlandı';
  }

  @override
  String dashboardWorkloadAddedToday(int count) {
    return 'İş yükü: $count eklendi';
  }

  @override
  String get dashboardKeyInsightTitle => 'Temel İçgörü';

  @override
  String get dashboardNoInsightAvailable => 'Henüz temel bir içgörü yok.';

  @override
  String get dashboardQuickActionsTitle => 'Hızlı Eylemler';

  @override
  String get dashboardProgressOverviewTitle => 'İlerleme Özeti';

  @override
  String get dashboardViewDetailedAnalysis => 'Detaylı analizi görüntüle ->';

  @override
  String get analyticsSparseDataTitle => 'Analizleriniz oluşuyor';

  @override
  String get analyticsSparseDataBody =>
      'Çalışma oturumu kaydedin, görev ekleyin ve notlarınızı girin. Uygulamayı kullandıkça grafikler dolacak.';

  @override
  String get analyticsInsightNoStudyDataHint =>
      'Henüz çalışma verisi yok. İçgörülerin açılması için takibe başlayın.';

  @override
  String get startTrackingYourSemester => 'Döneminizi takip etmeye başlayın';

  @override
  String get whatYouCanTrack => 'Neleri takip edebilirsiniz';

  @override
  String get trackTasks => 'Görevler';

  @override
  String get trackStudySessions => 'Çalışma oturumları';

  @override
  String get trackGrades => 'Notlar';

  @override
  String get whyItMatters => 'Neden önemli';

  @override
  String get monitorProgress => 'İlerlemenizi takip edin';

  @override
  String get reduceAcademicRisk => 'Akademik riski azaltın';

  @override
  String get custom => 'Özel';

  @override
  String customDurationLabel(int minutes) {
    return 'Özel: ${minutes}dk';
  }

  @override
  String get enterMinutes => 'Dakika girin';

  @override
  String get quickPresets => 'Hızlı Seçenekler';

  @override
  String get setDuration => 'Süreyi Ayarla';

  @override
  String get focusedTime => 'Odaklanılan süre';

  @override
  String get startAnotherSession => 'Yeni oturum başlat';

  @override
  String get sessionInsightShort =>
      'Kısa oturum. Bir sonraki sefere daha uzun odaklanmayı dene.';

  @override
  String get sessionInsightMedium => 'İyi oturum. Devamlılığı koru.';

  @override
  String get sessionInsightLong => 'Güçlü odaklanma oturumu.';

  @override
  String addedToWeeklyGoal(int minutes) {
    return '+${minutes}dk haftalık hedefe eklendi';
  }

  @override
  String get minimumSessionMessage => 'Minimum oturum süresi 10 dakikadır';

  @override
  String get durationRangeHint => 'Süre girin (10–240 dakika)';

  @override
  String get selectCourseToStart => 'Başlamak için bir ders seçin';

  @override
  String todayProgress(String completed, String goal) {
    return 'Bugün: $completed / $goal';
  }

  @override
  String weeklyProgress(String completed, String goal) {
    return 'Bu hafta: $completed / $goal';
  }

  @override
  String streakDays(int count) {
    return '$count gün';
  }

  @override
  String get noStreak => 'Bugün bir seri başlat';

  @override
  String get insightTooShort => 'Çok kısa. En az 20 dakika hedefle.';

  @override
  String get insightDecent =>
      'İyi başlangıç. Bir sonraki oturumunu uzatmayı dene.';

  @override
  String get insightStrong => 'Güçlü odaklanma. Bu devamlılığı koru.';

  @override
  String get lowFocus => 'Düşük Odak';

  @override
  String get mediumFocus => 'Orta Odak';

  @override
  String get highFocus => 'Yüksek Odak';

  @override
  String get goodFocus => 'İyi odak';

  @override
  String todayFocusedContext(int minutes, int sessions) {
    return 'bu gece ${minutes}dk odaklanıldı • $sessions oturum';
  }

  @override
  String get studyIntent => 'Çalışma Niyeti';

  @override
  String get studyIntentHint => 'Bu oturumdaki ana odağınız nedir?';

  @override
  String get studyIntentPlaceholder =>
      'örn. 4. Bölümü oku, Kalkülüs sorularını çöz...';

  @override
  String endsAt(String time) {
    return '$time vaktinde biter';
  }

  @override
  String endsAround(String time) {
    return '$time civarında biter';
  }

  @override
  String get structuredSession => 'Yapılandırılmış oturum';

  @override
  String get remainingTime => 'Kalan süre';

  @override
  String sessionProgress(int current, int total) {
    return 'Oturum $current / $total';
  }

  @override
  String get stayFocusedMsg => 'Odaklanmaya devam et. Harika gidiyorsun.';

  @override
  String get halfwayMsg => 'Yolun yarısındasın!';

  @override
  String get almostDoneMsg => 'Bitmek üzere, devam et!';

  @override
  String youStayedFocused(int minutes) {
    return '$minutes dakika boyunca odaklandın';
  }

  @override
  String get recommended => 'Önerilen';

  @override
  String get weeklyGoalProgress => 'Haftalık Hedef İlerlemesi';

  @override
  String weeklyGoalTag(int goal) {
    return 'Hedef: ${goal}dk';
  }

  @override
  String minutesDone(int minutes) {
    return '${minutes}dk tamamlandı';
  }

  @override
  String get sessionTooShort => 'Oturum Çok Kısa';

  @override
  String get sessionTooShortDescription =>
      'Etkili bir odaklanma için minimum oturum süresi 10 dakikadır. Bu oturum kaydedilmedi.';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get weeklyStudyGoal => 'Haftalık Çalışma Hedefi';

  @override
  String get behindThisWeek => 'Bu hafta geridesin — bugün harekete geç';

  @override
  String get justGettingStarted => 'Henüz yeni başlıyoruz';

  @override
  String remainingHours(int hours) {
    return '${hours}sa kaldı';
  }

  @override
  String catchUpMessage(int hours) {
    return '${hours}sa kaldı • Yetişmen gerekiyor';
  }

  @override
  String get focusScore => 'Odak Puanı';

  @override
  String get moderateFocus => 'Orta Düzey Odak';

  @override
  String get patternConsistent => 'Çalışma düzeni: Tutarlı';

  @override
  String get patternIrregular => 'Çalışma düzeni: Değişken';

  @override
  String get confidenceHigh => 'Tahmin doğruluğu: Yüksek';

  @override
  String get confidenceMedium => 'Tahmin doğruluğu: Orta';

  @override
  String get confidenceLow => 'Tahmin doğruluğu: Düşük';

  @override
  String basedOnSessions(int count) {
    return '($count oturuma göre)';
  }

  @override
  String get gettingStarted => 'Yeni başlıyor';

  @override
  String get noDataYet => 'Henüz veri yok';

  @override
  String get noDataForSemesterYet => 'Bu dönem için henüz veri yok';

  @override
  String get statusStable => 'Stabil';

  @override
  String get statusImproving => 'Gelişiyor';

  @override
  String get statusDeclining => 'Düşüşte';

  @override
  String get statusModerate => 'Orta';

  @override
  String trySessionNow(int duration) {
    return '$duration dakikalık bir çalışma dene';
  }

  @override
  String get startNow => 'Şimdi başla';

  @override
  String get sessionTooShortTitle => 'Oturum Çok Kısa';

  @override
  String get sessionTooShortMessage =>
      'Minimum oturum süresi 10 dakikadır. Bu oturum kaydedilmedi.';

  @override
  String get focusRemaining => 'Kalan süre';

  @override
  String get shortSessionInsight =>
      'Kısa oturum. Bir dahaki sefere daha uzun odaklanmaya çalış.';

  @override
  String get goodSessionInsight => 'İyi oturum. Devamlılığı koru.';

  @override
  String get strongSessionInsight => 'Güçlü odak oturumu.';

  @override
  String get sessionEndedEarly =>
      'Oturum erken sonlandırıldı — en az 15 dakika kalmayı dene';

  @override
  String get niceProgressToday => 'Bugün harika ilerleme kaydettin';

  @override
  String get studyConsistent => 'Bu hafta istikrarı korumaya devam et';

  @override
  String get next15m =>
      'Odağı yeniden kazanmak için 15 dakikalık bir oturumla başla';

  @override
  String get next25m => '25 dakikalı bir odaklanma seansıyla devam et';

  @override
  String get next45m =>
      'Derin odaklanma modundasın. 45 dakikalık bir seans dene';

  @override
  String sessionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oturum',
      one: '1 oturum',
      zero: 'Oturum yok',
    );
    return '$_temp0';
  }

  @override
  String minutesFocused(Object minutes) {
    return '${minutes}dk odaklanıldı';
  }

  @override
  String get patternLabel => 'Çalışma düzeni';

  @override
  String get statusVariable => 'Değişken';

  @override
  String get burnoutTrendForming =>
      'Trend oluşuyor. Desen tutarsızlığı nedeniyle risk artıyor.';

  @override
  String get burnoutRiskIncreasing =>
      'Düşük tutarlılık ve hedef açığı nedeniyle risk artıyor.';

  @override
  String burnoutReasonBehindGoal(String hours) {
    return 'Haftalık hedefinin ${hours}sa gerisindesin.';
  }

  @override
  String get burnoutReasonInconsistent =>
      'Çalışma düzeniniz bu hafta tutarsız.';

  @override
  String get burnoutReasonFrequentSwitching =>
      'Çalışma saatlerini sık sık değiştiriyorsunuz.';

  @override
  String get burnoutReasonLoadAboveGoal =>
      'Toplam çalışma yükün haftalık hedefinin üzerinde.';

  @override
  String get burnoutReasonNoSignals =>
      'Henüz önemli bir tükenmişlik sinyali saptanmadı.';

  @override
  String get burnoutReasonDeficit =>
      'You are falling behind your weekly study goal.';

  @override
  String get burnoutReasonStress =>
      'High stress detected during study sessions.';

  @override
  String get burnoutReasonConsistency =>
      'Low study consistency over the last 7 days.';

  @override
  String get burnoutReasonMood => 'A declining mood trend has been detected.';

  @override
  String get burnoutRecStable1 => 'Mevcut rutininizi sabit tutun.';

  @override
  String get burnoutRecStable2 =>
      'Haftalık hedefinizi takip etmeye devam edin.';

  @override
  String get burnoutRecWarning1 => 'Oturum süresini biraz azaltın.';

  @override
  String get burnoutRecWarning2 =>
      'Çalışma saatinizi tutarlı bir aralıkta tutun.';

  @override
  String get burnoutRecHighRisk1 =>
      'Oturumları kısaltın ve daha sık mola verin.';

  @override
  String get burnoutRecHighRisk2 =>
      'Bu hafta tek bir çalışma zaman aralığına odaklanın.';

  @override
  String get burnoutRecHighRisk3 =>
      'Kendinizi tükenmiş hissediyorsanız bir dinlenme günü ayırın.';

  @override
  String get burnoutRecRisk1 => 'Oturum süresini hemen azaltın.';

  @override
  String get burnoutRecRisk2 =>
      'Mola sıklığını artırın ve hedefleri basitleştirin.';

  @override
  String get burnoutRecRisk3 =>
      'Daha fazla zorlamadan önce bir dinlenme günü ayırın.';

  @override
  String get overloadWarning =>
      'Kendini çok fazla zorluyorsun. Düzgün bir ara ver.';

  @override
  String focusTrendMessage(String trend) {
    return 'Haftalık odaklanma düzenin $trend.';
  }

  @override
  String get focusAnalysisBasis =>
      'Son seanslara, tutarlılığa ve istikrara dayalıdır.';

  @override
  String get longBreakLabel => 'Uzun Ara';

  @override
  String focusSessionCount(int current, int total) {
    return 'Odaklanma $current/$total';
  }

  @override
  String get improving => 'İyileşen';

  @override
  String get declining => 'Azalan';

  @override
  String get stable => 'Stabil';

  @override
  String get focusShort => 'Kısa Odak';

  @override
  String get focusGood => 'İyi Odak';

  @override
  String get focusDeep => 'Derin Odak';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusStoppedEarly => 'Erken bitirildi';

  @override
  String get tryLongerFocus =>
      'Bir dahaki sefere daha uzun süre odaklanmayı deneyin';

  @override
  String get solidSession => 'Sağlam seans, böyle devam et';

  @override
  String get excellentDeepWork => 'Mükemmel derin çalışma';

  @override
  String get focusScoreImpact => 'Odak Skoru Etkisi';

  @override
  String get completedYes => 'Evet';

  @override
  String get completedNo => 'Hayır';

  @override
  String get cycles => 'Döngüler';

  @override
  String get breaksSkipped => 'Atlanan molalar';

  @override
  String get weeklyActivity => 'Haftalık Aktivite';

  @override
  String get streakWarningMessage =>
      '🔥 Serini bozma. Devam etmek için bugün çalış!';

  @override
  String get preivousWeekLabel => 'Geçen hafta';

  @override
  String get newWeekStart => 'Yeni hafta başlangıcı';

  @override
  String get noStudyActivityYet => 'Henüz çalışma aktivitesi yok';

  @override
  String get studiedOnlyOneDay => 'Bu hafta sadece bir gün çalıştın';

  @override
  String get gettingStartedExtend =>
      'Başlangıç aşaması. Seansları uzatmaya çalış';

  @override
  String get buildingConsistency => 'İstikrar oluşuyor';

  @override
  String get strongConsistentPattern => 'Güçlü ve istikrarlı çalışma düzeni';

  @override
  String get noActivity => 'Aktivite yok';

  @override
  String get monday => 'Pazartesi';

  @override
  String get tuesday => 'Salı';

  @override
  String get wednesday => 'Çarşamba';

  @override
  String get thursday => 'Perşembe';

  @override
  String get friday => 'Cuma';

  @override
  String get saturday => 'Cumartesi';

  @override
  String get sunday => 'Pazar';

  @override
  String get weeklyProgressLabel => 'Haftalık İlerleme';

  @override
  String get newBadge => 'Yeni ⭐';

  @override
  String weeklyGoalProgressHours(String current, String goal) {
    return '$current / $goal';
  }

  @override
  String activeDaysCount(int count) {
    return '$count aktif gün';
  }

  @override
  String peakDayLabel(String day) {
    return 'Zirve: $day';
  }

  @override
  String get streakAtRisk => 'Seri Tehlikede!';

  @override
  String get studyHabit => 'Çalışma Alışkanlığı';

  @override
  String get startStreakToday => 'Serine bugün başla';

  @override
  String get streakDay1 => '1. gün tamamlandı. Yarın istikrarı koru';

  @override
  String get strongHabitForming => 'Güçlü alışkanlık oluşuyor';

  @override
  String get excellentDiscipline => 'Mükemmel disiplin';

  @override
  String get lightFocus => 'Hafif odak';

  @override
  String get insightCycle => 'Yüksek kaliteli odak düzeni. Bu döngüyü koru.';

  @override
  String get insightStart =>
      'Güçlü başlangıç. Daha derin odak için 30 dakikayı aşın.';

  @override
  String get insightMomentum => 'Derin çalışmaya doğru ivme kazanılıyor.';

  @override
  String focusPoints(String points) {
    return '$points puan';
  }

  @override
  String get pomodoroFocusStep => 'Odak • 25 dk';

  @override
  String get pomodoroBreakStep => 'Mola • 5 dk';

  @override
  String get pomodoroRepeatStep => 'Toplam 4 döngü';

  @override
  String pomodoroTotalFocusSummary(int minutes) {
    return 'Toplam odak: $minutes dk';
  }

  @override
  String get pomodoroCompleted => 'Pomodoro tamamlandı';

  @override
  String cyclesCompleted(int count) {
    return '$count döngü tamamlandı';
  }

  @override
  String focusTimeBreakdown(int minutes) {
    return 'Odak süresi: $minutes dk';
  }

  @override
  String breakTimeBreakdown(int minutes) {
    return 'Mola süresi: $minutes dk';
  }

  @override
  String get excellentConsistency => 'Mükemmel tutarlılık';

  @override
  String get totalFocusTime => 'Toplam odak süresi';

  @override
  String streakDaysInARow(int count) {
    return 'Üst üste $count gün';
  }

  @override
  String get pomodoroMetrics => 'Metrikler';

  @override
  String get pomodoroPerformance => 'Performans';

  @override
  String get pomodoroTimeline => 'Döngü Zaman Çizelgesi';

  @override
  String pomodoroSubtitle(int done, int total) {
    return 'Pomodoro • $done/$total döngü';
  }

  @override
  String focusCycleDone(int index, int minutes) {
    return 'Odak $index  •  $minutes dk';
  }

  @override
  String focusCycleInProgress(int index) {
    return 'Odak $index  •  devam ediyor';
  }

  @override
  String focusCycleNotReached(int index) {
    return 'Odak $index  •  ulaşılmadı';
  }

  @override
  String breakDone(int minutes) {
    return 'Mola  •  $minutes dk';
  }

  @override
  String get breakPending => 'Mola';

  @override
  String get focusTimeLabel => 'Odak Süresi';

  @override
  String get breakTimeLabel => 'Mola Süresi';

  @override
  String completionOfCycles(int percent) {
    return 'Planlanan döngülerin %$percent\'i';
  }

  @override
  String minutesFocusedLabel(int minutes) {
    return '$minutes dk odaklandı';
  }

  @override
  String pomodoroHistorySubtitle(int done, int total, String time) {
    return '$total döngüden $done\'i • $time';
  }

  @override
  String sessionHistorySubtitle(String type, int minutes, String time) {
    return '$type • ${minutes}dk • $time';
  }

  @override
  String get statusBadgeCompleted => '✔ Tamamlandı';

  @override
  String get statusBadgeStopped => '⏸ Erken durduruldu';

  @override
  String errorLoading(String error) {
    return 'Hata: $error';
  }

  @override
  String get pomodoroInsightConsistent =>
      'Pomodoro döngülerini tutarlı şekilde tamamlıyorsunuz';

  @override
  String get pomodoroInsightPartial =>
      'Sık sık döngü ortasında duruyorsunuz. Daha kısa oturumlar deneyin';

  @override
  String get pomodoroInsightNeedsWork =>
      'Pomodoro döngülerini nadiren tamamlıyorsunuz. Süreyi kısaltmayı düşünün';

  @override
  String get studyActivity => 'Çalışma Aktivitesi';

  @override
  String heatmapTooltip(String date, int minutes, int sessions, int score) {
    return '$date: ${minutes}dk • $sessions oturum • Skor: $score';
  }

  @override
  String get heatmapLegendLess => 'Az';

  @override
  String get heatmapLegendMore => 'Çok';

  @override
  String get heatmapDayDetails => 'Gün Detayları';

  @override
  String streakCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count günlük seri',
      one: '1 günlük seri',
    );
    return '$_temp0';
  }

  @override
  String get studyIntensitySubtitle =>
      'Zaman içindeki günlük çalışma yoğunluğunuz';

  @override
  String get buildStreak => 'SERİNİZİ OLUŞTURUN';

  @override
  String get buildStreakSubtitle =>
      'Çalışma aktivite geçmişiniz burada görünecek';

  @override
  String get goodConsistency => 'İyi süreklilik';

  @override
  String get activity => 'Aktivite';

  @override
  String get sessions => 'Oturumlar';

  @override
  String get min => 'dk';

  @override
  String heatmapActivityLegendTooltip(Object label) {
    return 'Aktivite: $label';
  }

  @override
  String minutesShort(Object count) {
    return '$count dk';
  }

  @override
  String get startSession => 'Start Session';

  @override
  String targetPrefix(String target) {
    return 'Hedef: $target';
  }

  @override
  String get recommendedForYouTitle => 'Sizin için önerildi';

  @override
  String get keepMyPreference => 'Tercihimi koru';

  @override
  String get followActualBehavior => 'Gerçek davranışı takip et';

  @override
  String bestStudyTimeBullet(String time) {
    return '• En iyi çalışma zamanı: $time';
  }

  @override
  String suggestedSessionBullet(int minutes, String pattern) {
    return '• Önerilen oturum: $minutes dk ($pattern)';
  }

  @override
  String dailyTargetNeededBullet(String hours) {
    return '• Yolda kalmak için günde ~$hours saat çalışman gerekiyor';
  }

  @override
  String burnoutInputsHumanized(String deficit, int inconsistency) {
    return '• Çalışma açığı: ${deficit}s\n• Tutarlılık: %$inconsistency';
  }

  @override
  String get patternIrregularThisWeek =>
      '• Düzen notu: Bu hafta çalışma zamanların düzensiz.';

  @override
  String adaptiveHintRecentStudyTime(String time) {
    return 'Son zamanlarda daha çok $time çalışıyor görünüyorsun.';
  }

  @override
  String weekSessionsBreakdown(int morning, int afternoon, int night) {
    return 'Bu hafta oturumlar: sabah $morning, öğleden sonra $afternoon, gece $night.';
  }

  @override
  String confidenceBreakdown(int behavior, int preference, String trendText) {
    return 'Güven: davranış %$behavior • tercih uyumu $preference% $trendText';
  }

  @override
  String trendDeltaVsLastWeek(String delta) {
    return '• trend geçen haftaya göre $delta';
  }

  @override
  String weeklyGoalBehindDetailed(String logged, String expected) {
    return 'Haftalık hedefinin gerisindesin (şu ana kadar ${logged}sa kaydedildi, beklenen ${expected}sa).';
  }

  @override
  String get warningActionStartSession =>
      'Yeniden yola girmek için şimdi 25-40 dakikalık bir oturum başlat.';

  @override
  String get weeklyGoalSlightlyBehind =>
      'Haftalık hedefinin biraz gerisindesin. Mevcut tempoyu koru.';

  @override
  String get burnoutStatusTitle => 'Tükenmişlik Durumu';

  @override
  String burnoutOverallTrend(String status) {
    return 'Genel: $status';
  }

  @override
  String burnoutTrendLine(String status, String direction) {
    return 'Trend: $status $direction';
  }

  @override
  String burnoutDeficitLine(String status, String direction) {
    return 'Açık: $status $direction';
  }

  @override
  String burnoutConsistencyLine(String status, String direction) {
    return 'Tutarlılık: $status $direction';
  }

  @override
  String get noRecoveryTrendDetectedYet =>
      'Henüz toparlanma trendi tespit edilmedi.';

  @override
  String get notEnoughDataTrendYet =>
      'Henüz trend tespiti için yeterli veri yok.';

  @override
  String get recoveryImprovingThisWeek =>
      'Çalışma düzenin bu hafta iyileşiyor.';

  @override
  String studyDeficitBasedOnWeeklyGoal(String hours) {
    return 'Çalışma açığı haftalık hedefine göre hesaplanır (${hours}sa).';
  }

  @override
  String get softInterventionsTitle => 'Nazik müdahaleler';

  @override
  String get burnoutLevelStable => 'Stabil';

  @override
  String get burnoutLevelWarning => 'Uyarı';

  @override
  String get burnoutLevelHighRisk => 'Yüksek Risk';

  @override
  String get burnoutLevelBurnoutRisk => 'Tükenmişlik Riski';

  @override
  String get burnoutExplanationStable =>
      'Çalışma düzenin şu anda dengeli görünüyor.';

  @override
  String get burnoutExplanationWarning =>
      'Çalışma düzenin tutarsızlaşıyor ve haftalık hedefinin gerisinde kalıyorsun.';

  @override
  String get burnoutExplanationHighRisk =>
      'Tutarsız çalışma ve açık belirtileri görünmeye başladı.';

  @override
  String get burnoutExplanationBurnoutRisk =>
      'Yükün yüksek ve düzenin dengesizleşiyor.';

  @override
  String get burnoutReasonInconsistentPattern =>
      'Bu hafta çalışma düzenin tutarsız.';

  @override
  String get burnoutReasonSwitchingTimes =>
      'Çalışma saatlerini sık sık değiştiriyorsun.';

  @override
  String get burnoutReasonNoMajorSignals =>
      'Henüz büyük bir tükenmişlik sinyali yok.';

  @override
  String get burnoutRecommendationStable1 => 'Mevcut düzenini koru.';

  @override
  String get burnoutRecommendationStable2 => 'Haftalık hedef takibini sürdür.';

  @override
  String get burnoutRecommendationWarning1 => 'Oturum süresini biraz kısalt.';

  @override
  String get burnoutRecommendationWarning2 =>
      'Çalışma saatini tek bir zaman diliminde sabitle.';

  @override
  String get burnoutRecommendationHigh1 =>
      'Oturumları kısalt ve daha sık mola ver.';

  @override
  String get burnoutRecommendationHigh2 =>
      'Bu hafta tek bir çalışma zaman penceresine odaklan.';

  @override
  String get burnoutRecommendationHigh3 =>
      'Kendini çok yorgun hissediyorsan bir toparlanma günü ekle.';

  @override
  String get burnoutRecommendationBurnout1 => 'Oturum süresini hemen azalt.';

  @override
  String get burnoutRecommendationBurnout2 =>
      'Molaları artır ve hedefleri sadeleştir.';

  @override
  String get burnoutRecommendationBurnout3 =>
      'Daha fazla yüklenmeden önce bir toparlanma günü ayır.';

  @override
  String get decisionNextActionTitle => 'Sonraki Adım';

  @override
  String get decisionStudyAnyCourse => 'Öncelikli dersin için çalış';

  @override
  String decisionStudyCourse(String course) {
    return '$course dersine çalış';
  }

  @override
  String decisionMinutesToday(int minutes) {
    return 'Bugün $minutes dakika';
  }

  @override
  String get decisionFocusRecommendationTitle => 'Odak Önerisi';

  @override
  String get decisionWhatChangedTitle => 'Neler Değişti';

  @override
  String get decisionTaskLoadLabel => 'Görev Yükü';

  @override
  String get decisionConfidenceLow => 'Güven: Düşük (son etkinliğe göre)';

  @override
  String get startedFromAnalyticsRecommendation =>
      'Analitik önerisinden başlatıldı';

  @override
  String get followedPlanToday => 'Harika. Bugün planını uyguladın.';

  @override
  String sessionImpactAddedToCourse(int minutes, String course) {
    return '+$minutes dk $course dersine eklendi';
  }

  @override
  String get sessionImpactCloserToGoal =>
      'Artık haftalık hedefine daha yakınsın';

  @override
  String get decisionReasonOverdueAttention =>
      'Süresi geçmiş görevler acil ilgi gerektiriyor';

  @override
  String get decisionReasonLeastStudied => 'Bu hafta en az bu derse çalıştın';

  @override
  String get decisionReasonNoUrgentDeadlines =>
      'Acil son tarih yok. Düzeni koru.';

  @override
  String get decisionReasonBehindWeeklyTarget =>
      'Haftalık hedefinin gerisindesin';

  @override
  String get decisionReasonHeavyWorkload => 'Bu derste açık görev yükü yüksek';

  @override
  String get decisionReasonHighestPriority =>
      'Şu anda en yüksek öncelikli dersin bu';

  @override
  String get decisionReasonBuildRoutine => 'Rutinini oluşturmaya başla';

  @override
  String get decisionReasonLowestStudyWeek =>
      'Bu hafta en düşük çalışma süresi';

  @override
  String get decisionReasonNoStudyLogged => 'Bu hafta çalışma kaydı yok';

  @override
  String get decisionReasonFallbackConsistency =>
      'Yedek öneri: Bu hafta istikrarını koru';

  @override
  String decisionReasonStudyProgress(String studied, String target) {
    return '${target}sa hedefinin ${studied}sa kadarını çalıştın';
  }

  @override
  String decisionReasonImportantCourse(int ects) {
    return 'Önemli ders ($ects AKTS)';
  }

  @override
  String decisionReasonHigherPriorityThan(String course) {
    return '$course dersinden daha acil';
  }

  @override
  String get decisionReasonHigherPriorityGeneral =>
      'Bu hafta diger derslerden daha acil';

  @override
  String get todayPlanTitle => 'Bugun Plani';

  @override
  String todayMinutesCompleted(int minutes) {
    return 'Bugun: $minutes dk tamamlandi';
  }

  @override
  String get recoveryPlanTitle => 'Toparlanma Plani';

  @override
  String get recoveryPlanSplitFromWeeklyDeficit =>
      'Haftalik acigina gore bolundu';

  @override
  String get planDay3Label => '3. Gun';

  @override
  String suggestedSplitSessionsToday(int count, int minutes) {
    return 'Oneri: Bugun $count × $minutes dk oturum';
  }

  @override
  String get suggestedFlexibleSessionsToday => 'Oneri: Bugun 2-3 odakli oturum';

  @override
  String get suggestedShorterSessionsToday =>
      'Öneri: Bugün 3-4 kısa çalışma seansı yapın';

  @override
  String get recoveryMessageStressHigh =>
      'Tükenmişliği önlemek için bugün daha kısa seanslara odaklanın';

  @override
  String needHoursTodayToStayOnTrack(String hours) {
    return 'Yolda kalmak icin bugun ${hours}sa ihtiyacin var';
  }

  @override
  String minutesRemainingShort(int minutes) {
    return '${minutes}dk kaldi';
  }

  @override
  String decisionReasonDeadlineLowStudy(int days) {
    return 'Son teslime $days gün var ve bu hafta normalden az çalıştın';
  }

  @override
  String decisionReasonDeadlineInDays(int days) {
    return 'Son teslime $days gün kaldı';
  }

  @override
  String decisionReasonLowestStudyWithDeadline(int days) {
    return 'Bu hafta en düşük çalışma süresi ve son teslime $days gün kaldı';
  }

  @override
  String decisionReasonLowestStudyWithOpenTasks(int count) {
    return 'Bu hafta en düşük çalışma süresi ve $count açık görev var';
  }

  @override
  String decisionReasonHighCourseWeight(int ects) {
    return 'Yüksek ders ağırlığı ($ects AKTS)';
  }

  @override
  String get reset => 'Sıfırla';

  @override
  String get status => 'Durum';

  @override
  String get logMoodTitle => 'Ruh Halini Kaydet';

  @override
  String get moodAfterSessionPrompt =>
      'Bu çalışma oturumundan sonra nasıl hissediyorsun?';

  @override
  String get moodManualPrompt =>
      'Çalışma içgörülerini geliştirmek için ruh hali ve stresini takip et.';

  @override
  String get moodLevel => 'Ruh Hali Seviyesi';

  @override
  String get stressLevel => 'Stres Seviyesi';

  @override
  String get energyLevel => 'Enerji Seviyesi';

  @override
  String get moodFactors => 'Faktörler';

  @override
  String get moodFactorSleep => 'Uyku';

  @override
  String get moodFactorWorkload => 'İş Yükü';

  @override
  String get moodFactorHealth => 'Sağlık';

  @override
  String get moodFactorMotivation => 'Motivasyon';

  @override
  String get moodFactorSocial => 'Sosyal';

  @override
  String get moodFactorExams => 'Sınavlar';

  @override
  String get saveMood => 'Ruh Halini Kaydet';

  @override
  String get moodSaved => 'Ruh hali kaydı oluşturuldu.';

  @override
  String get moodSaveFailed => 'Ruh hali kaydı oluşturulamadı.';

  @override
  String get moodAndStressTitle => 'Ruh Hali ve Stres';

  @override
  String get moodAverageLabel => 'Ortalama Ruh Hali';

  @override
  String get stressAverageLabel => 'Ortalama Stres';

  @override
  String get moodNoData => 'Veri yok';

  @override
  String get moodSettingsTitle => 'Ruh Hali ve Stres Ayarları';

  @override
  String get enableMoodTracking => 'Ruh Hali Takibini Etkinleştir';

  @override
  String get enableMoodReminders => 'Hatırlatıcıları Etkinleştir';

  @override
  String get reminderTimeLabel => 'Hatırlatıcı Saati';

  @override
  String get reminderTypeLabel => 'Hatırlatıcı Türü';

  @override
  String get reminderTypeDaily => 'Günlük';

  @override
  String get reminderTypeAfterStudy => 'Çalışma Sonrası';

  @override
  String get reminderTypeBoth => 'İkisi';

  @override
  String get moodHistoryTitle => 'Ruh Hali Geçmişi';

  @override
  String get moodDailyPromptTitle => 'Bugün nasıl hissediyorsun?';

  @override
  String get moodDailyPromptSubtitle =>
      'Çalışma kararlarını iyileştirmek için ruh halini ve stresini kaydet.';

  @override
  String get moodReminderTitle => 'Ruh hali kontrolü';

  @override
  String get moodReminderBody =>
      'Ruh halini ve stresini kaydetmek için bir dakikanı ayır.';

  @override
  String get moodLast7Days => 'Son 7 gündeki ruh hali';

  @override
  String moodOverLastDays(int count) {
    return 'Son $count gündeki ruh hali';
  }

  @override
  String get moodKeepLogging => 'Ruh halinizi kaydetmeye devam edin';

  @override
  String get moodTrendNeedsData =>
      'Kişisel duygusal eğilim grafiğinizi görmek için ruh halinizi kaydetmeye devam edin.';

  @override
  String get dailyMoodHistory => 'Günlük Ruh Hali Geçmişi';

  @override
  String get olderLabel => 'Daha Eski';

  @override
  String get decisionSmartInsights => 'AI içgörüsü';

  @override
  String get decisionHighStress => 'Yüksek stres tespit edildi';

  @override
  String get decisionShortSessions => 'Bugün daha kısa çalışma yap';

  @override
  String get decisionDeepWork => 'Derin çalışma için iyi durumdasın';

  @override
  String get decisionBurnoutWarning => 'Tükenmişlik riski artıyor';

  @override
  String get decisionStressRising => 'Bu hafta stresin artıyor';

  @override
  String get decisionMoodDeclining => 'Ruh halin düşüyor';

  @override
  String get decisionDeadlinePressure => 'Yüksek baskı. Görevleri böl';

  @override
  String get decisionLowActivityHighStress => 'Düşük aktivite ama yüksek stres';

  @override
  String get decisionLightTasksOnly => 'Bugün sadece hafif görevlere odaklan';

  @override
  String decisionMainFactor(String factor) {
    return 'Ana stres kaynağı: $factor';
  }

  @override
  String decisionWorstDay(String day) {
    return '$day günü daha düşük hissediyorsun';
  }

  @override
  String get decisionMorningPlanning => 'Sabah odağı: ana görevlerini planla';

  @override
  String get decisionAfternoonExecution =>
      'Öğleden sonra odağı: en önemli görevi uygula';

  @override
  String get decisionNightLightReview => 'Gece odağı: hafif tekrar yap';

  @override
  String get decisionActionShortSessions =>
      'Daha kısa oturumlar kullan (25 dk)';

  @override
  String get decisionActionBreakDown => 'Çalışmayı şimdi küçük görevlere böl';

  @override
  String get decisionActionMonitorWeekly => 'Bu paterni hafta boyunca takip et';

  @override
  String get decisionActionPlanning => 'Bugün için en önemli 3 görevi belirle';

  @override
  String get decisionActionExecution =>
      'Şimdi tek bir odaklı uygulama bloğu yap';

  @override
  String get decisionActionLightReview => 'Hafif tekrar yap, ağır yükten kaçın';

  @override
  String startRecommendedSession(int minutes) {
    return 'Önerilen Oturumu Başlat ($minutes dk)';
  }

  @override
  String get smartInsightUpdated => 'Akıllı İçgörü Güncellendi';

  @override
  String get moodSavedPositive1 => 'Kaydedildi. Harika tutarlılık.';

  @override
  String get moodSavedPositive2 => 'Kaydedildi. Devam et.';

  @override
  String get moodSavedPositive3 => 'Kaydedildi. Güzel ilerleme.';

  @override
  String get moodSavedPositive4 => 'Kaydedildi. İyi gidiyorsun.';

  @override
  String get todaysMoodTitle => 'Bugünkü Ruh Hali';

  @override
  String stressOutOfTen(int value) {
    return 'Stres $value/10';
  }

  @override
  String get takeItSlowerTodayTitle => 'Bugün biraz yavaşla';

  @override
  String get takeItSlowerTodayBody =>
      'Yüksek stres tespit edildi. Daha kısa oturumlar yap ve molaları koru.';

  @override
  String get strongStateTitle => 'Güçlü bir durumdasın';

  @override
  String get strongStateBody => 'Ruh halin yüksekken daha derin çalış.';

  @override
  String get view => 'Gör';

  @override
  String get focusRecommendationPrimary => 'Odak Önerisi (Birincil)';

  @override
  String get decisionConfidenceHigh => 'Güven: Yüksek (son etkinliğe göre)';

  @override
  String get decisionConfidenceMedium => 'Güven: Orta (son etkinliğe göre)';

  @override
  String get decisionBurnoutDurationCap =>
      'Yüksek stres algılandı. Oturumları 25dk ile sınırla.';

  @override
  String get decisionFixedSchedule => 'Sabit program oluştur';

  @override
  String get decisionActionFixedSchedule => '3 gün aynı çalışma saatini kullan';

  @override
  String get postSessionMoodImproved => 'Çalışma sonrası ruh halin iyileşti';

  @override
  String get postSessionStressIncreased =>
      'Uzun oturumlar stresini artırıyor olabilir';

  @override
  String get postSessionFeedbackLogged =>
      'Oturum sonrası geri bildirim kaydedildi';

  @override
  String consistencyScoreLine(int score, String trend) {
    return 'Tutarlılık: %$score ($trend)';
  }

  @override
  String get predictionStressTitle => 'Tahmini Stres (Sonraki 3 Gün)';

  @override
  String get predictionPlanTitle => 'Önerilen Plan';

  @override
  String get predictionLevelLow => 'DÜŞÜK';

  @override
  String get predictionLevelMedium => 'ORTA';

  @override
  String get predictionLevelHigh => 'Stres eğilimi: Artıyor';

  @override
  String predictionReasonHighStressToday(String stress) {
    return 'Stres: $stress/10';
  }

  @override
  String predictionReasonLowConsistency(String percent) {
    return 'Tutarlılık: %$percent';
  }

  @override
  String predictionReasonUpcomingWorkload(int count) {
    return 'Teslim tarihleri: $count';
  }

  @override
  String get predictionMainReasonTitle => 'Ana neden:';

  @override
  String get predictionWhyTitle => 'Bu plan neden önerildi?';

  @override
  String predictionReasonStressHigh(String stress) {
    return 'Stres: $stress/10';
  }

  @override
  String predictionReasonLowConsistencyDetail(String delta) {
    return 'Tutarlılık: %$delta';
  }

  @override
  String predictionReasonTasksPending(int count) {
    return 'Bekleyen görevler: $count';
  }

  @override
  String predictionReasonDeadlinesSoon(int count) {
    return 'Teslim tarihleri: $count';
  }

  @override
  String get predictionAffectedTitle => 'Etkilenen:';

  @override
  String predictionPlanLine(
    String day,
    String time,
    int minutes,
    String focus,
  ) {
    return '$day saat $time • $minutes dk $focus oturumu';
  }

  @override
  String predictionPlanLineSimple(String day, int minutes, String focus) {
    return '• $day: $minutes dk $focus';
  }

  @override
  String get predictionPlanLightFocus => 'hafif';

  @override
  String get predictionPlanFocusExecution => 'odak';

  @override
  String get predictionPlanDeepExecution => 'derin';

  @override
  String get predictionPlanLightReview => 'hafif tekrar';

  @override
  String predictionPerformanceRisk(String level) {
    return 'Performans Riski: $level';
  }

  @override
  String predictionPerformanceRiskLagging(String level, String courses) {
    return 'Performans Riski: $level • Geride olunan: $courses';
  }

  @override
  String get moodNameAwful => 'Berbat';

  @override
  String get moodNameBad => 'Kötü';

  @override
  String get moodNameNeutral => 'Nötr';

  @override
  String get moodNameGood => 'İyi';

  @override
  String get moodNameGreat => 'Harika';

  @override
  String imFeelingMood(String mood) {
    return 'Bugün $mood hissediyorum';
  }

  @override
  String saveMoodDots(String mood, String stress) {
    return 'Kaydet • $mood • Stres $stress';
  }

  @override
  String get addQuickNoteOptional => 'Kısa bir not ekle (isteğe bağlı)';

  @override
  String get analyticsMoodPerformanceTitle => '🧠 Ruh Hali vs Performans';

  @override
  String get analyticsMoodPerformanceGoodDesc =>
      'Yüksek modunuz odaklanma sürenizi olumlu etkiliyor.';

  @override
  String analyticsMoodLabel(String label, String value, String trend) {
    return '🙂 $label: $value $trend';
  }

  @override
  String analyticsStressLabel(String label, String value, String trend) {
    return '⚡ $label: $value $trend';
  }

  @override
  String analyticsImpactPositive(int minutes) {
    return '🚀 +${minutes}dk';
  }

  @override
  String analyticsImpactNegative(int minutes) {
    return '📉 -${minutes}dk';
  }

  @override
  String get analyticsMoodPerformanceBadDesc =>
      'Düşük modunuz oturum verimliliğinizi kısıtlıyor.';

  @override
  String get analyticsMoodPerformanceStableDesc =>
      'Modunuz dengeli, bu da tutarlı bir odaklanma sağlıyor.';

  @override
  String get analyticsMoodBetterMood => 'Daha İyi Ruh Hali';

  @override
  String get analyticsMoodHighStress => 'Yüksek Stres';

  @override
  String get analyticsMoodFocusBoost => 'Odaklanma Artışı';

  @override
  String get analyticsMoodFocusDrain => 'Odaklanma Kaybı';

  @override
  String analyticsMoodDifference(Object minutes, Object plusMinus) {
    return '$plusMinus${minutes}m';
  }

  @override
  String get burnoutMessageEmotionalRisk =>
      'Emotional volatility detected in recent sessions. Prioritize mental health.';

  @override
  String get decisionStatusModerateStress => 'Orta düzey stres tespit edildi';

  @override
  String get decisionStatusLowStress => 'Düşük stres';

  @override
  String get decisionStatusHighStress => 'Yüksek stres tespit edildi';

  @override
  String get predictionStressLikelyIncrease =>
      'Stress likely to increase due to low recovery and rising pressure';

  @override
  String get analyticsNotEnoughData => 'Not enough data yet';

  @override
  String get decisionRisingStressUnstablePattern =>
      'Your stress is rising while your routine is unstable';

  @override
  String get decisionActionFixedScheduleFocus =>
      'Study at the same time for 3 days to stabilize focus';

  @override
  String get burnoutRisingStressInconsistentPattern =>
      'Your stress is increasing while your study pattern is inconsistent';

  @override
  String predictionPressureLikelyToIncrease(String hours) {
    return 'Çalışma eksiği: $hours sa';
  }

  @override
  String get analyticsMoodCorrelationDetected => 'Correlation detected';

  @override
  String analyticsMoodStudyDropped(String percent) {
    return 'Study dropped by $percent%';
  }

  @override
  String analyticsMoodMoodDropped(String percent) {
    return 'Mood dropped by $percent%';
  }

  @override
  String get burnoutShortExplanation =>
      'Your study pattern looks balanced right now.';

  @override
  String get signalStressHigh => 'Yüksek stres';

  @override
  String get signalStressMedium => 'Orta stres';

  @override
  String get signalMoodLow => 'Düşük ruh hali';

  @override
  String get signalConsistencyLow => 'Tutarsız rutin';

  @override
  String get signalDeficitHigh => 'Çalışma eksiği';

  @override
  String get consistency => 'Süreklilik';

  @override
  String get stress => 'Stres';

  @override
  String get moodTrends => 'Ruh Hali Trendleri';

  @override
  String get studyProfileTitle => 'Çalışma Profilin';

  @override
  String studyProfileOptimalDuration(int min, int max) {
    return 'İdeal Oturum: $min-$max dk';
  }

  @override
  String studyProfileStressThreshold(String value) {
    return 'Stres > $value olduğunda odak düşüyor';
  }

  @override
  String studyProfilePeakWindow(String window) {
    return 'En Verimli Zaman: $window';
  }

  @override
  String get studyProfileMorning => 'Sabah';

  @override
  String get studyProfileAfternoon => 'Öğleden Sonra';

  @override
  String get studyProfileEvening => 'Akşam';

  @override
  String studyProfileMainFactor(String factor) {
    return 'Ana faktör: $factor';
  }

  @override
  String studyProfileSecondaryFactor(String factor) {
    return 'İkincil: $factor';
  }

  @override
  String get completion => 'Tamamlama';

  @override
  String get moodEnergyLevel => 'Enerji Seviyesi';

  @override
  String get moodLoggedSession => 'Çalışma oturumundan sonra kaydedildi';

  @override
  String get moodLoggedManual => 'Manuel olarak kaydedildi';

  @override
  String get markAllAsRead => 'Tümünü okundu olarak işaretle';

  @override
  String get mood => 'Ruh Hali';

  @override
  String get academic => 'Akademik';

  @override
  String get moodCheckNotificationTitle => 'Ruh hali kontrolü';

  @override
  String get moodCheckNotificationMessage =>
      'Bugün nasıl hissediyorsun? İçgörülerin doğru kalması için ruh halini kaydet.';

  @override
  String get dailyBaseline => 'Günlük Temel';

  @override
  String get studySessions => 'Çalışma Oturumları';

  @override
  String get notificationOverdue => 'gecikmiş';

  @override
  String get notificationDueToday => 'bugün teslim edilecek';

  @override
  String get notificationDueTomorrow => 'yarın teslim edilecek';

  @override
  String get notificationDueSoon => 'yakında teslim edilecek';

  @override
  String get weeklyStudyGoalMissed => 'Haftalık çalışma hedefi kaçırıldı';

  @override
  String weeklyStudyGoalMissedMessage(Object actual, Object goal) {
    return 'Bu hafta $goal saatlik hedefinizin $actual saatini çalıştınız.';
  }

  @override
  String get decisionRisingStressTitle => 'Rising Stress Levels';

  @override
  String get decisionStatusDeficit => 'Büyük çalışma eksiği';

  @override
  String get decisionStatusInconsistent => 'Tutarsızlık tespit edildi';

  @override
  String get baseline => 'Temel';

  @override
  String get predictionCollectingData => 'Veri Toplanıyor';

  @override
  String get predictionCollectingDataDetail =>
      '5 veya daha fazla oturum çalışıldığında tam yapay zeka içgörüleri aktif olacaktır.';

  @override
  String decisionRecommendedSession(int minutes) {
    return 'Önerilen: $minutes dk';
  }

  @override
  String get moodTerrible => 'Berbat';

  @override
  String get moodBad => 'Kötü';

  @override
  String get moodNeutral => 'Nötr';

  @override
  String get moodGood => 'İyi';

  @override
  String get moodAmazing => 'Harika';

  @override
  String get moodUnknown => 'Bilinmiyor';

  @override
  String get hideDetails => 'Detayları gizle';

  @override
  String get viewFullAnalysis => 'Tam analizi görüntüle';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get selectedSemester => 'Seçili Dönem';

  @override
  String minutesValue(int minutes) {
    return '$minutes dk';
  }

  @override
  String minutesCourseValue(int minutes, String course) {
    return '$minutes dk $course';
  }

  @override
  String get smartAiInsights => 'AI içgörüsü';

  @override
  String get burnoutExplanationFallingBehind =>
      'Haftalık hedefinizin gerisinde kalıyorsunuz.';

  @override
  String get burnoutBehaviorHighFatigue =>
      'Elevated mental fatigue levels detected.';

  @override
  String get burnoutBehaviorMoodInstability =>
      'Increasing mood variability impacting focus.';

  @override
  String get burnoutBehaviorIrregularRest =>
      'Inconsistent rest periods between sessions.';

  @override
  String get burnoutBehaviorUnpredictableRhythm =>
      'Unpredictable study rhythm and timing.';

  @override
  String get burnoutBehaviorSwitchingContext =>
      'Frequent context switching affecting deep focus.';

  @override
  String get burnoutBehaviorMentalOverload =>
      'Cognitive load exceeding typical recovery rates.';

  @override
  String consistencyPercentage(Object score) {
    return 'Süreklilik: %$score';
  }

  @override
  String labelWithColon(Object label) {
    return '$label:';
  }

  @override
  String labelWithColonAndSpace(Object label) {
    return '$label: ';
  }

  @override
  String get examsTitle => 'Sinavlar';

  @override
  String get examsLoadError => 'Sinavlar yuklenemedi';

  @override
  String get examsAddCta => 'Sinav Ekle';

  @override
  String get examsUpcomingSectionTitle => 'Yaklasan sinavlar';

  @override
  String get examsGroupToday => 'Bugün';

  @override
  String get examsGroupThisWeek => 'Bu Hafta';

  @override
  String get examsGroupThisMonth => 'Bu Ay';

  @override
  String get examsGroupLater => 'Daha Sonra';

  @override
  String get examsPastSectionTitle => 'Gecmis sinavlar';

  @override
  String get examsNoUpcoming => 'Bu donem icin yaklasan sinav yok';

  @override
  String get examsNoUpcomingSubtitle =>
      'Programinizi olusturmak icin \"Sinav Ekle\"ye dokunun';

  @override
  String get examsNoPast => 'Bu donem icin gecmis sinav yok';

  @override
  String get examsTypeMidterm => 'Vize';

  @override
  String get examsTypeFinal => 'Final';

  @override
  String get examsTypeQuiz => 'Quiz';

  @override
  String get examTypeQuiz => 'Quiz';

  @override
  String get examsLocationOnline => 'Online Sinav';

  @override
  String get examsLocationFaceToFace => 'Yuz yuze Sinav';

  @override
  String get examsLocationClassroomPrefix => 'Oda';

  @override
  String get examsInstructorPrefix => 'Ogretim Gorevlisi:';

  @override
  String get examsCoursePrefix => 'Ders:';

  @override
  String get examsTitleField => 'Sinav basligi';

  @override
  String get examsPickDateTimeError => 'Lutfen tarih ve saat sec';

  @override
  String get examsCreateError => 'Sinav olusturulamadi';

  @override
  String get examsOptionalCourse => 'Istege bagli ders';

  @override
  String get examsCourseOptionalField => 'Ders (istege bagli)';

  @override
  String get examsDateField => 'Sinav tarihi';

  @override
  String get examsTimeField => 'Sinav saati';

  @override
  String get examsOnlineToggle => 'Online sinav';

  @override
  String get examsClassroomField => 'Sinif';

  @override
  String get examsInstructorField => 'Ogretim gorevlisi';

  @override
  String get examsNotesOptionalField => 'Notlar (istege bagli)';

  @override
  String get examsCreateButton => 'Sinav Olustur';

  @override
  String get editExam => 'Sinavi Duzenle';

  @override
  String get examsUpdateError => 'Sinav guncellenemedi';

  @override
  String get examsNotFound => 'Sinav bulunamadi';

  @override
  String get examsNoItems => 'Sinav yok';

  @override
  String get examsCalendarTitle => 'Sinav Takvimi';

  @override
  String get examsNoItemsForDay => 'Bu gun sinav yok';

  @override
  String get examsCalendarOpenTooltip => 'Sinav takvimini ac';

  @override
  String get examUrgencyNoExamsSoon => 'Yakin zamanda sinav yok';

  @override
  String examUrgencyUpcoming(Object count, Object days) {
    return 'Sonraki $days gunde $count sinav';
  }

  @override
  String get examUrgencyHeavyWeek => 'Yogun sinav donemi';

  @override
  String get examDetailTitle => 'Sinav Detayi';

  @override
  String get examDetailDeletePrompt => 'Bu sinav silinsin mi?';

  @override
  String get examDetailDeleteWarning => 'Bu islem geri alinamaz.';

  @override
  String get examDetailDeleteWarningStrong =>
      'Bu islem sinavi ve hatirlaticilarini kalici olarak siler.';

  @override
  String get examsNextCardTitle => 'Siradaki Sinav';

  @override
  String examsInDays(int days) {
    return '$days gun sonra';
  }

  @override
  String aiDetRiskIncreased(Object delta, Object core) {
    return 'Risk puanin bu hafta %$delta artti.\n$core';
  }

  @override
  String aiDetHighStressInsight(Object stress) {
    return 'Oturum stresi yuksek ($stress/10). Bu genelde asiri yuklenme veya yorgunluk demektir.';
  }

  @override
  String get aiDetHighStressRecoPrimary =>
      'Bugun: tek konu icin 20-30 dakikalik bir oturum.';

  @override
  String get aiDetHighStressRecoSecondary =>
      'Sonraki bloga baslamadan once 5 dakika mola ver.';

  @override
  String aiDetOverdueInsight(Object count) {
    return 'Bu donemde gecikmis $count gorevin var - bunlar ilerleyene kadar riski yukseltiyor.';
  }

  @override
  String get aiDetOverdueRecoPrimary =>
      'Bugun: once en kucuk gecikmis gorevi bitir veya yeniden planla.';

  @override
  String get aiDetOverdueRecoSecondary =>
      'Sonra bir sonrakine gec; baslamadan once sure kutusu belirle.';

  @override
  String aiDetRiskHighInsight(Object score) {
    return 'Akademik risk yuksek ($score/100). Gorevler, calisma suresi veya duzenlilik ust uste biniyor.';
  }

  @override
  String aiDetRiskHighRecoPrimary(Object dueSoon) {
    return '18:00\'dan once: en acil/yaklasan goreve odaklan ($dueSoon yaklasan).';
  }

  @override
  String get aiDetRiskHighRecoSecondary =>
      'Takvime iki adet 25-40 dakikalik blok ekle; ilkini 2 saat icinde baslat.';

  @override
  String aiDetRiskModerateInsight(Object score) {
    return 'Akademik risk orta seviyede ($score/100). Haftalik ilerleme hedefin altinda ve toparlama adimi gerekiyor.';
  }

  @override
  String aiDetRiskModerateRecoPrimary(Object minutes) {
    return 'Simdi bir odak oturumu baslat ($minutes dk).';
  }

  @override
  String aiDetModerateSecondaryDueSoon(Object count) {
    return 'Bu aksam $count yaklasan gorevini son tarihe gore yeniden sirala.';
  }

  @override
  String aiDetModerateSecondaryDeficitMulti(
    Object sessions,
    Object m1,
    Object m2,
  ) {
    return 'Bugun: acigi daha hizli kapatmak icin $sessions oturum yap ($m1 + $m2 dk).';
  }

  @override
  String aiDetModerateSecondaryDeficitSingle(Object minutes) {
    return 'Bugun: $minutes dakikalik bir toparlama oturumu baslat.';
  }

  @override
  String get aiDetModerateSecondaryTomorrow =>
      'Yarin: risk artmasin diye ikinci bir 30 dakikalik blok ekle.';

  @override
  String get aiDetDefaultInsight =>
      'Gorunum yonetilebilir: burada gecikme sinyali yok ve risk yuksek bantta degil.';

  @override
  String get aiDetDefaultRecoPrimary =>
      'Bugun: 25 dakikalik bir tekrar oturumu yap.';

  @override
  String get aiDetDefaultRecoSecondary =>
      'Hafta ortasi: son tarihleri yenile ve tarihsiz gorevlere tarih ekle.';

  @override
  String get aiTaskUrgentInsight =>
      'Yuksek oncelikli acik islerin var - once bunlari tamamla.';

  @override
  String get aiTaskUrgentRecoPrimary => 'Bir acil isi tamamen bitir.';

  @override
  String get aiTaskUrgentRecoSecondary =>
      'Sonra sadece bir sonraki acil ise gec.';

  @override
  String get aiTaskBacklogInsight =>
      'Buyuk bekleyen listeleri ertelemeyi artirir.';

  @override
  String get aiTaskBacklogRecoPrimary => 'Bugun en kucuk iki gorevi bitir.';

  @override
  String get aiTaskBacklogRecoSecondary =>
      'Bu, her sabah gordugun listeyi kucultur.';

  @override
  String get aiTaskQueuedInsight => 'Tarihsiz siradaki isler genelde sarkar.';

  @override
  String get aiTaskQueuedRecoPrimary =>
      'Sonraki iki gorevi takvimine yerlestir.';

  @override
  String get aiTaskQueuedRecoSecondary =>
      'Sadece son tarih degil, baslangic saati de ver.';

  @override
  String get aiTaskNoneInsight => 'Bu gorunumde acil oge yok.';

  @override
  String get aiTaskNoneRecoPrimary =>
      'Bos zamani okuma veya uzun odevler icin kullan.';

  @override
  String get aiTaskNoneRecoSecondary =>
      'Henuz eklenmediyse sonraki sinav tarihini ekle.';

  @override
  String aiDetDeficitHighInsight(Object hours) {
    return 'Haftalik calisma hedefinin yaklasik $hours saat gerisindesin - birden fazla gun kacirmak hizla birikir.';
  }

  @override
  String get aiDetDeficitHighRecoPrimary =>
      'Bugun: takvimine 2-3 blok ekle (her biri 25-40 dk).';

  @override
  String get aiDetDeficitHighRecoSecondary =>
      'Sabit saat kullan - \"canim isterse\" degil.';

  @override
  String aiDetDeficitMediumInsight(Object hours) {
    return 'Haftalik hedefinin yaklasik $hours saat altindasin.';
  }

  @override
  String get aiDetDeficitMediumRecoPrimary =>
      'Pazardan once: en yakin son tarihli derse 1-2 odak oturumu ekle.';

  @override
  String get aiDetDeficitMediumRecoSecondary =>
      'Bu hafta notunu en cok etkileyen dersi sec.';

  @override
  String aiDetConsistencyLowInsight(Object percent) {
    return 'Duzenlilik dusuk (%$percent). Duzensiz gunler son teslimleri daha baskili hale getirir.';
  }

  @override
  String get aiDetConsistencyLowRecoPrimary =>
      'Sonraki 5 is gunu: ayni 30 dakikalik baslangic penceresi (orn. ogle yemegi sonrasi).';

  @override
  String get aiDetConsistencyLowRecoSecondary =>
      'Bu aksam: mevcut seviyeden cikmak icin bir 25 dakikalik oturum yap.';

  @override
  String aiDetConsistencyMidInsight(Object percent) {
    return 'Duzenlilik orta seviyede (%$percent). Calisiyorsun ama ritim sabit degil.';
  }

  @override
  String get aiDetConsistencyMidRecoPrimary =>
      'Bugun: mevcut bir aliskanligindan hemen sonra 25-35 dakika calis.';

  @override
  String get aiDetConsistencyMidRecoSecondary =>
      'Yarin: ayni saatte tekrar et.';

  @override
  String aiDetDueSoonManyInsight(Object count) {
    return '$count gorevin yakinda teslim - aralarinda sik gecis stresi artirir.';
  }

  @override
  String get aiDetDueSoonManyRecoPrimary =>
      'Son tarihe gore sirala: once hizli kazanclar, sonra en zor gorev.';

  @override
  String get aiDetDueSoonManyRecoSecondary =>
      'Bunlar temizlenene kadar yeni opsiyonel isleri durdur.';

  @override
  String get aiDetDueSoonSomeInsight =>
      'Yakinda teslim edilmesi gereken ders islerin var - onceden bitirmek son dakika calismasindan iyidir.';

  @override
  String get aiDetDueSoonSomeRecoPrimary =>
      'Bugun: once en yakin son tarih icin zaman blogu ayir.';

  @override
  String get aiDetDueSoonSomeRecoSecondary =>
      'Geciken yoksa sonraki ders/quiz icin on okuma yap.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterInsight =>
      'Bu takvim haftasinda son tarih yok, ama donem calismalari izlenmeye devam ediyor.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterRecoPrimary =>
      'Bu boslugu okuma veya sinav hazirligi icin kullan.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterRecoSecondary =>
      'Tarihsiz gorevlere tarih ekle ki plan gercekci kalsin.';

  @override
  String get aiDetCalendarNoTasksInsight =>
      'Bu takvim haftasi penceresinde gorev yok - son tarihler daha ileride olabilir.';

  @override
  String get aiDetCalendarNoTasksRecoPrimary =>
      'Ders calismasini one cek veya zayif konulari guclendir.';

  @override
  String get aiDetCalendarNoTasksRecoSecondary =>
      'Sonraki yogun haftadan once ekstra zaman biriktir.';

  @override
  String get dataPermissionsTitle => 'Veri ve Izinler';

  @override
  String get contactSupportTitle => 'Iletisim / Destek';

  @override
  String get privacyPolicyIntro =>
      'Bu politika, Acadia\'nin hangi verileri neden kullandigini aciklar.';

  @override
  String get privacyPolicyEffectiveDate => 'Yururluk tarihi: Mayis 2026';

  @override
  String get privacyPolicyCollectedTitle => 'Topladigimiz veriler';

  @override
  String get privacyPolicyCollectedAccount => 'Hesap bilgileri (ad, e-posta)';

  @override
  String get privacyPolicyCollectedAcademic =>
      'Akademik veriler (gorevler, sinavlar, calisma oturumlari)';

  @override
  String get privacyPolicyCollectedMood =>
      'Ruh hali verileri yalnizca ruh hali takibi aciksa';

  @override
  String get privacyPolicyUseTitle => 'Verilerinizi su amaclarla kullaniriz';

  @override
  String get privacyPolicyUseAnalytics =>
      'Analiz ve ilerleme icgoruleri sunmak';

  @override
  String get privacyPolicyUseAi => 'YZ calisma onerileri uretmek';

  @override
  String get privacyPolicyUseFeatures =>
      'Ders ve gorev ozelliklerini calistirmak';

  @override
  String get privacyPolicyStorageTitle => 'Depolama';

  @override
  String get privacyPolicyStorageSupabase =>
      'Verileriniz Supabase ile guvenli sekilde saklanir';

  @override
  String get privacyPolicyStorageRetention =>
      'Verileriniz hesabiniz aktif oldugu surece saklanir ve donem gecmisi ozelliklerinde kullanilir';

  @override
  String get privacyPolicyNotificationsTitle => 'Bildirimler';

  @override
  String get privacyPolicyNotificationsLocalOnly =>
      'Hatirlaticilar yalnizca ders/ruh hali icin yerel bildirimlerdir';

  @override
  String get privacyPolicyControlTitle => 'Kontrol sizde';

  @override
  String get privacyPolicyControlMood =>
      'Ruh hali takibini istediginiz zaman kapatabilirsiniz';

  @override
  String get privacyPolicyControlDelete =>
      'Hesap verilerinizin silinmesini destek uzerinden talep edebilirsiniz';

  @override
  String get privacyPolicyNoSell =>
      'Verilerinizi satmiyoruz ve reklam icin ucuncu taraflarla paylasmiyoruz.';

  @override
  String get privacyPolicyThirdParty =>
      'Acadia, temel uygulama ozelliklerini calistirmak icin yalnizca guvenilir altyapi saglayicilarini (Supabase, Firebase ve istege bagli e-posta icin Resend) kullanir.';

  @override
  String get privacyPolicyAiDisclaimer =>
      'YZ tarafindan uretilen icgoruler oneridir, profesyonel tavsiye degildir.';

  @override
  String get termsIntro =>
      'Bu kosullar sizin sorumluluklarinizi ve Acadia hizmet sinirlarini aciklar.';

  @override
  String get termsLine1 => 'Bu uygulama egitim ve verimlilik amacli sunulur.';

  @override
  String get termsLine2 =>
      'Analizlerin, hatirlaticilarin veya YZ icgorulerinin dogrulugu garanti edilmez.';

  @override
  String get termsLine3 =>
      'Uygulamaya girdiginiz verilerden ve bu verilerle aldiginiz kararlardan siz sorumlusunuz.';

  @override
  String get termsLine4 =>
      'Ruh hali takibi opsiyoneldir ve yalnizca uygulama ici ozelliklerde kullanilir.';

  @override
  String get termsLine5 =>
      'Ozellikleri istedigimiz zaman guncelleyebilir veya degistirebiliriz.';

  @override
  String get termsLine6 =>
      'Acadia\'yi kullanarak bu kosullari kabul etmis olursunuz.';

  @override
  String get dataPermissionsNotificationsTitle => 'Bildirimler';

  @override
  String get dataPermissionsNotificationsUsage =>
      'Ders ve ruh hali hatirlatici bildirimleri icin kullanilir.';

  @override
  String get dataPermissionsNotCollectedTitle => 'Toplamadigimiz veriler';

  @override
  String get dataPermissionsNoTracking => 'Cihaz takip verisi yok';

  @override
  String get dataPermissionsNoLocation => 'Konum verisi yok';

  @override
  String get dataPermissionsNoContacts => 'Rehber verisi yok';

  @override
  String get dataPermissionsNoCameraTracking =>
      'Kamera kaydi veya arka plan kamera erisimi yok';

  @override
  String get dataPermissionsAvatarNote =>
      'Galeri/kamera izni yalnizca profil avatarinizi manuel olarak degistirdiginizde istenir.';

  @override
  String get contactSupportIntro =>
      'Destek, geri bildirim veya veri talepleri icin bize ulasin:';

  @override
  String get contactSupportTopics =>
      'Destek ekibi hesap erisimi, veri talepleri, bildirim sorunlari ve hatali uygulama davranislari konularinda yardimci olur.';

  @override
  String get legalContactLine => 'E-posta: support@acadia.app';

  @override
  String get moodTrackingOffBanner => 'Ruh hali takibi kapalı';

  @override
  String get moodTrackingOffBannerSubtitle =>
      'Yeni ruh hali verisi toplanmayacak';

  @override
  String get moodTrackingOffGoToSettings => 'Ayarlar';

  @override
  String get moodTrackingStatusOff => 'Durum: Kapalı';

  @override
  String get moodTrackingStatusActive => 'Durum: Aktif';

  @override
  String get moodTrackingNowEnabled => 'Ruh hali takibi etkinleştirildi';

  @override
  String get moodTrackingNowDisabled => 'Ruh hali takibi devre dışı bırakıldı';

  @override
  String get moodTrackingHistoricalOnly =>
      'Ruh hali takibi kapalı. Geçmiş ruh hali içgörüleri hâlâ mevcut. Yeni ruh hali ve stres verisi kaydetmek için takibi etkinleştirin.';

  @override
  String get moodTrackingOffSessionSnackbar =>
      'Ruh hali takibi kapalı. Oturum ruh halini kaydetmek için Ayarlar\'dan etkinleştirin.';

  @override
  String get moodTrackingOffBadge => 'Takip Kapalı';

  @override
  String get studentProfileSummaryTitle => 'Akademik Profilim';

  @override
  String get profileSummaryOverviewSection => 'Genel Bakış';

  @override
  String get profileSummaryIdentitySection => 'Akademik Kimlik';

  @override
  String get profileSemesterHistorySection => 'Dönem Geçmişi';

  @override
  String get profileActiveSemesterSection => 'Aktif Dönem';

  @override
  String profileSemestersCount(int count) {
    return '$count dönem';
  }

  @override
  String profileCoursesCount(int count) {
    return '$count ders';
  }

  @override
  String get profileGpaLabel => 'Dönem GPA';

  @override
  String get profileCgpaLabel => 'CGPA';

  @override
  String profileTaskSummary(int done, int total) {
    return '$done/$total görev';
  }

  @override
  String profileDeadlineSummary(int done, int total) {
    return '$done/$total son tarih';
  }

  @override
  String get profileStudyStatsSection => 'Çalışma İstatistikleri';

  @override
  String get profilePerformanceHighlightsSection => 'Performans Özeti';

  @override
  String get profileStudySessions => 'Oturum';

  @override
  String get profileWeeklyAvgHours => 'Ort. saat/hafta';

  @override
  String get profileStudyConsistency => 'Tutarlılık';

  @override
  String get profileThisWeekHours => 'Bu hafta';

  @override
  String get profileStudyGoal => 'Haftalık hedef';

  @override
  String get profileBestSemester => 'En İyi Dönem';

  @override
  String get profileMostImproved => 'En Fazla Gelişim';

  @override
  String get profileTotalCredits => 'Toplam Kredi';

  @override
  String get profileNotSet => '—';

  @override
  String get profileNoGpaYet => 'YOK';

  @override
  String get profileNoCoursesYet => 'Ders yok';

  @override
  String get profileCoursesThisSemester => 'Bu dönem dersleri';

  @override
  String get countryLabel => 'Ülke';
}
