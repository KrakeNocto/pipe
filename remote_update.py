import paramiko
import time

# === Путь к приватному ключу SSH ===
SSH_KEY_PATH = "PATH_TO_SSH"  # например: ~/.ssh/id_rsa

# === Файлы с IP и паролями ===
IP_FILE = "IP.txt"
PASS_FILE = "Pass.txt"

# === Команда для запуска в tmux ===
REMOTE_COMMAND = (
    "tmux new -d -s PIPE_UPD_032 "
    "'bash <(curl -s https://raw.githubusercontent.com/KrakeNocto/pipe/refs/heads/main/pipe_upd_v0.3.2.sh)'"
)

# === Чтение IP и паролей ===
with open(IP_FILE, 'r') as ipf:
    ips = [line.strip() for line in ipf if line.strip()]

with open(PASS_FILE, 'r') as pf:
    passwords = [line.strip() for line in pf if line.strip()]

if len(ips) != len(passwords):
    print("❌ Количество IP-адресов не соответствует количеству паролей.")
    exit(1)

# === Инициализация SSH клиента ===
key = paramiko.Ed25519Key.from_private_key_file(SSH_KEY_PATH, password="YOUR_PWD")

success_log = open("OK_SSH.txt", "w")
fail_log = open("ERROR_SSH.txt", "w")

for ip, password in zip(ips, passwords):
    print(f"🔄 Подключение к {ip}...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(hostname=ip, username="root", password=password, pkey=key, timeout=10)

        stdin, stdout, stderr = client.exec_command(REMOTE_COMMAND)
        output = stdout.read().decode()
        errors = stderr.read().decode()

        if errors:
            print(f"⚠️ Ошибка при выполнении команды на {ip}: {errors}")
            fail_log.write(f"{ip}\n")
        else:
            print(f"✅ Команда выполнена на {ip}")
            success_log.write(f"{ip}\n")

    except Exception as e:
        print(f"❌ Не удалось подключиться к {ip}: {e}")
        fail_log.write(f"{ip}\n")
    finally:
        client.close()
        time.sleep(3)  # интервал между соединениями

success_log.close()
fail_log.close()
print("🎯 Готово. Результаты в OK_SSH.txt и ERROR_SSH.txt.")
