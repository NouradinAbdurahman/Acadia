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
  String get tooManyRequests => 'Lütfen tekrar denemeden önce biraz bekleyin.';

  @override
  String get pleaseWait => 'Lütfen tekrar denemeden önce biraz bekleyin.';

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
  String get deleteSemesterWarning =>
      'Bu dönem, dönem listenizden kaldırılacak.';

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
  String get focusLevel => 'Odak Seviyesi';

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
  String get thisWeekLabel => 'Bu hafta';

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
      'Riskiniz orta seviyede. Görevleri tamamlamaya ve çalışma süresini artırmaya odaklanın.';

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
    return 'Geçen haftaya göre $delta puan arttı';
  }

  @override
  String riskTrendDown(int delta) {
    return 'Geçen haftaya göre $delta puan iyileşti';
  }

  @override
  String get riskTrendStable => 'Değişim yok';

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

  @override
  String get examResults => 'Ders Sonuçları';

  @override
  String get addResult => 'Sonuç Ekle';

  @override
  String get editResult => 'Sonucu Düzenle';

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
  String get trendNotEnoughData => 'Yeterli veri yok';

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
  String get trendInsightStableMessage =>
      'Henüz belirgin bir değişim yok. Düzenli kayıt tutmaya devam et.';

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
  String get gettingStarted => 'Yeni başlıyor';

  @override
  String get noDataYet => 'Henüz veri yok';

  @override
  String get statusStable => 'Stabil';

  @override
  String get statusImproving => 'Gelişiyor';

  @override
  String get statusDeclining => 'Düşüşte';

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
  String get reset => 'Sıfırla';

  @override
  String get status => 'Durum';
}
