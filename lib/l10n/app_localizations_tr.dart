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
  String get notifications => 'Bildirimler';

  @override
  String get noNotifications => 'Henüz bildirim yok';

  @override
  String get notificationsCaughtUp => 'Her şey yolunda';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get earlier => 'Daha Önce';

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
  String get deepFocus => 'Derin Odak';

  @override
  String get analytics => 'Analiz';

  @override
  String get studyHours => 'Çalışma saatleri';

  @override
  String get taskCompletionRate => 'Görev tamamlama oranı';

  @override
  String get stressTrends => 'Stres eğilimleri';

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
  String get signup => 'Hesap Oluştur';

  @override
  String get invalidCredentials => 'Geçersiz e-posta veya şifre.';

  @override
  String get tooManyRequests =>
      'Çok fazla istek. Lütfen daha sonra tekrar deneyin.';

  @override
  String get networkError => 'Bağlantı hatası. Tekrar deneyin.';

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
  String get tooManyAttempts =>
      'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';

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
  String get basicIdentity => 'Temel Kimlik';

  @override
  String get academicProgram => 'Akademik Program';

  @override
  String get currentSemesterLoad => 'Dönem İş Yükü';

  @override
  String get learningPatternCalibration => 'Öğrenme Modelleri';

  @override
  String get universityName => 'Üniversite Adı';

  @override
  String get degreeType => 'Derece Türü';

  @override
  String get major => 'Bölüm';

  @override
  String get minor => 'Yandal';

  @override
  String get academicYear => 'Akademik Yıl';

  @override
  String get expectedGraduationYear => 'Beklenen Mezuniyet Yılı';

  @override
  String get currentSemesterNumber => 'Mevcut Dönem';

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
  String get addCourse => 'Ders Ekle';

  @override
  String get editCourse => 'Dersi Düzenle';

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
  String get creditsLabel => 'Kredi';

  @override
  String get sortAlphabetical => 'Alfabetik';

  @override
  String get sortStudyTime => 'Çalışma Süresi';

  @override
  String get semester => 'Dönem';

  @override
  String get selectSemester => 'Dönem Seç';

  @override
  String get setAsActive => 'Aktif dönem olarak ayarla';

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
  String get errorLoadingCourses => 'Dersler yüklenirken hata oluştu';

  @override
  String get academicInformation => 'Akademik Bilgiler';

  @override
  String get editProfile => 'Profili Düzenle';

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
  String get noUpcomingDeadlines => 'Yaklaşan teslim tarihi yok';

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
  String get focusLevel => 'Focus Level';

  @override
  String get deepFlow => 'Deep Flow';

  @override
  String get building => 'Building';

  @override
  String get studyHoursByCourse => 'Derse Göre Çalışma Saatleri';

  @override
  String get weeklyTaskCompletion => 'Haftalık Görev Tamamlama';

  @override
  String get dailyInsight => 'Daily Insight';

  @override
  String get focusOnStudies => 'Focus on your studies today.';

  @override
  String get thisWeekLabel => 'This Week';

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
      'Riskiniz orta düzeyde; yaklaşan görevlere ve çalışma hedeflerine dikkat edin.';

  @override
  String get riskInterpretationLow =>
      'Güvenli bir aralıktasınız. Mevcut ilerlemenizi sürdürün.';

  @override
  String riskHoursRemaining(Object hours) {
    return '$hours saat kaldı';
  }

  @override
  String get riskGoalReached => 'Hedefe ulaşıldı!';

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
    return '+$delta risk artışı';
  }

  @override
  String riskTrendDown(int delta) {
    return '-$delta (iyileşti)';
  }

  @override
  String get riskTrendStable => '+0 (değişim yok)';

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
  String get overviewNoUpcomingTasks => 'Yaklaşan teslim tarihi yok';

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
    return 'Bu haftaki görevler: $completed/$total tamamlandı';
  }

  @override
  String get noStudyDataThisWeek => 'Bu hafta çalışma oturumu yok';

  @override
  String get noTasksThisWeek => 'Bu haftaya planlanmış görev yok';
}
