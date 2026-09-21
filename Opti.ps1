# =============================================================================
#  OPTI - Aplikasi Optimalisasi Kinerja PC
#  Copyright (c) H.MP Dev  |  Pusat Developer: https://hmp.my.id
#  ----------------------------------------------------------------------------
#  Fitur:
#    - Terms & Policy (wajib disetujui sebelum aplikasi berjalan)
#    - Matikan Layanan & Fitur Windows yang useless (checkbox, + tombol 1 klik)
#    - Optimasi cepat via registry (telemetri, iklan, tips, WER, visual FX)
#    - Pembersih cache otomatis (scan semua folder bernama *cache* + temp)
#    - Pembersih RAM (Empty Standby List)
#    - Backup & Restore semua perubahan
#
#  UI: Bahasa Indonesia, ASCII only (aman untuk PowerShell 5.1).
#  Jalankan via run.bat atau: powershell -ExecutionPolicy Bypass -File Opti.ps1
# =============================================================================

param([switch]$NoElevate)

# ------------------------------------------------------------------ setup ----
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------------------------------------------------------
#  Tempat penyimpanan.
#  - Konfigurasi & tools: folder di samping skrip (file) / %LOCALAPPDATA%\Opti
#    saat dijalankan via "irm <URL> | iex". Admin mere-launch perintah remote
#    yang sama (lihat SOURCE_URL).
#  - Backup: otomatis dibuat di folder "Documents\BackupOpti" pada komputer
#    siapa pun yang memakai fitur ini.
# --------------------------------------------------------------------------
$script:SourceRoot = $null
if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
    $script:SourceRoot = Split-Path -Parent $PSCommandPath
}

$script:SourceUrl = 'https://raw.githubusercontent.com/HMPoetra/Opti/main/Opti.ps1'
$script:Root      = if ($script:SourceRoot) { $script:SourceRoot } else { Join-Path $env:LOCALAPPDATA 'Opti' }
$script:ConfigFile  = Join-Path $script:Root 'config.json'
$script:BackupDir   = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'BackupOpti'
$script:Version     = '1.4.0'

if (-not (Test-Path -LiteralPath $script:BackupDir)) { New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null }

# ------------------------------------------------------------- admin check ----
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $script:IsAdmin -and -not $NoElevate) {
    if ($script:SourceRoot) {
        # mode file: relaunch file itu sendiri sebagai admin (konsol disembunyikan)
        $arg = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    } elseif ($script:SourceUrl) {
        # mode remote (irm ... | iex): relaunch perintah remote yang sama
        $arg = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"irm $script:SourceUrl | iex`""
    } else {
        Add-Type -AssemblyName PresentationFramework | Out-Null
        [System.Windows.MessageBox]::Show("Jalankan perintah Opti ini dari PowerShell yang sudah Administrator.", 'Opti', 'OK', 'Warning') | Out-Null
        exit
    }
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arg | Out-Null
    } catch {
        Add-Type -AssemblyName PresentationFramework | Out-Null
        [System.Windows.MessageBox]::Show("Opti membutuhkan izin Administrator. Gagal meminta izin:`n$($_.Exception.Message)", 'Opti', 'OK', 'Warning') | Out-Null
    }
    exit
}

# seluruh isi aplikasi dibungkus try/catch agar error startup terlihat (tidak mati diam-diam)
try {

# ----------------------------------------------------------------- EULA -------
$script:TermsText = @"
================================================================================
          PERATURAN & KEBIJAKAN (TERMS & POLICY) - APLIKASI OPTI
================================================================================

(c) H.MP Dev  |  Pusat Developer: https://hmp.my.id

1. TENTANG APLIKASI
   Opti adalah alat (tool) yang membantu mengoptimalkan kinerja PC Windows
   dengan mematikan layanan/fitur yang jarang berguna, menghapus file cache,
   dan mengosongkan RAM (standby list). Aplikasi ini WAJIB dijalankan dengan
   hak Administrator.

2. HAK AKSES ADMINISTRATOR
   Aplikasi ini mengubah pengaturan sistem, layanan Windows, registry, dan
   menghapus data. Hak akses Administrator adalah syarat mutlak. Dengan
   menekan tombol "SETUJU, LANJUTKAN", ANDA MEMBERI IZIN aplikasi untuk
   mengubah dan menghapus data pada komputer Anda.

3. DATA YANG DIASES & DIUBAH
   a) Layanan dan fitur Windows: aplikasi dapat mengubah "startup type"
      (Nonaktif / Manual / Otomatis) dari layanan yang Anda pilih.
   b) Registry: kunci pengaturan Windows yang Anda pilih untuk diubah
      (telemetri, saran/iklan, pelaporan error, efek visual, dll).
   c) File cache: isi folder yang namanya mengandung kata "cache".
   d) File sementara (temp), Prefetch, dan Recycle Bin (jika diaktifkan).
   e) RAM: pengosongan daftar standby dan modified page list.

4. PENGHAPUSAN DATA (CACHE & TEMP)
   Penghapusan dilakukan pada ISI folder cache dan temp, bukan folder itu
   sendiri. File yang sedang dipakai proses lain akan dilewati secara aman.
   PERINGATAN: walau diusahakan selektif, ada kemungkinan file tertentu yang
   anda butuhkan ikut terhapus. Back up data penting Anda terlebih dahulu.

5. PERUBAHAN LAYANAN & FITUR
   Anda yang memilih layanan mana yang dimatikan melalui daftar centang
   (checkbox). Aplikasi hanya menandai rekomendasi; keputusan akhir ada di
   tangan Anda. Beberapa layanan wajib tetap berjalan (mis. Windows Update,
   audio, jaringan) agar Windows tetap sehat.

6. BACKUP & RESTORE
   Setelah setiap proses pembersihan/optimasi, Opti otomatis menyimpan backup
   layanan & registry ke folder "Documents\BackupOpti" di komputer Anda. Anda
   dapat mengembalikan (restore) seluruh pengaturan kapan saja dari tab
   Backup & Restore.

7. PRIVASI
   Opti TIDAK mengirim data ke mana pun, TIDAK membuat akun, TIDAK memuat
   iklan, dan TIDAK menampilkan telemetri. Semua proses 100% berjalan di
komputer Anda. Satu-satunya file yang ditulis Opti: config.json,
    folder Documents\BackupOpti, dan file log ringan.

8. DISCLAIMER / RISIKO & TANGGUNG JAWAB
   Opti disediakan "sebagaimana adanya" (AS-IS) TANPA jaminan apa pun.
   Penggunaan tool ini dapat memengaruhi stabilitas sistem, fitur Windows,
   atau aplikasi lain. Pengembang TIDAK bertanggung jawab atas:
   - kerusakan sistem, kehilangan data, atau ketidakstabilan,
   - layanan yang ternyata diperlukan oleh aplikasi tertentu,
   - perubahan yang dilakukan pengguna pada pengaturan di luar rekomendasi.
   Anda menggunakan Opti SEPENUHNYA atas risiko Anda sendiri. Selalu buat
   restore point / backup data Anda sebelum menggunakan alat ini.

9. SYARAT PENGGUNAAN
   - Anda berusia setidaknya 18 tahun atau memiliki izin pemilik komputer.
   - Anda hanya akan menggunakan Opti di komputer yang Anda miliki/kelola.
   - Anda memahami setiap opsi yang Anda pilih sebelum menerapkannya.
   - Anda tidak akan menggunakan Opti untuk merusak sistem orang lain.

10. PERSETUJUAN
   Dengan menekan "SETUJU, LANJUTKAN" Anda menyatakan telah membaca,
   memahami, dan menyetujui seluruh isi peraturan & kebijakan ini.
   Jika Anda tidak setuju, tekan "TIDAK SETUJU" dan aplikasi akan TUTUP.

-------------------------------------------------------------------------------
Versi: $($script:Version)   |   Semua pengaturan disimpan lokal di folder aplikasi.
(c) H.MP Dev  |  Pusat Developer: https://hmp.my.id
================================================================================
"@

function Get-OptiConfig {
    if (Test-Path -LiteralPath $script:ConfigFile) {
        try { return (Get-Content -Raw -LiteralPath $script:ConfigFile | ConvertFrom-Json) } catch { }
    }
    return [pscustomobject]@{ TermsAccepted = $false; TermsVersion = 0 }
}

function Save-OptiConfig {
    param($Config)
    $Config | ConvertTo-Json | Set-Content -LiteralPath $script:ConfigFile -Encoding UTF8
}

# ------------------------------------------------------------ native RAM ----
$script:NativeCode = @'
using System;
using System.Runtime.InteropServices;

namespace OptiRam {
    public static class Native {
        [DllImport("ntdll.dll")]
        public static extern int NtSetSystemInformation(int SystemInformationClass,
                                                        IntPtr SystemInformation,
                                                        int SystemInformationLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr hObject);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
                                                         IntPtr NewState, uint BufferLength,
                                                         IntPtr PreviousState, IntPtr ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool GetTokenInformation(IntPtr TokenHandle, int TokenInformationClass,
                                                       IntPtr TokenInformation, uint TokenInformationLength,
                                                       out uint ReturnLength);

        private const uint TOKEN_ADJUST_PRIVILEGES = 0x20;
        private const uint TOKEN_QUERY = 0x8;
        private const int SE_PRIVILEGE_ENABLED = 0x2;
        private const int TOKEN_PRIVILEGES_CLASS = 3; // TokenPrivileges

        // Mengaktifkan SEMUA privilege di dalam token. Tidak memakai
        // LookupPrivilegeValue karena di beberapa Windows lookup nama privilege
        // tertentu gagal (ERROR_NO_SUCH_PRIVILEGE), dan API empty-standby
        // memerlukan SeProfileSingleProcess dalam keadaan enabled.
        private static bool EnableAllPrivileges(out int countEnabled) {
            countEnabled = 0;
            IntPtr hToken;
            if (!OpenProcessToken((IntPtr)(-1), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken)) return false;
            try {
                uint ret;
                GetTokenInformation(hToken, TOKEN_PRIVILEGES_CLASS, IntPtr.Zero, 0, out ret);
                IntPtr src = Marshal.AllocHGlobal((int)ret);
                try {
                    if (!GetTokenInformation(hToken, TOKEN_PRIVILEGES_CLASS, src, ret, out ret)) return false;
                    int count = Marshal.ReadInt32(src);
                    if (count > 0) {
                        IntPtr list = Marshal.AllocHGlobal(4 + count * 12);
                        try {
                            Marshal.WriteInt32(list, 0, count);
                            IntPtr s = new IntPtr(src.ToInt64() + 4);
                            IntPtr d = new IntPtr(list.ToInt64() + 4);
                            for (int i = 0; i < count; i++) {
                                Marshal.WriteInt32(d, 0, Marshal.ReadInt32(s));
                                Marshal.WriteInt32(d, 4, Marshal.ReadInt32(s, 4));
                                Marshal.WriteInt32(d, 8, SE_PRIVILEGE_ENABLED);
                                s = new IntPtr(s.ToInt64() + 12);
                                d = new IntPtr(d.ToInt64() + 12);
                            }
                            if (!AdjustTokenPrivileges(hToken, false, list, (uint)(4 + count * 12), IntPtr.Zero, IntPtr.Zero)) return false;
                            countEnabled = count;
                        } finally {
                            Marshal.FreeHGlobal(list);
                        }
                    }
                    return true;
                } finally {
                    Marshal.FreeHGlobal(src);
                }
            } finally {
                CloseHandle(hToken);
            }
        }

        private static int Purge(int command, int flags) {
            int n = 0;
            EnableAllPrivileges(out n);
            MemoryListCommand cmd = new MemoryListCommand();
            cmd.Command = command;
            cmd.Flags = flags;
            int size = Marshal.SizeOf(typeof(MemoryListCommand));
            IntPtr ptr = Marshal.AllocHGlobal(size);
            try {
                Marshal.StructureToPtr(cmd, ptr, false);
                return NtSetSystemInformation(80, ptr, size); // SystemMemoryListInformation = 80
            } finally {
                Marshal.FreeHGlobal(ptr);
            }
        }

        public static int EmptyStandby() {
            return Purge(4, 1); // MemoryPurgeStandbyList, flag purge standby
        }

        public static int EmptyStandbyAndModified() {
            return Purge(4, 3); // purge standby + modified page list
        }

        // Diagnose: menelusuri mengapa panggilan purge gagal (untuk laporan di UI)
        public static string Diagnose() {
            int n = 0;
            bool ok = EnableAllPrivileges(out n);
            return "enable_all=" + (ok ? 1 : 0) + ";privs=" + n + ";call=" + (((uint)Purge(4, 1)) & 0xFFFFFFFF).ToString("X8");
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MemoryListCommand {
        public int Command;
        public int Flags;
    }
}
'@

try { Add-Type -TypeDefinition $script:NativeCode -ErrorAction Stop } catch {
    $script:NativeLoadError = $_.Exception.Message
}

# --------------------------------------------------- data: layanan useless ----
$script:Useless = @(
    @{ Name='DiagTrack';        Label='Telemetri (DiagTrack)';                    Note='Mengirim data telemetri ke Microsoft.' }
    @{ Name='dmwappushservice'; Label='WAP Push (Device Management)';             Note='Bagian telemetri push WAP.' }
    @{ Name='diagnosticshub.standardcollector.service'; Label='Standard Collector Diagnostics'; Note='Kolektor data diagnostik.' }
    @{ Name='MapsBroker';       Label='Manajer Peta Unduhan';                     Note='Matikan bila jarang pakai aplikasi peta.' }
    @{ Name='Fax';              Label='Faks';                                     Note='Layanan faks warisan (obsolete).' }
    @{ Name='RetailDemo';       Label='Retail Demo';                              Note='Khusus toko ritel, matikan di PC biasa.' }
    @{ Name='WerSvc';           Label='Pelaporan Error Windows';                  Note='Pelaporan error, aman dimatikan.' }
    @{ Name='wcncsvc';          Label='Windows Connect Now';                      Note='Konfigurasi WiFi WCN.' }
    @{ Name='WMPNetworkSvc';    Label='Berbagi Jaringan WMP';                     Note='Matikan bila tidak berbagi media WMP.' }
    @{ Name='icssvc';           Label='Hotspot Seluler Windows';                  Note='Matikan bila tidak pakai mobile hotspot.' }
    @{ Name='XblAuthManager';   Label='Xbox Live Authentication';                 Note='Matikan bila tidak main Xbox di PC.' }
    @{ Name='XblGameSave';      Label='Xbox Live Game Save';                      Note='Matikan bila tidak main Xbox di PC.' }
    @{ Name='XboxNetApiSvc';    Label='Jaringan Xbox Live';                       Note='Matikan bila tidak main Xbox di PC.' }
    @{ Name='XboxGipSvc';       Label='Xbox GIP Peripheral';                      Note='Matikan bila tidak pakai peripheral Xbox.' }
    @{ Name='SysMain';          Label='SysMain (Superfetch)';                     Note='Preload apps; sering sebabkan disk 100%.' }
    @{ Name='TabletInputService'; Label='Keyboard Sentuh & Panel Tulis';          Note='Matikan bila pakai keyboard fisik.' }
    @{ Name='PhoneSvc';         Label='Layanan Telepon';                          Note='Integrasi Windows dengan ponsel.' }
    @{ Name='PcaSvc';           Label='Asisten Kompatibilitas Program';           Note='Sering memakan CPU di latar belakang.' }
    @{ Name='WpcMonSvc';        Label='Kontrol Orang Tua';                        Note='Matikan bila tidak pakai parental control.' }
    @{ Name='bthserv';          Label='Dukungan Bluetooth';                       Note='Matikan bila tidak pakai Bluetooth.' }
    @{ Name='BluetoothUserService'; Label='Layanan Pengguna Bluetooth';           Note='Matikan bila tidak pakai Bluetooth.' }
    @{ Name='Spooler';          Label='Print Spooler';                            Note='Matikan bila TIDAK ada printer.' }
    @{ Name='DPS';              Label='Kebijakan Diagnostik';                     Note='Layanan diagnostik Windows.' }
    @{ Name='WdiServiceHost';   Label='Host Layanan Diagnostik';                  Note='Bagian diagnostik Windows.' }
    @{ Name='WdiSystemHost';    Label='Host Sistem Diagnostik';                   Note='Bagian diagnostik Windows.' }
    @{ Name='storageservice';   Label='Layanan Penyimpanan (Store)';              Note='Sinkron data Store. Matikan bila tak penting.' }
    @{ Name='LicenseManager';   Label='Manajer Lisensi Windows';                  Note='Manajemen lisensi; aman dimatikan.' }
    @{ Name='ScDeviceEnum';     Label='Enumerasi Perangkat Smart Card';           Note='Matikan bila tak pakai smart card.' }
    @{ Name='SCardSvr';         Label='Kartu Pintar (Smart Card)';                Note='Matikan bila tak pakai smart card.' }
    @{ Name='SCPolicySvc';      Label='Kebijakan Kartu Pintar';                   Note='Matikan bila tak pakai smart card.' }
    @{ Name='WebClient';        Label='WebClient';                                Note='Akses folder WebDAV.' }
    @{ Name='WpnService';       Label='Layanan Notifikasi Push';                  Note='Notifikasi push Windows.' }
    @{ Name='OneSyncSvc';       Label='Host Sinkronisasi';                        Note='Sinkron mail/kontak. Matikan bila tak pakai akun MS.' }
    @{ Name='WSearch';          Label='Windows Search  (OPSIONAL)';               Note='BUKAN dicentang otomatis. Matikan hanya bila jarang cari file.' }
)

$script:UselessMap = @{}
foreach ($u in $script:Useless) { $script:UselessMap[$u.Name] = $u }
$script:UselessNames = @($script:Useless | ForEach-Object { $_.Name })

# ------------------------------------------------- data: tweak registry -------
$script:Tweaks = @(
    [pscustomobject]@{ Id='telemetry'; Label='Nonaktifkan Telemetri & Pengumpulan Data Windows';        Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Value=0 }
    [pscustomobject]@{ Id='wer';       Label='Nonaktifkan Windows Error Reporting (WER)';               Path='HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; Name='Disabled'; Value=1 }
    [pscustomobject]@{ Id='startads';  Label='Nonaktifkan Saran/Apps Promosi di Menu Start';            Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338389Enabled'; Value=0 }
    [pscustomobject]@{ Id='tips';      Label='Nonaktifkan Tips & Saran Windows';                        Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-310093Enabled'; Value=0 }
    [pscustomobject]@{ Id='adsfolder'; Label='Nonaktifkan Saran/Iklan di File Explorer';                Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ShowSyncProviderNotifications'; Value=0 }
    [pscustomobject]@{ Id='adslock';   Label='Nonaktifkan Iklan di Lock Screen';                        Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338388Enabled'; Value=0 }
    [pscustomobject]@{ Id='visualfx';  Label='Atur Efek Visual ke Mode "Best Performance" (login ulang)'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name='VisualFXSetting'; Value=2 }
)
$script:TweakEnabled = @{}
foreach ($t in $script:Tweaks) { $script:TweakEnabled[$t.Id] = $false }

# -------------------------------------------------------------- helpers ------
function Show-OptiMsg {
    param([string]$Text, [string]$Title = 'Opti', [string]$Kind = 'Info')
    $icon = switch ($Kind) {
        'Warn' { [System.Windows.Forms.MessageBoxIcon]::Warning }
        'Err'  { [System.Windows.Forms.MessageBoxIcon]::Error }
        default { [System.Windows.Forms.MessageBoxIcon]::Information }
    }
    [System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

function Confirm-OptiMsg {
    param([string]$Text, [string]$Title = 'Opti')
    return ([System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question) -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Write-OptiStatus {
    param([string]$Message)
    if ($script:lblStatus) { $script:lblStatus.Text = $Message; [System.Windows.Forms.Application]::DoEvents() }
}

function Set-OptiProgress {
    param([int]$Value, [int]$Max = 100)
    if ($script:ProgressBar) {
        $script:ProgressBar.Maximum = $Max
        if ($Value -gt $Max) { $Value = $Max }
        $script:ProgressBar.Value = $Value
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Show-OptiLoading {
    param([string]$Text = 'Memproses...')
    if (-not $script:LoadingPanel) { return }
    Update-OptiLoadingBounds
    $script:LoadingText = $Text
    $script:LoadingDots = 0
    $script:LoadingLabel.Text = $Text + '...'
    if ($script:LoadingCard) {
        $script:LoadingCard.Left = [int][math]::Max(0, ($script:LoadingPanel.ClientSize.Width - $script:LoadingCard.Width) / 2)
        $script:LoadingCard.Top  = [int][math]::Max(0, ($script:LoadingPanel.ClientSize.Height - $script:LoadingCard.Height) / 2)
    }
    $script:LoadingPanel.BringToFront()
    $script:LoadingPanel.Visible = $true
    try { $script:LoadingTimer.Start() } catch { }
    [System.Windows.Forms.Application]::DoEvents()
}

function Hide-OptiLoading {
    if (-not $script:LoadingPanel) { return }
    $script:LoadingPanel.Visible = $false
    try { $script:LoadingTimer.Stop() } catch { }
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-OptiLoadingBounds {
    if (-not $script:LoadingPanel -or -not $Tabs) { return }
    $script:LoadingPanel.Location = $Tabs.Location
    $script:LoadingPanel.Size = $Tabs.Size
}

function Update-OptiLoadingDots {
    $script:LoadingDots++
    $n = ($script:LoadingDots % 3) + 1
    $script:LoadingLabel.Text = $script:LoadingText + ('.' * $n)
    if ($script:LoadingBar) { $script:LoadingBar.Value = 10 * (($script:LoadingDots % 10) + 1) }
    Update-OptiLoadingBounds
    if ($script:LoadingCard) {
        $script:LoadingCard.Left = [int][math]::Max(0, ($script:LoadingPanel.ClientSize.Width - $script:LoadingCard.Width) / 2)
        $script:LoadingCard.Top  = [int][math]::Max(0, ($script:LoadingPanel.ClientSize.Height - $script:LoadingCard.Height) / 2)
    }
}

# ------------------------------------------------- module: registry ----------
function Save-OptiRegistrySnapshot {
    $snap = @{}
    foreach ($t in $script:Tweaks) {
        $exists = Test-Path -LiteralPath $t.Path
        $val = $null
        if ($exists) {
            $p = Get-ItemProperty -LiteralPath $t.Path -Name $t.Name -ErrorAction SilentlyContinue
            if ($p) { $val = $p.$($t.Name) }
        }
        $snap[$t.Id] = [pscustomobject]@{ Existed = ($null -ne $val); Value = $val }
    }
    return $snap
}

function Apply-OptiRegistryTweaks {
    foreach ($t in $script:Tweaks) {
        if (-not $script:TweakEnabled[$t.Id]) { continue }
        if (-not (Test-Path -LiteralPath $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
        New-ItemProperty -LiteralPath $t.Path -Name $t.Name -Value $t.Value -PropertyType DWord -Force | Out-Null
    }
}

function Restore-OptiRegistrySnapshot {
    param($Snapshot)
    foreach ($t in $script:Tweaks) {
        $s = $Snapshot.$($t.Id)
        if (-not $s) { continue }
        if (-not (Test-Path -LiteralPath $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
        if ($s.Existed -and $null -ne $s.Value) {
            Set-ItemProperty -LiteralPath $t.Path -Name $t.Name -Value $s.Value -ErrorAction SilentlyContinue
        } elseif (-not $s.Existed) {
            Remove-ItemProperty -LiteralPath $t.Path -Name $t.Name -ErrorAction SilentlyContinue
        }
    }
}

# ------------------------------------------------- module: backup ------------
function New-OptiBackup {
    $snap = [ordered]@{ Created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); Services = @(); Registry = @{} }
    $cim = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue
    $snap.Services = @($cim | ForEach-Object { [pscustomobject]@{ Name = $_.Name; DisplayName = $_.DisplayName; StartMode = $_.StartMode; State = $_.State } })
    $snap.Registry = Save-OptiRegistrySnapshot
    if (-not (Test-Path -LiteralPath $script:BackupDir)) { New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null }
    $file = Join-Path $script:BackupDir ('backup-' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.json')
    $snap | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $file -Encoding UTF8
    Write-OptiStatus ('Backup tersimpan: ' + (Split-Path -Leaf $file))
    return $file
}

function New-OptiAutoBackup {
    try {
        $f = New-OptiBackup
        Write-OptiStatus ('Backup otomatis dibuat: ' + (Split-Path -Leaf $f))
        return $f
    } catch {
        Write-OptiStatus 'Backup otomatis gagal dibuat.'
        return $null
    }
}

function Get-OptiBackupFiles {
    Get-ChildItem -LiteralPath $script:BackupDir -Filter '*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | ForEach-Object { $_.FullName }
}

function Restore-OptiBackup {
    param([string]$File)
    $data = Get-Content -Raw -LiteralPath $File | ConvertFrom-Json
    if (-not $data) { throw 'Backup tidak valid.' }

    $ok = 0; $fail = @()
    foreach ($s in @($data.Services)) {
        $sc = switch ($s.StartMode) {
            'Automatic' { 'auto' }
            'AutomaticDelayedStart' { 'delayed-auto' }
            'Manual'    { 'demand' }
            'Disabled'  { 'disabled' }
            default { $null }
        }
        if ($sc) {
            & sc.exe config $s.Name start= $sc 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $ok++ } else { $fail += $s.Name }
        }
    }

    if ($data.Registry) {
        foreach ($t in $script:Tweaks) {
            $s = $data.Registry.$($t.Id)
            if (-not $s) { continue }
            if (-not (Test-Path -LiteralPath $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
            if ($s.Existed -and $null -ne $s.Value) {
                Set-ItemProperty -LiteralPath $t.Path -Name $t.Name -Value $s.Value -ErrorAction SilentlyContinue
            } elseif (-not $s.Existed) {
                Remove-ItemProperty -LiteralPath $t.Path -Name $t.Name -ErrorAction SilentlyContinue
            }
        }
    }

    return [pscustomobject]@{ ServicesOk = $ok; ServicesFail = $fail.Count; File = $File }
}

# ------------------------------------------------- module: layanan -----------
function Get-OptiServiceStartModes {
    $map = @{}
    Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue | ForEach-Object { $map[$_.Name] = $_.StartMode }
    return $map
}

function Refresh-OptiServiceGrid {
    Show-OptiLoading -Text 'Muat ulang daftar layanan...'
    try {
        Write-OptiStatus 'Muat ulang daftar layanan...'
        $script:ServiceTable.Rows.Clear()
        $modeMap = Get-OptiServiceStartModes
        $all = Get-Service -ErrorAction SilentlyContinue | Sort-Object DisplayName

        foreach ($svc in $all) {
            $row = $script:ServiceTable.NewRow()
            $isRecommended = ($script:UselessNames -contains $svc.Name) -and ($svc.Name -ne 'WSearch')
            $row['Pilih']    = $isRecommended
            $row['Layanan']  = $svc.Name
            $row['Tampilan'] = $svc.DisplayName
            $row['Status']   = if ($svc.Status -eq 'Running') { 'Jalan' } else { 'Berhenti' }
            $row['Startup']  = if ($modeMap.ContainsKey($svc.Name)) { $modeMap[$svc.Name] } else { '?' }
            $row['Catatan']  = if ($script:UselessMap.ContainsKey($svc.Name)) { $script:UselessMap[$svc.Name].Note } else { 'Layanan standar Windows' }
            $script:ServiceTable.Rows.Add($row) | Out-Null
        }

        $script:ServiceGrid.DataSource = $null
        $script:ServiceGrid.DataSource = $script:ServiceTable
        foreach ($c in $script:ServiceGrid.Columns) {
            $c.HeaderCell.Style.BackColor = $script:HeaderGrid
            $c.HeaderCell.Style.ForeColor = [System.Drawing.Color]::White
            $c.HeaderCell.Style.Font = Get-OptiFont -Size 9.5 -Style Bold
            $c.HeaderCell.Style.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleLeft
            $c.DefaultCellStyle.Font = Get-OptiFont -Size 9.5
            if ($c.Name -ne 'Pilih') { $c.ReadOnly = $true }
            if ($c.Name -eq 'Layanan')    { $c.AutoSizeMode = 'None'; $c.Width = 190 }
            if ($c.Name -eq 'Tampilan')   { $c.AutoSizeMode = 'None'; $c.Width = 260 }
            if ($c.Name -eq 'Status')     { $c.AutoSizeMode = 'None'; $c.Width = 70 }
            if ($c.Name -eq 'Startup')    { $c.AutoSizeMode = 'None'; $c.Width = 90 }
            if ($c.Name -eq 'Pilih')      { $c.AutoSizeMode = 'None'; $c.Width = 50 }
        }
        if ($script:ServiceGrid.Columns.Contains('Catatan')) {
            $script:ServiceGrid.Columns['Catatan'].AutoSizeMode = 'Fill'
        }
        Write-OptiStatus ('Ditemukan ' + $script:ServiceTable.Rows.Count + ' layanan. Centang yang ingin dimatikan.')
    } finally {
        Hide-OptiLoading
    }
}

function Get-OptiCheckedServices {
    $names = @()
    foreach ($row in $script:ServiceTable.Rows) {
        if ([bool]$row['Pilih']) { $names += [string]$row['Layanan'] }
    }
    return $names
}

function Set-OptiServiceModes {
    param([string]$Mode)
    $names = Get-OptiCheckedServices
    if ($names.Count -eq 0) {
        Show-OptiMsg 'Tidak ada layanan yang dicentang. Centang dulu layanan yang ingin diubah.' 'Opti - Layanan' 'Warn'
        return
    }

    $modeText = switch ($Mode) {
        'Disabled'  { 'NONAKTIFKAN' }
        'Manual'    { 'set MANUAL' }
        'Automatic' { 'set OTOMATIS' }
    }
    if (-not (Confirm-OptiMsg ("Ubah " + $names.Count + " layanan menjadi " + $modeText + "?`nBackup otomatis dibuat lebih dulu."))) { return }

    $backupFile = New-OptiBackup
    $map = @{ 'Automatic' = 'auto'; 'AutomaticDelayedStart' = 'delayed-auto'; 'Manual' = 'demand'; 'Disabled' = 'disabled' }
    $sc = $map[$Mode]

    Show-OptiLoading -Text 'Menerapkan layanan...'
    try {
        $done = 0; $fail = @()
        for ($i = 0; $i -lt $names.Count; $i++) {
            $n = $names[$i]
            Write-OptiStatus ("Menerapkan " + $modeText + " : " + $n + " (" + ($i + 1) + "/" + $names.Count + ")")
            & sc.exe config $n start= $sc 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $done++
                if ($Mode -eq 'Disabled') { Stop-Service -Name $n -Force -ErrorAction SilentlyContinue }
            } else {
                $fail += $n
            }
        }
    } finally {
        Hide-OptiLoading
    }

    Refresh-OptiServiceGrid
    $msg = "Berhasil: $done layanan di-" + $modeText + "."
    if ($fail.Count -gt 0) { $msg += "`nGagal: " + ($fail -join ', ') }
    if ($fail.Count -gt 0 -and $fail.Count -eq $names.Count) {
        $msg += "`nSemua gagal - pastikan Opti dijalankan sebagai Administrator."
    }
    $msg += "`nBackup: " + (Split-Path -Leaf $backupFile)
    Show-OptiMsg $msg 'Opti - Layanan'
}

# ------------------------------------------------- module: cache & temp ------
function Get-OptiCacheFolders {
    param([scriptblock]$OnFound)
    $roots = @($env:LOCALAPPDATA, $env:APPDATA, $env:TEMP, 'C:\ProgramData', (Join-Path $env:SystemRoot 'Temp')) |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    $found = @()
    foreach ($root in $roots) {
        if ($script:CancelScan) { break }
        Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue -Depth 8 |
            Where-Object { $_.Name -match 'cache' -and $_.FullName -notmatch '\$Recycle.Bin|System Volume Information|WinSxS|node_modules' } |
            ForEach-Object {
                if ($script:CancelScan) { return }
                $found += $_
                if ($OnFound) { & $OnFound $_ }
            }
    }
    return $found
}

function Measure-OptiItem {
    param([string]$Path)
    $sum = Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
    if ($null -eq $sum -or $null -eq $sum.Sum) { return 0 }
    return $sum.Sum
}

function Clear-OptiFolder {
    param([string]$Path)
    $size = Measure-OptiItem -Path $Path
    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    return $size
}

function Scan-OptiCacheUi {
    $script:CancelScan = $false
    $script:CacheList.Items.Clear()
    Show-OptiLoading -Text 'Memindai folder cache...'
    try {
        Write-OptiStatus 'Memindai folder bernama *cache* ... (Klik "Batalkan Pindai" untuk berhenti)'

        $count = 0
        $seen = @{}
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $found = Get-OptiCacheFolders -OnFound {
            param($dir)
            if ($seen.ContainsKey($dir.FullName)) { return }
            $seen[$dir.FullName] = $true
            $count++
            $item = New-Object System.Windows.Forms.ListViewItem
            $item.Text = $dir.FullName
            [void]$item.SubItems.Add('')
            [void]$item.SubItems.Add('Ditemukan')
            $item.Tag = $dir.FullName
            $script:CacheList.Items.Add($item) | Out-Null
            if (($count % 40) -eq 0) { Write-OptiStatus ("Memindai... $count folder ditemukan (" + [math]::Round($sw.Elapsed.TotalSeconds) + " dtk)"); [System.Windows.Forms.Application]::DoEvents() }
        }
        $sw.Stop()

        if ($script:CancelScan) {
            Write-OptiStatus ('Pemindaian dibatalkan pada ' + $script:CacheList.Items.Count + ' folder.')
        } else {
            Write-OptiStatus ('Selesai. Ditemukan ' + $script:CacheList.Items.Count + ' folder cache dalam ' + [math]::Round($sw.Elapsed.TotalSeconds) + ' detik.')
        }
    } finally {
        Hide-OptiLoading
    }
}

function Delete-OptiCacheUi {
    $all = @($script:CacheList.Items | ForEach-Object { $_.Tag })
    $selected = @($script:CacheList.SelectedItems | ForEach-Object { $_.Tag })
    $targets = @($(if ($selected.Count -gt 0) { $selected } else { $all }) | Select-Object -Unique)

    if ($targets.Count -eq 0) { Show-OptiMsg 'Folder cache belum dipindai.' 'Opti - Cache' 'Warn'; return }
    if (-not (Confirm-OptiMsg ("Hapus ISI dari " + $targets.Count + " folder cache?`n(Folder itu sendiri TIDAK dihapus. File yang sedang dipakai dilewati.)"))) { return }

    Show-OptiLoading -Text 'Menghapus cache...'
    try {
        $total = 0L; $done = 0; $skip = 0
        for ($i = 0; $i -lt $targets.Count; $i++) {
            $path = $targets[$i]
            Write-OptiStatus ("Membersihkan " + (Split-Path -Leaf $path) + " (" + ($i + 1) + "/" + $targets.Count + ")")
            Set-OptiProgress -Value ($i + 1) -Max $targets.Count
            $freed = 0L
            if (Test-Path -LiteralPath $path) {
                $freed = Clear-OptiFolder -Path $path
                $total += $freed
                $done++
            } else {
                $skip++
            }
            foreach ($li2 in @($script:CacheList.Items | Where-Object { $_.Tag -eq $path })) {
                $li2.SubItems[1].Text = [math]::Round($freed / 1MB, 2)
                $li2.SubItems[2].Text = if ((Test-Path -LiteralPath $path)) { 'Dibersihkan' } else { 'Tidak Ada' }
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
    } finally {
        Hide-OptiLoading
        Set-OptiProgress -Value 0 -Max 100
    }
    New-OptiAutoBackup | Out-Null
    Write-OptiStatus 'Pembersihan cache selesai.'
    Show-OptiMsg ("Cache dibersihkan: $done folder (dilewati: $skip).`nTotal dibebaskan: ~" + [math]::Round($total / 1MB, 1) + " MB.") 'Opti - Cache'
}

# ------------------------------------------------- module: RAM --------------
function Get-OptiRamInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $totalGB = 0; $freeGB = 0; $usedGB = 0
    if ($os) {
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $usedGB  = [math]::Round($totalGB - $freeGB, 1)
    }

    $standbyMB = 0
    try {
        $c = (Get-Counter '\Memory\Standby Cache Normal Priority Bytes' -ErrorAction Stop).CounterSamples[0].CookedValue
        $standbyMB = [math]::Round($c / 1MB, 0)
    } catch { }

    return [pscustomobject]@{ Total = $totalGB; Free = $freeGB; Used = $usedGB; StandbyMB = $standbyMB }
}

function Refresh-OptiRamInfo {
    $i = Get-OptiRamInfo
    $script:lblRamTotal.Text   = 'Total RAM : ' + $i.Total + ' GB'
    $script:lblRamUsed.Text    = 'Terpakai : ' + $i.Used + ' GB'
    $script:lblRamFree.Text    = 'Tersedia : ' + $i.Free + ' GB'
    $script:lblRamStandby.Text = 'Standby List : ' + $i.StandbyMB + ' MB'
    Write-OptiStatus 'Info RAM diperbarui.'
}

function Clear-OptiRamStandby {
    if (-not $script:IsAdmin) { Show-OptiMsg 'Operasi ini butuh Administrator.' 'Opti - RAM' 'Warn'; return }
    Show-OptiLoading -Text 'Mengosongkan RAM...'
    try {
        if (-not $script:NativeLoadError) {
            $r = [OptiRam.Native]::EmptyStandby()
            if ($r -ne 0) {
                $u = $r -band 0xFFFFFFFF
                $code0 = '0x' + ('{0:X8}' -f $u)
                $d = [OptiRam.Native]::Diagnose()
                Show-OptiMsg ('Gagal mengosongkan standby list. Kode: ' + $code0 + "`nDiagnostik: " + $d + "`nPastikan Opti dijalankan sebagai Administrator.") 'Opti - RAM' 'Err'
            } else {
                Show-OptiMsg 'Standby list (RAM cache) telah dikosongkan.' 'Opti - RAM'
            }
        } else {
            Show-OptiMsg ("Komponen RAM gagal dimuat: $script:NativeLoadError" ) 'Opti - RAM' 'Err'
        }
        New-OptiAutoBackup | Out-Null
    } finally {
        Hide-OptiLoading
    }
    Start-Sleep -Milliseconds 300
    Refresh-OptiRamInfo
}

function Clear-OptiRamStandbyAndModified {
    if (-not $script:IsAdmin) { Show-OptiMsg 'Operasi ini butuh Administrator.' 'Opti - RAM' 'Warn'; return }
    Show-OptiLoading -Text 'Mengosongkan RAM...'
    try {
        if (-not $script:NativeLoadError) {
            $r = [OptiRam.Native]::EmptyStandbyAndModified()
            if ($r -ne 0) {
                $u = $r -band 0xFFFFFFFF
                $code1 = '0x' + ('{0:X8}' -f $u)
                $d = [OptiRam.Native]::Diagnose()
                Show-OptiMsg ('Gagal. Kode: ' + $code1 + "`nDiagnostik: " + $d + "`nPastikan Opti dijalankan sebagai Administrator.") 'Opti - RAM' 'Err'
            } else {
                Show-OptiMsg 'Standby list & modified page list dikosongkan.' 'Opti - RAM'
            }
        } else {
            Show-OptiMsg ("Komponen RAM gagal dimuat: $script:NativeLoadError" ) 'Opti - RAM' 'Err'
        }
        New-OptiAutoBackup | Out-Null
    } finally {
        Hide-OptiLoading
    }
    Start-Sleep -Milliseconds 300
    Refresh-OptiRamInfo
}

# --------------------------------------------------------------- theme -----
$script:AccentColor = [System.Drawing.Color]::FromArgb(0, 108, 216)
$script:AccentDark  = [System.Drawing.Color]::FromArgb(13, 84, 168)
$script:HeaderBack  = [System.Drawing.Color]::FromArgb(20, 28, 44)
$script:PageBack    = [System.Drawing.Color]::White
$script:BorderColor = [System.Drawing.Color]::FromArgb(226, 230, 236)
$script:AltRowColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$script:TextPrimary = [System.Drawing.Color]::FromArgb(36, 41, 47)
$script:TextMuted   = [System.Drawing.Color]::FromArgb(110, 118, 128)
$script:HeaderGrid  = [System.Drawing.Color]::FromArgb(35, 47, 64)
$script:DangerColor = [System.Drawing.Color]::FromArgb(202, 44, 52)

function Get-OptiFont {
    param([single]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
    try {
        if ([System.Drawing.FontFamily]::Families.Name -contains 'Segoe UI Variable Text') {
            return New-Object System.Drawing.Font('Segoe UI Variable Text', $Size, $Style)
        }
        return New-Object System.Drawing.Font('Segoe UI', $Size, $Style)
    } catch { return New-Object System.Drawing.Font('Segoe UI', $Size, $Style) }
}

function Set-OptiButtonTheme {
    param([System.Windows.Forms.Button]$Button, [string]$Kind = 'Normal')
    $Button.FlatStyle = 'Flat'
    $Button.UseVisualStyleBackColor = $false
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.Font = Get-OptiFont -Size 9.5
    switch ($Kind) {
        'Primary' {
            $Button.BackColor = $script:AccentColor
            $Button.ForeColor = [System.Drawing.Color]::White
            $Button.FlatAppearance.BorderColor = $script:AccentColor
            $Button.FlatAppearance.MouseOverBackColor = $script:AccentDark
            $Button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(8, 74, 150)
        }
        'Danger' {
            $Button.BackColor = $script:DangerColor
            $Button.ForeColor = [System.Drawing.Color]::White
            $Button.FlatAppearance.BorderColor = $script:DangerColor
            $Button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(174, 32, 40)
            $Button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(140, 24, 32)
        }
        default {
            $Button.BackColor = $script:PageBack
            $Button.ForeColor = $script:TextPrimary
            $Button.FlatAppearance.BorderColor = $script:BorderColor
            $Button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(231, 240, 250)
            $Button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(205, 224, 243)
        }
    }
}

$script:PrimaryBtn = @('MATIKAN yang Dicentang', 'Terapkan Optimasi Terpilih', 'Restore Backup Terpilih', 'Buat Backup Sekarang', 'Kosongkan Standby List (RAM cache)')
$script:DangerBtn = @('Hapus Isi Folder Cache', 'Bersihkan Recycle Bin', 'Kosongkan Standby + Modified Page List')

function Apply-OptiTheme {
    param([System.Windows.Forms.Control]$Control)
    foreach ($ctrl in $Control.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $kind = 'Normal'
            if ($script:PrimaryBtn -contains $ctrl.Text) { $kind = 'Primary' }
            elseif ($script:DangerBtn -contains $ctrl.Text) { $kind = 'Danger' }
            Set-OptiButtonTheme -Button $ctrl -Kind $kind
        } elseif ($ctrl -is [System.Windows.Forms.CheckBox]) {
            $ctrl.FlatStyle = 'Flat'
            $ctrl.Font = Get-OptiFont -Size 9.5
        }
        if ($ctrl.HasChildren) { Apply-OptiTheme -Control $ctrl }
    }
}

$script:brushActive    = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$script:brushInactive  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 238, 242))
$script:brushAccent    = New-Object System.Drawing.SolidBrush($script:AccentColor)
$script:brushTextDark  = New-Object System.Drawing.SolidBrush($script:TextPrimary)
$script:brushTextMuted = New-Object System.Drawing.SolidBrush($script:TextMuted)
$script:fontTab        = Get-OptiFont -Size 10 -Style Bold
$script:fontTabInact   = Get-OptiFont -Size 10
$script:sfCenter = New-Object System.Drawing.StringFormat
$script:sfCenter.Alignment = [System.Drawing.StringAlignment]::Center
$script:sfCenter.LineAlignment = [System.Drawing.StringAlignment]::Center

# =================================================================== UI =====
# ------------------------------------------------------------ terms form -----
function Show-OptiTerms {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'Opti - Persetujuan & Kebijakan'
    $f.Size = New-Object System.Drawing.Size(880, 680)
    $f.StartPosition = 'CenterScreen'
    $f.MaximizeBox = $false
    $f.FormBorderStyle = 'FixedDialog'

    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Location = New-Object System.Drawing.Point(12, 12)
    $rtb.Size = New-Object System.Drawing.Size(840, 560)
    $rtb.ReadOnly = $true
    $rtb.ScrollBars = 'Vertical'
    $rtb.BackColor = [System.Drawing.Color]::White
    $rtb.Text = $script:TermsText

    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = 'TIDAK SETUJU (Keluar)'
    $btnNo.Location = New-Object System.Drawing.Point(12, 590)
    $btnNo.Size = New-Object System.Drawing.Size(210, 40)

    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = 'SETUJU, LANJUTKAN'
    $btnYes.Location = New-Object System.Drawing.Point(642, 590)
    $btnYes.Size = New-Object System.Drawing.Size(210, 40)

    $script:Agreed = $false
    $btnYes.Add_Click({ $script:Agreed = $true; $f.Close() })
    $btnNo.Add_Click({ $script:Agreed = $false; $f.Close() })

    $f.Controls.Add($rtb)
    $f.Controls.Add($btnNo)
    $f.Controls.Add($btnYes)
    $f.ShowDialog() | Out-Null
    return $script:Agreed
}

# ------------------------------------------------------------ main form ------
$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'Opti - Optimalisasi Kinerja PC  v' + $script:Version
$Form.Size = New-Object System.Drawing.Size(1030, 730)
$Form.StartPosition = 'CenterScreen'
$Form.MinimumSize = New-Object System.Drawing.Size(980, 660)
$Form.BackColor = $script:PageBack
$Form.Font = Get-OptiFont -Size 9

$Layout = New-Object System.Windows.Forms.TableLayoutPanel
$Layout.Dock = 'Fill'
$Layout.ColumnCount = 1
$Layout.RowCount = 3
$Layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 64)))
$Layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$Layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 38)))
$Form.Controls.Add($Layout)

# --- header
$Header = New-Object System.Windows.Forms.Panel
$Header.Dock = 'Fill'
$Header.BackColor = $script:HeaderBack

$Title = New-Object System.Windows.Forms.Label
$Title.Text = '  OPTI  -  Optimalisasi Kinerja PC'
$Title.Font = Get-OptiFont -Size 15 -Style Bold
$Title.ForeColor = [System.Drawing.Color]::White
$Title.AutoSize = $true
$Title.Location = New-Object System.Drawing.Point(14, 10)

$Subtitle = New-Object System.Windows.Forms.Label
$Subtitle.Text = 'Matikan fitur useless, hapus cache & kosongkan RAM. Semua perubahan bisa di-restore.'
$Subtitle.Font = Get-OptiFont -Size 9
$Subtitle.ForeColor = [System.Drawing.Color]::FromArgb(176, 184, 196)
$Subtitle.AutoSize = $true
$Subtitle.Location = New-Object System.Drawing.Point(16, 38)

$HeaderAccent = New-Object System.Windows.Forms.Panel
$HeaderAccent.Dock = 'Bottom'
$HeaderAccent.Height = 3
$HeaderAccent.BackColor = $script:AccentColor

$lblDev = New-Object System.Windows.Forms.LinkLabel
$lblDev.AutoSize = $true
$lblDev.Anchor = 'Top, Right'
$lblDev.Font = Get-OptiFont -Size 9
$lblDev.ForeColor = [System.Drawing.Color]::FromArgb(176, 184, 196)
$lblDev.ActiveLinkColor = [System.Drawing.Color]::White
$lblDev.LinkColor = [System.Drawing.Color]::FromArgb(120, 180, 255)
$lblDev.Text = '(c) H.MP Dev  |  hmp.my.id'
$lblDev.Location = New-Object System.Drawing.Point(790, 22)
$lblDev.Add_Click({ Start-Process 'https://hmp.my.id' })

$Header.Controls.Add($Title)
$Header.Controls.Add($Subtitle)
$Header.Controls.Add($HeaderAccent)
$Header.Controls.Add($lblDev)

# --- tab control
$Tabs = New-Object System.Windows.Forms.TabControl
$Tabs.Dock = 'Fill'
$Tabs.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$Tabs.DrawMode = 'OwnerDrawFixed'
$Tabs.ItemSize = New-Object System.Drawing.Size(178, 44)
$Tabs.Padding = New-Object System.Drawing.Point(16, 6)
$Tabs.HotTrack = $false
$Tabs.BackColor = [System.Drawing.Color]::FromArgb(238, 241, 245)
$Tabs.Add_DrawItem({
    param($sender, $e)
    $g = $e.Graphics
    $r = $e.Bounds
    if ($e.Index -eq $sender.SelectedIndex) {
        $g.FillRectangle($script:brushActive, $r.X, $r.Y, $r.Width, $r.Height)
        $g.FillRectangle($script:brushAccent, $r.X, ($r.Bottom - 3), $r.Width, 3)
        $g.DrawString($sender.TabPages[$e.Index].Text, $script:fontTab, $script:brushTextDark, [System.Drawing.RectangleF]$r, $script:sfCenter)
    } else {
        $g.FillRectangle($script:brushInactive, $r.X, $r.Y, $r.Width, $r.Height)
        $g.DrawString($sender.TabPages[$e.Index].Text, $script:fontTabInact, $script:brushTextMuted, [System.Drawing.RectangleF]$r, $script:sfCenter)
    }
})

# ===== TAB 1 : LAYANAN & FITUR =====
$TabServices = New-Object System.Windows.Forms.TabPage
$TabServices.Text = 'Layanan & Fitur (Useless)'

$script:ServiceGrid = New-Object System.Windows.Forms.DataGridView
$script:ServiceGrid.AllowUserToAddRows = $false
$script:ServiceGrid.AllowUserToDeleteRows = $false
$script:ServiceGrid.MultiSelect = $false
$script:ServiceGrid.SelectionMode = 'FullRowSelect'
$script:ServiceGrid.RowHeadersVisible = $false
$script:ServiceGrid.AutoSizeColumnsMode = 'Fill'
# saat checkbox di-klik, tulis nilai langsung ke DataTable (kalau tidak,
# Get-OptiCheckedServices akan selalu membaca 0)
$script:ServiceGrid.Add_CurrentCellDirtyStateChanged({
    if ($script:ServiceGrid.IsCurrentCellDirty) {
        [void]$script:ServiceGrid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit)
    }
})
$script:ServiceGrid.BorderStyle = 'None'
$script:ServiceGrid.CellBorderStyle = 'SingleHorizontal'
$script:ServiceGrid.BackgroundColor = $script:PageBack
$script:ServiceGrid.GridColor = [System.Drawing.Color]::FromArgb(228, 232, 238)
$script:ServiceGrid.EnableHeadersVisualStyles = $false
$script:ServiceGrid.ColumnHeadersHeight = 42
$script:ServiceGrid.RowTemplate.Height = 32
$script:ServiceGrid.DefaultCellStyle.BackColor = $script:PageBack
$script:ServiceGrid.DefaultCellStyle.ForeColor = $script:TextPrimary
$script:ServiceGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(198, 222, 246)
$script:ServiceGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::FromArgb(16, 40, 66)
$script:ServiceGrid.AlternatingRowsDefaultCellStyle.BackColor = $script:AltRowColor

$script:ServiceTable = New-Object System.Data.DataTable 'Layanan'
[void]$script:ServiceTable.Columns.Add('Pilih',   [bool])
[void]$script:ServiceTable.Columns.Add('Layanan', [string])
[void]$script:ServiceTable.Columns.Add('Tampilan',[string])
[void]$script:ServiceTable.Columns.Add('Status',  [string])
[void]$script:ServiceTable.Columns.Add('Startup', [string])
[void]$script:ServiceTable.Columns.Add('Catatan', [string])

$SvcPanel = New-Object System.Windows.Forms.Panel
$SvcPanel.Dock = 'Fill'
$SvcPanel.BackColor = $script:PageBack
$script:ServiceGrid.Dock = 'Fill'

$SvcBtnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$SvcBtnPanel.Dock = 'Bottom'
$SvcBtnPanel.Height = 44
$SvcBtnPanel.FlowDirection = 'LeftToRight'
$SvcBtnPanel.BackColor = $script:PageBack
$SvcBtnPanel.Padding = New-Object System.Windows.Forms.Padding(4)

function New-ActionButton {
    param([string]$Text, [int]$Width, [scriptblock]$Click)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Width = $Width
    $b.Height = 30
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Font = Get-OptiFont -Size 9.5
    if ($Click) { $b.Add_Click($Click) }
    $b
}

function New-OptiInfoLabel {
    param([string]$Caption)
    $l = New-Object System.Windows.Forms.Label
    $l.AutoSize = $true
    $l.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $l.Text = $Caption + ' : ...'
    $l.Padding = New-Object System.Windows.Forms.Padding(4)
    $l
}

$btnSvcDisable = New-ActionButton -Text 'MATIKAN yang Dicentang' -Width 200 -Click {
    try { Set-OptiServiceModes -Mode 'Disabled' } catch { Show-OptiMsg $_.Exception.Message 'Error' 'Err' }
}
$btnSvcManual = New-ActionButton -Text 'Set Manual' -Width 100 -Click {
    try { Set-OptiServiceModes -Mode 'Manual' } catch { Show-OptiMsg $_.Exception.Message 'Error' 'Err' }
}
$btnSvcAuto = New-ActionButton -Text 'Set Otomatis' -Width 110 -Click {
    try { Set-OptiServiceModes -Mode 'Automatic' } catch { Show-OptiMsg $_.Exception.Message 'Error' 'Err' }
}
$btnSvcRecomm = New-ActionButton -Text 'Centang Semua Rekomendasi' -Width 200 -Click {
    foreach ($row in $script:ServiceTable.Rows) {
        $row['Pilih'] = ($script:UselessNames -contains [string]$row['Layanan']) -and ([string]$row['Layanan'] -ne 'WSearch')
    }
}
$btnSvcClear = New-ActionButton -Text 'Bersihkan Centang' -Width 140 -Click {
    foreach ($row in $script:ServiceTable.Rows) { $row['Pilih'] = $false }
}
$btnSvcRefresh = New-ActionButton -Text 'Refresh Daftar' -Width 120 -Click {
    try { Refresh-OptiServiceGrid } catch { Show-OptiMsg $_.Exception.Message 'Error' 'Err' }
}

$SvcNote = New-Object System.Windows.Forms.Label
$SvcNote.Dock = 'Bottom'
$SvcNote.AutoSize = $true
$SvcNote.Font = Get-OptiFont -Size 8.5
$SvcNote.ForeColor = $script:TextMuted
$SvcNote.Padding = New-Object System.Windows.Forms.Padding(4, 2, 0, 2)
$SvcNote.Text = 'Status "Startup": Otomatis = auto / Manual = demand / Nonaktif = disabled.  Centang layanan lalu klik "MATIKAN yang Dicentang". Layanan wajib (audio, jaringan, update) jangan dimatikan.'

$SvcBtnPanel.Controls.Add($btnSvcDisable)
$SvcBtnPanel.Controls.Add($btnSvcManual)
$SvcBtnPanel.Controls.Add($btnSvcAuto)
$SvcBtnPanel.Controls.Add($btnSvcRecomm)
$SvcBtnPanel.Controls.Add($btnSvcClear)
$SvcBtnPanel.Controls.Add($btnSvcRefresh)

$SvcPanel.Controls.Add($script:ServiceGrid)
$SvcPanel.Controls.Add($SvcBtnPanel)
$SvcPanel.Controls.Add($SvcNote)
$TabServices.Controls.Add($SvcPanel)
$Tabs.TabPages.Add($TabServices)

# ===== TAB 2 : OPTIMASI CEPAT (REGISTRY) =====
$TabQuick = New-Object System.Windows.Forms.TabPage
$TabQuick.Text = 'Optimasi Cepat (Registry)'

$QuickPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$QuickPanel.Dock = 'Fill'
$QuickPanel.FlowDirection = 'TopDown'
$QuickPanel.WrapContents = $false
$QuickPanel.AutoScroll = $true
$QuickPanel.BackColor = $script:PageBack
$QuickPanel.Padding = New-Object System.Windows.Forms.Padding(10)

$QuickHeader = New-Object System.Windows.Forms.Label
$QuickHeader.AutoSize = $true
$QuickHeader.Font = Get-OptiFont -Size 12 -Style Bold
$QuickHeader.ForeColor = $script:TextPrimary
$QuickHeader.Text = 'Optimasi Cepat via Registry (pilih yang ingin diterapkan)'
$QuickPanel.Controls.Add($QuickHeader)

# add tweak checkboxes
$QuickCheckboxes = @{}
foreach ($t in $script:Tweaks) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $t.Label
    $cb.Tag = $t.Id
    $cb.AutoSize = $true
    $cb.Width = 700
    $cb.Checked = $false
    $cb.Add_CheckedChanged({
        $id = $this.Tag
        $script:TweakEnabled[$id] = $this.Checked
    })
    $QuickCheckboxes[$t.Id] = $cb
    $QuickPanel.Controls.Add($cb)
}

$QuickSep = New-Object System.Windows.Forms.Label
$QuickSep.AutoSize = $true
$QuickSep.Text = 'Catatan: kunci registry tentang telemetri/iklan aman. "Visual FX" butuh login ulang. Backup otomatis dibuat sebelum menerapkan.'
$QuickSep.ForeColor = [System.Drawing.Color]::DimGray
$QuickPanel.Controls.Add($QuickSep)

function New-QuickButton {
    param([string]$Text, [int]$Width, [scriptblock]$Click)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Width = $Width
    $b.Height = 34
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Font = Get-OptiFont -Size 9.5
    if ($Click) { $b.Add_Click($Click) }
    $b
}

$btnQuickApply = New-QuickButton -Text 'Terapkan Optimasi Terpilih' -Width 240 -Click {
    $any = @($script:Tweaks | Where-Object { $script:TweakEnabled[$_.Id] }).Count
    if ($any -eq 0) { Show-OptiMsg 'Belum ada tweak yang dicentang.' 'Opti - Optimasi' 'Warn'; return }
    if (-not (Confirm-OptiMsg ("Terapkan $any pengaturan registry? Backup otomatis dibuat lebih dulu."))) { return }
    Show-OptiLoading -Text 'Menerapkan optimasi registry...'
    try {
        New-OptiBackup | Out-Null
        Apply-OptiRegistryTweaks
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Optimasi' 'Err'; return } finally { Hide-OptiLoading }
    Show-OptiMsg ("$any pengaturan registry diterapkan.`nRestart beberapa kali untuk efek penuh.") 'Opti - Optimasi'
}
$btnQuickRestore = New-QuickButton -Text 'Kembalikan dari Backup Terakhir' -Width 260 -Click {
    $files = Get-OptiBackupFiles
    if ($files.Count -eq 0) { Show-OptiMsg 'Belum ada backup.' 'Opti - Optimasi' 'Warn'; return }
    if (-not (Confirm-OptiMsg 'Kembalikan pengaturan registry sesuai backup terakhir?')) { return }
    Show-OptiLoading -Text 'Mengembalikan registry...'
    try {
        $data = Get-Content -Raw -LiteralPath $files[0] | ConvertFrom-Json
        if ($data.Registry) { Restore-OptiRegistrySnapshot -Snapshot $data.Registry }
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Optimasi' 'Err'; return } finally { Hide-OptiLoading }
    Show-OptiMsg 'Registry dikembalikan sesuai backup terakhir.' 'Opti - Optimasi'
}
$QuickPanel.Controls.Add($btnQuickApply)
$QuickPanel.Controls.Add($btnQuickRestore)
$TabQuick.Controls.Add($QuickPanel)
$Tabs.TabPages.Add($TabQuick)

# ===== TAB 3 : PEMBERSIH CACHE & TEMP =====
$TabCache = New-Object System.Windows.Forms.TabPage
$TabCache.Text = 'Bersihkan Cache & Temp'

$CachePanel = New-Object System.Windows.Forms.Panel
$CachePanel.Dock = 'Fill'
$CachePanel.BackColor = $script:PageBack

$CacheBtnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$CacheBtnPanel.Dock = 'Top'
$CacheBtnPanel.Height = 44
$CacheBtnPanel.Padding = New-Object System.Windows.Forms.Padding(4)
$CacheBtnPanel.BackColor = $script:PageBack

$script:CacheList = New-Object System.Windows.Forms.ListView
$script:CacheList.Dock = 'Fill'
$script:CacheList.View = 'Details'
$script:CacheList.FullRowSelect = $true
$script:CacheList.GridLines = $true
$script:CacheList.MultiSelect = $true
$script:CacheList.BackColor = [System.Drawing.Color]::White
$script:CacheList.ForeColor = $script:TextPrimary
$script:CacheList.Font = Get-OptiFont -Size 9.5
$script:CacheList.BorderStyle = 'None'
[void]$script:CacheList.Columns.Add('Folder', 620)
[void]$script:CacheList.Columns.Add('Ukuran (MB)', 100)
[void]$script:CacheList.Columns.Add('Status', 130)

$btnScan = New-ActionButton -Text 'Pindai Folder Cache' -Width 160 -Click { try { Scan-OptiCacheUi } catch { Show-OptiMsg $_.Exception.Message 'Opti - Cache' 'Err' } }
$btnScanCancel = New-ActionButton -Text 'Batalkan Pindai' -Width 120 -Click { $script:CancelScan = $true; Write-OptiStatus 'Pembatalan diminta...' }
$btnDelete = New-ActionButton -Text 'Hapus Isi Folder Cache' -Width 170 -Click { try { Delete-OptiCacheUi } catch { Show-OptiMsg $_.Exception.Message 'Opti - Cache' 'Err' } }
$btnTemp = New-ActionButton -Text 'Hapus Temp Windows' -Width 150 -Click {
    $total = 0L
    Show-OptiLoading -Text 'Menghapus Temp Windows...'
    try {
        foreach ($p in @($env:TEMP, (Join-Path $env:SystemRoot 'Temp'))) {
            if (Test-Path -LiteralPath $p) { $total += Clear-OptiFolder -Path $p }
        }
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Temp' 'Err'; return } finally { Hide-OptiLoading }
    New-OptiAutoBackup | Out-Null
    Show-OptiMsg ("Temp dibersihkan. Bebas: ~" + [math]::Round($total / 1MB, 1) + " MB.") 'Opti - Temp'
}
$btnPrefetch = New-ActionButton -Text 'Bersihkan Prefetch' -Width 140 -Click {
    $f = 0
    Show-OptiLoading -Text 'Membersihkan Prefetch...'
    try {
        $p = Join-Path $env:SystemRoot 'Prefetch'
        if (Test-Path -LiteralPath $p) { $f = Clear-OptiFolder -Path $p } else { $f = 0 }
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Prefetch' 'Err'; return } finally { Hide-OptiLoading }
    New-OptiAutoBackup | Out-Null
    Show-OptiMsg ("Prefetch dibersihkan. Bebas: ~" + [math]::Round($f / 1MB, 1) + " MB.") 'Opti - Prefetch'
}
$btnRecycle = New-ActionButton -Text 'Bersihkan Recycle Bin' -Width 170 -Click {
    if (-not (Confirm-OptiMsg 'Kosongkan Recycle Bin? Data di dalamnya akan hilang permanen.')) { return }
    Show-OptiLoading -Text 'Mengosongkan Recycle Bin...'
    try {
        Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Recycle Bin' 'Err'; return } finally { Hide-OptiLoading }
    New-OptiAutoBackup | Out-Null
    Show-OptiMsg 'Recycle Bin dikosongkan.' 'Opti - Recycle Bin'
}
$btnCacheOpen = New-ActionButton -Text 'Buka Folder Terpilih' -Width 150 -Click {
    $sel = @($script:CacheList.SelectedItems)
    if ($sel.Count -eq 0) { Show-OptiMsg 'Pilih folder cache dulu.' 'Opti - Cache' 'Warn'; return }
    Start-Process explorer.exe -ArgumentList $sel[0].Tag
}

$CacheBtnPanel.Controls.Add($btnScan)
$CacheBtnPanel.Controls.Add($btnScanCancel)
$CacheBtnPanel.Controls.Add($btnDelete)
$CacheBtnPanel.Controls.Add($btnTemp)
$CacheBtnPanel.Controls.Add($btnPrefetch)
$CacheBtnPanel.Controls.Add($btnRecycle)
$CacheBtnPanel.Controls.Add($btnCacheOpen)

$CacheNote = New-Object System.Windows.Forms.Label
$CacheNote.Dock = 'Bottom'
$CacheNote.AutoSize = $true
$CacheNote.Font = Get-OptiFont -Size 8.5
$CacheNote.ForeColor = $script:TextMuted
$CacheNote.Padding = New-Object System.Windows.Forms.Padding(4, 2, 0, 2)
$CacheNote.Text = 'Pemindai mencari SEMUA folder yang namanya mengandung "cache". Klik "Hapus Isi Folder Cache" untuk mengosongkan isinya (folder itu sendiri tetap ada; file yang dipakai proses dilewati).'

$CachePanel.Controls.Add($script:CacheList)
$CachePanel.Controls.Add($CacheBtnPanel)
$CachePanel.Controls.Add($CacheNote)
$TabCache.Controls.Add($CachePanel)
$Tabs.TabPages.Add($TabCache)

# ===== TAB 4 : RAM =====
$TabRam = New-Object System.Windows.Forms.TabPage
$TabRam.Text = 'RAM'

$RamPanel = New-Object System.Windows.Forms.Panel
$RamPanel.Dock = 'Fill'
$RamPanel.BackColor = $script:PageBack
$RamPanel.Padding = New-Object System.Windows.Forms.Padding(14)

function New-SectionLabel {
    param([string]$Text)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Font = Get-OptiFont -Size 12 -Style Bold
    $l.ForeColor = $script:TextPrimary
    $l.AutoSize = $true
    $l
}

$lblRamSection = New-SectionLabel 'Informasi Memori (RAM)'
$lblRamSection.Location = New-Object System.Drawing.Point(0, 0)
$RamPanel.Controls.Add($lblRamSection)

$infoGrid = New-Object System.Windows.Forms.TableLayoutPanel
$infoGrid.ColumnCount = 4
$infoGrid.RowCount = 2
$infoGrid.Location = New-Object System.Drawing.Point(6, 40)
$infoGrid.Size = New-Object System.Drawing.Size(580, 70)

$script:lblRamTotal = New-OptiInfoLabel 'Total RAM'
$script:lblRamUsed = New-OptiInfoLabel 'Terpakai'
$script:lblRamFree = New-OptiInfoLabel 'Tersedia'
$script:lblRamStandby = New-OptiInfoLabel 'Standby List'

$infoGrid.Controls.Add($script:lblRamTotal, 0, 0)
$infoGrid.Controls.Add($script:lblRamUsed, 1, 0)
$infoGrid.Controls.Add($script:lblRamFree, 2, 0)
$infoGrid.Controls.Add($script:lblRamStandby, 3, 0)
$RamPanel.Controls.Add($infoGrid)

$btnRamRefresh = New-ActionButton -Text 'Segarkan Info RAM' -Width 140 -Click { try { Refresh-OptiRamInfo } catch { Show-OptiMsg $_.Exception.Message 'Opti - RAM' 'Err' } }
$btnRamRefresh.Location = New-Object System.Drawing.Point(600, 42)
$RamPanel.Controls.Add($btnRamRefresh)

$lblRamOps = New-SectionLabel 'Operasi Pengosongan RAM'
$lblRamOps.Location = New-Object System.Drawing.Point(0, 120)
$RamPanel.Controls.Add($lblRamOps)

$btnRamStandby = New-ActionButton -Text 'Kosongkan Standby List (RAM cache)' -Width 260 -Click { try { Clear-OptiRamStandby } catch { Show-OptiMsg $_.Exception.Message 'Opti - RAM' 'Err' } }
$btnRamStandby.Location = New-Object System.Drawing.Point(6, 160)
$RamPanel.Controls.Add($btnRamStandby)

$btnRamAll = New-ActionButton -Text 'Kosongkan Standby + Modified Page List' -Width 300 -Click { try { Clear-OptiRamStandbyAndModified } catch { Show-OptiMsg $_.Exception.Message 'Opti - RAM' 'Err' } }
$btnRamAll.Location = New-Object System.Drawing.Point(280, 160)
$RamPanel.Controls.Add($btnRamAll)

$lblRamNote = New-Object System.Windows.Forms.Label
$lblRamNote.Location = New-Object System.Drawing.Point(6, 320)
$lblRamNote.Size = New-Object System.Drawing.Size(700, 140)
$lblRamNote.AutoSize = $false
$lblRamNote.TabStop = $false
$lblRamNote.Text = "Penjelasan:`n- Standby list: data file yang Windows simpan di RAM sebagai cache. Mengosongkannya membebaskan RAM tapi file akan dibaca ulang dari disk bila dibutuhkan (boleh dikosongkan saat main game / render berat).`n- Modified page list: halaman memori yang belum disimpan ke disk.`n- Kedua tombol membutuhkan hak Administrator untuk mengosongkan daftar memori via API sistem."
$RamPanel.Controls.Add($lblRamNote)
$TabRam.Controls.Add($RamPanel)
$Tabs.TabPages.Add($TabRam)

# ===== TAB 5 : BACKUP & RESTORE =====
$TabBackup = New-Object System.Windows.Forms.TabPage
$TabBackup.Text = 'Backup & Restore'

$BkPanel = New-Object System.Windows.Forms.Panel
$BkPanel.Dock = 'Fill'
$BkPanel.BackColor = $script:PageBack
$BkPanel.Padding = New-Object System.Windows.Forms.Padding(12)

$lblBkTitle = New-SectionLabel 'Backup & Restore'
$lblBkTitle.Location = New-Object System.Drawing.Point(0, 0)
$BkPanel.Controls.Add($lblBkTitle)

$lblBkInfo = New-Object System.Windows.Forms.Label
$lblBkInfo.Location = New-Object System.Drawing.Point(2, 34)
$lblBkInfo.AutoSize = $true
$lblBkInfo.Text = 'Setiap proses pembersihan/optimasi otomatis menyimpan backup layanan & registry ke folder "Documents\BackupOpti". Pilih file lalu klik Load untuk melihat isinya, atau Restore untuk mengembalikan.'
$BkPanel.Controls.Add($lblBkInfo)

$script:BkList = New-Object System.Windows.Forms.ListBox
$script:BkList.Location = New-Object System.Drawing.Point(2, 70)
$script:BkList.Size = New-Object System.Drawing.Size(560, 320)
$BkPanel.Controls.Add($script:BkList)

function Refresh-OptiBackupList {
    $script:BkList.Items.Clear()
    foreach ($f in Get-OptiBackupFiles) { [void]$script:BkList.Items.Add((Split-Path -Leaf $f)) }
}

function Show-OptiBackupContents {
    param([string]$File)
    $data = Get-Content -Raw -LiteralPath $File | ConvertFrom-Json
    if (-not $data) { throw 'Backup tidak valid.' }

    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'Isi Backup - ' + (Split-Path -Leaf $File)
    $f.Size = New-Object System.Drawing.Size(780, 560)
    $f.StartPosition = 'CenterParent'
    $f.FormBorderStyle = 'FixedDialog'
    $f.MaximizeBox = $false
    $f.MinimizeBox = $false
    $f.BackColor = $script:PageBack
    $f.Font = Get-OptiFont -Size 9

    $top = New-Object System.Windows.Forms.Label
    $top.Dock = 'Top'
    $top.Height = 40
    $top.AutoSize = $false
    $top.Padding = New-Object System.Windows.Forms.Padding(10, 10, 0, 0)
    $top.ForeColor = $script:TextMuted
    $top.Font = Get-OptiFont -Size 9

    $lv = New-Object System.Windows.Forms.ListView
    $lv.Dock = 'Fill'
    $lv.View = 'Details'
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.MultiSelect = $false
    $lv.BorderStyle = 'None'
    $lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
    $lv.BackColor = [System.Drawing.Color]::White
    $lv.ForeColor = $script:TextPrimary
    $lv.Font = Get-OptiFont -Size 9
    [void]$lv.Columns.Add('Layanan', 230)
    [void]$lv.Columns.Add('Tampilan', 300)
    [void]$lv.Columns.Add('Startup', 90)
    [void]$lv.Columns.Add('Status', 70)

    $srvCount = 0
    if ($data.Services) {
        foreach ($s in @($data.Services)) {
            $srvCount++
            $item = New-Object System.Windows.Forms.ListViewItem
            $item.Text = [string]$s.Name
            [void]$item.SubItems.Add([string]$s.DisplayName)
            [void]$item.SubItems.Add([string]$s.StartMode)
            [void]$item.SubItems.Add([string]$s.State)
            [void]$lv.Items.Add($item)
        }
    }
    $regCount = 0
    if ($data.Registry) { $regCount = @($data.Registry.PSObject.Properties).Count }
    $created = if ($data.Created) { [string]$data.Created } else { '-' }
    $top.Text = ' Dibuat: ' + $created + '   Layanan: ' + $srvCount + '   Tweak Registry: ' + $regCount

    $bottom = New-Object System.Windows.Forms.Panel
    $bottom.Dock = 'Bottom'
    $bottom.Height = 48
    $bottom.Padding = New-Object System.Windows.Forms.Padding(10, 8, 10, 8)
    $bottom.BackColor = [System.Drawing.Color]::FromArgb(247, 248, 250)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = 'Tutup'
    $btnClose.Size = New-Object System.Drawing.Size(110, 30)
    $btnClose.Anchor = 'Right'
    $btnClose.Add_Click({ $f.Close() })
    $bottom.Controls.Add($btnClose)

    $f.Controls.Add($lv)
    $f.Controls.Add($top)
    $f.Controls.Add($bottom)
    $f.ShowDialog() | Out-Null
}

$btnBkCreate = New-ActionButton -Text 'Buat Backup Sekarang' -Width 170 -Click {
    Show-OptiLoading -Text 'Membuat backup...'
    try {
        $f = New-OptiBackup
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Backup' 'Err'; return } finally { Hide-OptiLoading }
    Refresh-OptiBackupList
    Show-OptiMsg ("Backup dibuat:`n" + (Split-Path -Leaf $f)) 'Opti - Backup'
}
$btnBkCreate.Location = New-Object System.Drawing.Point(580, 70)
$BkPanel.Controls.Add($btnBkCreate)

$btnBkRestore = New-ActionButton -Text 'Restore Backup Terpilih' -Width 200 -Click {
    if ($script:BkList.SelectedIndex -lt 0) { Show-OptiMsg 'Pilih file backup dulu.' 'Opti - Restore' 'Warn'; return }
    if (-not (Confirm-OptiMsg 'Kembalikan SEMUA pengaturan (layanan + registry) sesuai backup ini?')) { return }
    Show-OptiLoading -Text 'Mengembalikan backup...'
    try {
        $file = (Get-OptiBackupFiles)[$script:BkList.SelectedIndex]
        $res = Restore-OptiBackup -File $file
    } catch { Show-OptiMsg $_.Exception.Message 'Opti - Restore' 'Err'; return } finally { Hide-OptiLoading }
    Refresh-OptiServiceGrid
    $msg = "Restore selesai. Layana OK: " + $res.ServicesOk + "  Gagal: " + $res.ServicesFail + "."
    if ($res.ServicesFail -gt 0) { $msg += "`nSebagian layanan mungkin tidak ada/harus restart." }
    Show-OptiMsg $msg 'Opti - Restore'
}
$btnBkRestore.Location = New-Object System.Drawing.Point(580, 110)
$BkPanel.Controls.Add($btnBkRestore)

$btnBkOpen = New-ActionButton -Text 'Buka Folder Backup' -Width 170 -Click {
    if (Test-Path -LiteralPath $script:BackupDir) { Start-Process explorer.exe -ArgumentList $script:BackupDir }
}
$btnBkOpen.Location = New-Object System.Drawing.Point(580, 150)
$BkPanel.Controls.Add($btnBkOpen)

$btnBkLoad = New-ActionButton -Text 'Load / Lihat Isi Backup' -Width 200 -Click {
    if ($script:BkList.SelectedIndex -lt 0) { Show-OptiMsg 'Pilih file backup dulu.' 'Opti - Backup' 'Warn'; return }
    try { Show-OptiBackupContents -File (Get-OptiBackupFiles)[$script:BkList.SelectedIndex] } catch { Show-OptiMsg $_.Exception.Message 'Opti - Backup' 'Err' }
}
$btnBkLoad.Location = New-Object System.Drawing.Point(580, 190)
$BkPanel.Controls.Add($btnBkLoad)

$TabBackup.Controls.Add($BkPanel)

$Tabs.TabPages.Add($TabBackup)

foreach ($tp in $Tabs.TabPages) {
    $tp.BackColor = $script:PageBack
    $tp.BorderStyle = 'None'
}

# --- footer / status bar
$StatusBar = New-Object System.Windows.Forms.Panel
$StatusBar.Dock = 'Fill'
$StatusBar.BackColor = [System.Drawing.Color]::FromArgb(247, 248, 250)

$StatusStrip = New-Object System.Windows.Forms.Panel
$StatusStrip.Dock = 'Top'
$StatusStrip.Height = 3
$StatusStrip.BackColor = $script:AccentColor
$StatusBar.Controls.Add($StatusStrip)

$script:lblStatus = New-Object System.Windows.Forms.Label
$script:lblStatus.Dock = 'Left'
$script:lblStatus.AutoSize = $true
$script:lblStatus.Padding = New-Object System.Windows.Forms.Padding(6, 6, 0, 0)
$script:lblStatus.Text = 'Siap.'
$script:lblStatus.Font = Get-OptiFont -Size 9
$script:lblStatus.ForeColor = $script:TextMuted

$script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$script:ProgressBar.Anchor = 'Right'
$script:ProgressBar.Size = New-Object System.Drawing.Size(180, 16)
$script:ProgressBar.Location = New-Object System.Drawing.Point(830, 6)
$script:ProgressBar.ForeColor = $script:AccentColor
$script:ProgressBar.BackColor = [System.Drawing.Color]::FromArgb(230, 233, 238)

$lblAdmin = New-Object System.Windows.Forms.Label
$lblAdmin.Anchor = 'Right'
$lblAdmin.AutoSize = $true
$lblAdmin.Location = New-Object System.Drawing.Point(680, 6)
$lblAdmin.Text = if ($script:IsAdmin) { 'Mode: ADMINISTRATOR' } else { 'Mode: BUKAN ADMIN (beberapa fitur nonaktif)' }
$lblAdmin.ForeColor = if ($script:IsAdmin) { [System.Drawing.Color]::DarkGreen } else { [System.Drawing.Color]::Firebrick }
$lblAdmin.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)

$StatusBar.Controls.Add($script:lblStatus)
$StatusBar.Controls.Add($script:ProgressBar)
$StatusBar.Controls.Add($lblAdmin)

# --- assemble layout
$Layout.Controls.Add($Header, 0, 0)
$Layout.Controls.Add($Tabs, 0, 1)
$Layout.Controls.Add($StatusBar, 0, 2)

# --- overlay loading (animasi saat semua proses berjalan)
$script:LoadingPanel = New-Object System.Windows.Forms.Panel
$script:LoadingPanel.Dock = 'Fill'
$script:LoadingPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 250, 253)
$script:LoadingPanel.Visible = $false

$script:LoadingCard = New-Object System.Windows.Forms.Panel
$script:LoadingCard.Size = New-Object System.Drawing.Size(340, 100)
$script:LoadingCard.BackColor = [System.Drawing.Color]::White
$script:LoadingCard.BorderStyle = 'FixedSingle'

$script:LoadingLabel = New-Object System.Windows.Forms.Label
$script:LoadingLabel.Location = New-Object System.Drawing.Point(14, 12)
$script:LoadingLabel.Size = New-Object System.Drawing.Size(312, 24)
$script:LoadingLabel.Text = 'Memproses...'
$script:LoadingLabel.Font = Get-OptiFont -Size 10 -Style Bold
$script:LoadingLabel.ForeColor = $script:TextPrimary

$script:LoadingBar = New-Object System.Windows.Forms.ProgressBar
$script:LoadingBar.Location = New-Object System.Drawing.Point(14, 48)
$script:LoadingBar.Size = New-Object System.Drawing.Size(312, 26)
$script:LoadingBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$script:LoadingBar.ForeColor = $script:AccentColor

$script:LoadingCard.Controls.Add($script:LoadingLabel)
$script:LoadingCard.Controls.Add($script:LoadingBar)
$script:LoadingPanel.Controls.Add($script:LoadingCard)
$script:LoadingPanel.Dock = 'None'
$Form.Controls.Add($script:LoadingPanel)
$Form.Add_Resize({ Update-OptiLoadingBounds })

$script:LoadingTimer = New-Object System.Windows.Forms.Timer
$script:LoadingTimer.Interval = 350
$script:LoadingTimer.Add_Tick({ Update-OptiLoadingDots })

# ==== TERMS CHECK ====
$Config = Get-OptiConfig
if (-not $Config.TermsAccepted) {
    $agree = Show-OptiTerms
    if (-not $agree) {
        [System.Windows.Forms.MessageBox]::Show('Anda menolak Peraturan & Kebijakan. Aplikasi ditutup.', 'Opti', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        exit
    }
    $Config.TermsAccepted = $true
    $Config.TermsVersion = 1
    Save-OptiConfig -Config $Config
}

# kick off
Apply-OptiTheme -Control $Form
Refresh-OptiRamInfo
Refresh-OptiServiceGrid
Refresh-OptiBackupList
Write-OptiStatus 'Opti siap. Gunakan tab di atas untuk mulai mengoptimalkan PC Anda.'

[System.Windows.Forms.Application]::Run($Form)
} catch {
    $errText = $_.Exception.ToString()
    try {
        $logDir = Join-Path $env:LOCALAPPDATA 'Opti'
        if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Set-Content -LiteralPath (Join-Path $logDir 'error.log') -Value $errText -Encoding UTF8
    } catch { }
    [System.Windows.Forms.MessageBox]::Show('Opti gagal berjalan:' + [Environment]::NewLine + $_.Exception.Message + [Environment]::NewLine + [Environment]::NewLine + 'Detail lengkap: %LOCALAPPDATA%\Opti\error.log', 'Opti - Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}