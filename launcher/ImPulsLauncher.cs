using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace ImPulsLauncher
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new LauncherForm(args));
        }
    }

    internal sealed class ReleaseAsset
    {
        public string Name;
        public string Url;
        public string Digest;
        public long Size;
    }

    internal sealed class LauncherForm : Form
    {
        private const string Repo = "Treninem/game";
        private const string GameAssetName = "ImPuls-PC-Windows-x64.zip";
        private const string LauncherAssetName = "ImPuls-Launcher.exe";
        private const string LauncherHashName = "ImPuls-Launcher.exe.sha256";

        private readonly string InstallDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "ImPuls");
        private readonly string GameDir;
        private readonly string StateDir;
        private readonly string InstalledLauncher;
        private readonly string GameExe;

        private Label titleLabel;
        private Label statusLabel;
        private Label detailLabel;
        private ProgressBar progressBar;
        private Button primaryButton;
        private Button folderButton;
        private volatile bool busy;
        private ReleaseAsset latestGame;
        private bool updateRequired;
        private bool onlineCheckSucceeded;

        public LauncherForm(string[] args)
        {
            GameDir = Path.Combine(InstallDir, "Game");
            StateDir = Path.Combine(InstallDir, ".launcher");
            InstalledLauncher = Path.Combine(InstallDir, LauncherAssetName);
            GameExe = Path.Combine(GameDir, "ImPuls.exe");
            BuildUi();
        }

        protected override void OnShown(EventArgs e)
        {
            base.OnShown(e);
            Thread t = new Thread(BootstrapWorker);
            t.IsBackground = true;
            t.Start();
        }

        private void BuildUi()
        {
            Text = "ImPuls Launcher";
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(720, 390);
            MinimumSize = new Size(720, 390);
            MaximizeBox = false;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            BackColor = Color.FromArgb(18, 20, 31);
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point);

            titleLabel = new Label();
            titleLabel.Text = "ImPuls";
            titleLabel.Font = new Font("Segoe UI", 30F, FontStyle.Bold);
            titleLabel.AutoSize = true;
            titleLabel.Location = new Point(36, 30);
            Controls.Add(titleLabel);

            Label subtitle = new Label();
            subtitle.Text = "Загрузчик и автоматическое обновление игры";
            subtitle.ForeColor = Color.Gainsboro;
            subtitle.AutoSize = true;
            subtitle.Location = new Point(40, 92);
            Controls.Add(subtitle);

            statusLabel = new Label();
            statusLabel.Text = "Проверка...";
            statusLabel.Font = new Font("Segoe UI", 13F, FontStyle.Bold);
            statusLabel.AutoSize = false;
            statusLabel.Location = new Point(40, 145);
            statusLabel.Size = new Size(640, 32);
            Controls.Add(statusLabel);

            detailLabel = new Label();
            detailLabel.Text = "Подключение к GitHub Releases";
            detailLabel.ForeColor = Color.Silver;
            detailLabel.AutoSize = false;
            detailLabel.Location = new Point(40, 180);
            detailLabel.Size = new Size(640, 45);
            Controls.Add(detailLabel);

            progressBar = new ProgressBar();
            progressBar.Location = new Point(40, 235);
            progressBar.Size = new Size(640, 20);
            progressBar.Minimum = 0;
            progressBar.Maximum = 100;
            Controls.Add(progressBar);

            primaryButton = new Button();
            primaryButton.Text = "Проверка...";
            primaryButton.Enabled = false;
            primaryButton.Location = new Point(40, 285);
            primaryButton.Size = new Size(435, 54);
            primaryButton.Font = new Font("Segoe UI", 12F, FontStyle.Bold);
            primaryButton.FlatStyle = FlatStyle.Flat;
            primaryButton.BackColor = Color.FromArgb(86, 58, 170);
            primaryButton.ForeColor = Color.White;
            primaryButton.FlatAppearance.BorderSize = 0;
            primaryButton.Click += PrimaryButtonClick;
            Controls.Add(primaryButton);

            folderButton = new Button();
            folderButton.Text = "Папка игры";
            folderButton.Location = new Point(495, 285);
            folderButton.Size = new Size(185, 54);
            folderButton.FlatStyle = FlatStyle.Flat;
            folderButton.BackColor = Color.FromArgb(38, 42, 58);
            folderButton.ForeColor = Color.White;
            folderButton.FlatAppearance.BorderSize = 0;
            folderButton.Click += delegate { OpenGameFolder(); };
            Controls.Add(folderButton);
        }

        private void BootstrapWorker()
        {
            try
            {
                Directory.CreateDirectory(InstallDir);
                Directory.CreateDirectory(StateDir);

                if (!PathsEqual(Application.ExecutablePath, InstalledLauncher))
                {
                    SetStatus("Установка загрузчика", "Создаю постоянный ярлык ImPuls и переношу загрузчик в профиль пользователя.", -1);
                    File.Copy(Application.ExecutablePath, InstalledLauncher, true);
                    CreateShortcuts(InstalledLauncher);
                    Process.Start(new ProcessStartInfo(InstalledLauncher, "--installed") { UseShellExecute = true });
                    Ui(delegate { Close(); });
                    return;
                }

                CreateShortcuts(InstalledLauncher);
                if (TrySelfUpdate()) return;
                CheckGameRelease();
            }
            catch (Exception ex)
            {
                bool gamePresent = File.Exists(GameExe);
                SetStatus(gamePresent ? "Нет связи с сервером обновлений" : "Не удалось проверить игру", ex.Message, 0);
                Ui(delegate
                {
                    onlineCheckSucceeded = false;
                    updateRequired = false;
                    primaryButton.Text = gamePresent ? "Играть офлайн" : "Повторить";
                    primaryButton.Enabled = true;
                });
            }
        }

        private bool TrySelfUpdate()
        {
            try
            {
                SetStatus("Проверка загрузчика", "Проверяю новую версию ImPuls Launcher.", -1);
                Dictionary<string, object> release = GetJsonObject("https://api.github.com/repos/" + Repo + "/releases/tags/launcher");
                ReleaseAsset exeAsset = FindAsset(release, LauncherAssetName);
                ReleaseAsset hashAsset = FindAsset(release, LauncherHashName);
                if (exeAsset == null || hashAsset == null) return false;

                string expectedHash = DownloadText(hashAsset.Url).Trim();
                int space = expectedHash.IndexOf(' ');
                if (space > 0) expectedHash = expectedHash.Substring(0, space);
                expectedHash = expectedHash.Trim().ToLowerInvariant();
                string currentHash = Sha256File(Application.ExecutablePath);
                if (expectedHash.Length != 64 || string.Equals(expectedHash, currentHash, StringComparison.OrdinalIgnoreCase)) return false;

                string tempRoot = Path.Combine(Path.GetTempPath(), "ImPulsLauncher");
                Directory.CreateDirectory(tempRoot);
                string newExe = Path.Combine(tempRoot, "ImPuls-Launcher.new.exe");
                DownloadFile(exeAsset.Url, newExe, "Обновление загрузчика");
                string downloadedHash = Sha256File(newExe);
                if (!string.Equals(downloadedHash, expectedHash, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Контрольная сумма обновления загрузчика не совпала.");

                string cmd = Path.Combine(tempRoot, "update-launcher.cmd");
                string current = Application.ExecutablePath;
                string script = "@echo off\r\n" +
                    "ping 127.0.0.1 -n 3 >nul\r\n" +
                    "copy /Y \"" + EscapeCmd(newExe) + "\" \"" + EscapeCmd(current) + "\" >nul\r\n" +
                    "start \"\" \"" + EscapeCmd(current) + "\" --resume\r\n" +
                    "del /Q \"%~f0\"\r\n";
                File.WriteAllText(cmd, script, Encoding.ASCII);
                Process.Start(new ProcessStartInfo("cmd.exe", "/c \"\"" + cmd + "\"\"") { CreateNoWindow = true, UseShellExecute = false, WindowStyle = ProcessWindowStyle.Hidden });
                Ui(delegate { Close(); });
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        private void CheckGameRelease()
        {
            SetStatus("Проверка игры", "Получаю последний опубликованный Windows-пакет ImPuls.", -1);
            Dictionary<string, object> release = GetJsonObject("https://api.github.com/repos/" + Repo + "/releases/latest");
            latestGame = FindAsset(release, GameAssetName);
            if (latestGame == null) throw new InvalidDataException("В последнем релизе не найден " + GameAssetName + ".");

            string remoteToken = !string.IsNullOrEmpty(latestGame.Digest) ? latestGame.Digest : latestGame.Name + ":" + latestGame.Size;
            string localToken = ReadState("game.digest");
            bool installed = File.Exists(GameExe);
            updateRequired = !installed || !string.Equals(localToken, remoteToken, StringComparison.OrdinalIgnoreCase);
            onlineCheckSucceeded = true;

            Ui(delegate
            {
                progressBar.Style = ProgressBarStyle.Continuous;
                progressBar.Value = 0;
                if (!installed)
                {
                    statusLabel.Text = "Игра готова к загрузке";
                    detailLabel.Text = FormatSize(latestGame.Size) + " • проверка SHA-256 перед установкой";
                    primaryButton.Text = "Скачать и играть";
                }
                else if (updateRequired)
                {
                    statusLabel.Text = "Доступно обновление";
                    detailLabel.Text = "Новый опубликованный пакет будет установлен с резервной заменой файлов.";
                    primaryButton.Text = "Обновить и играть";
                }
                else
                {
                    statusLabel.Text = "Игра обновлена";
                    detailLabel.Text = "Установлена последняя опубликованная версия.";
                    primaryButton.Text = "Играть";
                }
                primaryButton.Enabled = true;
            });
        }

        private void PrimaryButtonClick(object sender, EventArgs e)
        {
            if (busy) return;
            if (!onlineCheckSucceeded && !File.Exists(GameExe))
            {
                primaryButton.Enabled = false;
                Thread retry = new Thread(BootstrapWorker);
                retry.IsBackground = true;
                retry.Start();
                return;
            }

            if (File.Exists(GameExe) && (!onlineCheckSucceeded || !updateRequired))
            {
                LaunchGame();
                return;
            }

            busy = true;
            primaryButton.Enabled = false;
            Thread t = new Thread(InstallOrUpdateWorker);
            t.IsBackground = true;
            t.Start();
        }

        private void InstallOrUpdateWorker()
        {
            try
            {
                if (Process.GetProcessesByName("ImPuls").Length > 0)
                    throw new InvalidOperationException("Закройте запущенную игру ImPuls перед обновлением.");

                if (latestGame == null) CheckGameRelease();
                string tempRoot = Path.Combine(Path.GetTempPath(), "ImPulsLauncher");
                Directory.CreateDirectory(tempRoot);
                string zipPath = Path.Combine(tempRoot, "game.zip");
                string extractRoot = Path.Combine(tempRoot, "extract-" + Guid.NewGuid().ToString("N"));
                string newDir = GameDir + ".new";
                string oldDir = GameDir + ".old";

                TryDeleteFile(zipPath);
                TryDeleteDirectory(extractRoot);
                TryDeleteDirectory(newDir);

                DownloadFile(latestGame.Url, zipPath, "Скачивание игры");
                VerifyDigest(zipPath, latestGame.Digest);

                SetStatus("Распаковка", "Подготавливаю новую версию отдельно от установленной игры.", -1);
                Directory.CreateDirectory(extractRoot);
                ZipFile.ExtractToDirectory(zipPath, extractRoot);
                string foundExe = FindGameExe(extractRoot);
                if (foundExe == null) throw new InvalidDataException("В скачанном пакете не найден ImPuls.exe.");
                string payloadRoot = Path.GetDirectoryName(foundExe);
                CopyDirectory(payloadRoot, newDir);
                if (!File.Exists(Path.Combine(newDir, "ImPuls.exe"))) throw new InvalidDataException("Новая версия игры неполная.");

                SetStatus("Установка обновления", "Переключаю игру на проверенную новую версию.", -1);
                TryDeleteDirectory(oldDir);
                bool oldMoved = false;
                try
                {
                    if (Directory.Exists(GameDir))
                    {
                        Directory.Move(GameDir, oldDir);
                        oldMoved = true;
                    }
                    Directory.Move(newDir, GameDir);
                    if (oldMoved) TryDeleteDirectory(oldDir);
                }
                catch
                {
                    if (!Directory.Exists(GameDir) && oldMoved && Directory.Exists(oldDir)) Directory.Move(oldDir, GameDir);
                    throw;
                }

                string token = !string.IsNullOrEmpty(latestGame.Digest) ? latestGame.Digest : latestGame.Name + ":" + latestGame.Size;
                WriteState("game.digest", token);
                TryDeleteFile(zipPath);
                TryDeleteDirectory(extractRoot);
                updateRequired = false;

                SetStatus("Готово", "Игра обновлена. Запускаю ImPuls.", 100);
                Ui(delegate
                {
                    primaryButton.Text = "Играть";
                    primaryButton.Enabled = true;
                });
                LaunchGame();
            }
            catch (Exception ex)
            {
                SetStatus("Обновление не установлено", ex.Message, 0);
                Ui(delegate
                {
                    primaryButton.Text = File.Exists(GameExe) ? "Играть офлайн" : "Повторить";
                    primaryButton.Enabled = true;
                });
            }
            finally
            {
                busy = false;
            }
        }

        private void LaunchGame()
        {
            try
            {
                if (!File.Exists(GameExe)) throw new FileNotFoundException("ImPuls.exe не найден.", GameExe);
                Process.Start(new ProcessStartInfo(GameExe) { WorkingDirectory = GameDir, UseShellExecute = true });
                Ui(delegate { WindowState = FormWindowState.Minimized; });
            }
            catch (Exception ex)
            {
                SetStatus("Не удалось запустить игру", ex.Message, 0);
            }
        }

        private void OpenGameFolder()
        {
            try
            {
                Directory.CreateDirectory(GameDir);
                Process.Start(new ProcessStartInfo("explorer.exe", "\"" + GameDir + "\"") { UseShellExecute = true });
            }
            catch { }
        }

        private Dictionary<string, object> GetJsonObject(string url)
        {
            string json = DownloadText(url);
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            serializer.MaxJsonLength = int.MaxValue;
            Dictionary<string, object> obj = serializer.Deserialize<Dictionary<string, object>>(json);
            if (obj == null) throw new InvalidDataException("GitHub вернул пустой ответ.");
            return obj;
        }

        private string DownloadText(string url)
        {
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.UserAgent = "ImPuls-Launcher/1.0";
            request.Accept = "application/vnd.github+json";
            request.Timeout = 20000;
            request.ReadWriteTimeout = 20000;
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            using (StreamReader reader = new StreamReader(response.GetResponseStream(), Encoding.UTF8))
                return reader.ReadToEnd();
        }

        private ReleaseAsset FindAsset(Dictionary<string, object> release, string name)
        {
            object assetsObj;
            if (!release.TryGetValue("assets", out assetsObj)) return null;
            object[] assets = assetsObj as object[];
            if (assets == null) return null;
            foreach (object item in assets)
            {
                Dictionary<string, object> a = item as Dictionary<string, object>;
                if (a == null) continue;
                string assetName = GetString(a, "name");
                if (!string.Equals(assetName, name, StringComparison.OrdinalIgnoreCase)) continue;
                long size = 0;
                object sizeObj;
                if (a.TryGetValue("size", out sizeObj) && sizeObj != null) long.TryParse(Convert.ToString(sizeObj), out size);
                return new ReleaseAsset
                {
                    Name = assetName,
                    Url = GetString(a, "browser_download_url"),
                    Digest = GetString(a, "digest"),
                    Size = size
                };
            }
            return null;
        }

        private static string GetString(Dictionary<string, object> d, string key)
        {
            object v;
            if (!d.TryGetValue(key, out v) || v == null) return "";
            return Convert.ToString(v);
        }

        private void DownloadFile(string url, string destination, string label)
        {
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.UserAgent = "ImPuls-Launcher/1.0";
            request.Timeout = 30000;
            request.ReadWriteTimeout = 30000;
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            using (Stream input = response.GetResponseStream())
            using (FileStream output = new FileStream(destination, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                long total = response.ContentLength;
                long done = 0;
                byte[] buffer = new byte[1024 * 256];
                int read;
                while ((read = input.Read(buffer, 0, buffer.Length)) > 0)
                {
                    output.Write(buffer, 0, read);
                    done += read;
                    int pct = total > 0 ? (int)Math.Min(100, done * 100L / total) : 0;
                    string detail = total > 0 ? FormatSize(done) + " / " + FormatSize(total) : FormatSize(done);
                    SetStatus(label, detail, pct);
                }
            }
        }

        private void VerifyDigest(string path, string digest)
        {
            if (string.IsNullOrEmpty(digest)) return;
            string expected = digest.Trim();
            if (expected.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase)) expected = expected.Substring(7);
            if (expected.Length != 64) return;
            SetStatus("Проверка файла", "Сверяю SHA-256 скачанного пакета.", -1);
            string actual = Sha256File(path);
            if (!string.Equals(expected, actual, StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("SHA-256 скачанного пакета не совпадает с GitHub Release.");
        }

        private static string Sha256File(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream fs = File.OpenRead(path))
            {
                byte[] hash = sha.ComputeHash(fs);
                StringBuilder sb = new StringBuilder(hash.Length * 2);
                for (int i = 0; i < hash.Length; i++) sb.Append(hash[i].ToString("x2"));
                return sb.ToString();
            }
        }

        private static string FindGameExe(string root)
        {
            string direct = Path.Combine(root, "ImPuls.exe");
            if (File.Exists(direct)) return direct;
            string[] found = Directory.GetFiles(root, "ImPuls.exe", SearchOption.AllDirectories);
            return found.Length > 0 ? found[0] : null;
        }

        private static void CopyDirectory(string source, string destination)
        {
            Directory.CreateDirectory(destination);
            foreach (string dir in Directory.GetDirectories(source, "*", SearchOption.AllDirectories))
            {
                string rel = dir.Substring(source.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                Directory.CreateDirectory(Path.Combine(destination, rel));
            }
            foreach (string file in Directory.GetFiles(source, "*", SearchOption.AllDirectories))
            {
                string rel = file.Substring(source.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                string target = Path.Combine(destination, rel);
                Directory.CreateDirectory(Path.GetDirectoryName(target));
                File.Copy(file, target, true);
            }
        }

        private void CreateShortcuts(string target)
        {
            try
            {
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                string programs = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                CreateShortcut(Path.Combine(desktop, "ImPuls.lnk"), target);
                CreateShortcut(Path.Combine(programs, "ImPuls.lnk"), target);
            }
            catch { }
        }

        private static void CreateShortcut(string shortcutPath, string target)
        {
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType == null) return;
            object shell = null;
            object shortcut = null;
            try
            {
                shell = Activator.CreateInstance(shellType);
                shortcut = shellType.InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { shortcutPath });
                Type st = shortcut.GetType();
                st.InvokeMember("TargetPath", BindingFlags.SetProperty, null, shortcut, new object[] { target });
                st.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, shortcut, new object[] { Path.GetDirectoryName(target) });
                st.InvokeMember("IconLocation", BindingFlags.SetProperty, null, shortcut, new object[] { target + ",0" });
                st.InvokeMember("Description", BindingFlags.SetProperty, null, shortcut, new object[] { "ImPuls Launcher" });
                st.InvokeMember("Save", BindingFlags.InvokeMethod, null, shortcut, null);
            }
            finally
            {
                if (shortcut != null && Marshal.IsComObject(shortcut)) Marshal.FinalReleaseComObject(shortcut);
                if (shell != null && Marshal.IsComObject(shell)) Marshal.FinalReleaseComObject(shell);
            }
        }

        private string ReadState(string name)
        {
            string path = Path.Combine(StateDir, name);
            return File.Exists(path) ? File.ReadAllText(path, Encoding.UTF8).Trim() : "";
        }

        private void WriteState(string name, string value)
        {
            Directory.CreateDirectory(StateDir);
            File.WriteAllText(Path.Combine(StateDir, name), value ?? "", Encoding.UTF8);
        }

        private void SetStatus(string status, string detail, int progress)
        {
            Ui(delegate
            {
                statusLabel.Text = status;
                detailLabel.Text = detail;
                if (progress < 0)
                {
                    progressBar.Style = ProgressBarStyle.Marquee;
                    progressBar.MarqueeAnimationSpeed = 25;
                }
                else
                {
                    progressBar.Style = ProgressBarStyle.Continuous;
                    progressBar.Value = Math.Max(0, Math.Min(100, progress));
                }
            });
        }

        private void Ui(Action action)
        {
            try
            {
                if (IsDisposed || Disposing) return;
                if (InvokeRequired) BeginInvoke(action); else action();
            }
            catch { }
        }

        private static bool PathsEqual(string a, string b)
        {
            return string.Equals(Path.GetFullPath(a).TrimEnd('\\'), Path.GetFullPath(b).TrimEnd('\\'), StringComparison.OrdinalIgnoreCase);
        }

        private static string EscapeCmd(string path)
        {
            return path.Replace("\"", "\"\"");
        }

        private static string FormatSize(long bytes)
        {
            if (bytes >= 1024L * 1024L * 1024L) return (bytes / (1024d * 1024d * 1024d)).ToString("0.00") + " ГБ";
            if (bytes >= 1024L * 1024L) return (bytes / (1024d * 1024d)).ToString("0.0") + " МБ";
            if (bytes >= 1024L) return (bytes / 1024d).ToString("0.0") + " КБ";
            return bytes + " Б";
        }

        private static void TryDeleteFile(string path)
        {
            try { if (File.Exists(path)) File.Delete(path); } catch { }
        }

        private static void TryDeleteDirectory(string path)
        {
            try { if (Directory.Exists(path)) Directory.Delete(path, true); } catch { }
        }
    }
}
