import tkinter as tk
from tkinter import messagebox
import platform
import subprocess
import ctypes
import os

APP_TITLE = "DTMC SPLAT"
VERSION = "v0.3"

MANAGER = "odpc12.omnix365.net"
GROUP = "Quarantine"
WAZUH_VERSION = "4.14.7-1"
MSI_URL = (
    "https://packages.wazuh.com/4.x/windows/"
    f"wazuh-agent-{WAZUH_VERSION}.msi"
)


def is_windows():
    return platform.system() == "Windows"


def is_admin():
    if not is_windows():
        return False
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def run_command(command):
    return subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True
    )


def wazuh_exists():
    result = run_command('sc query Wazuh')
    return result.returncode == 0


def wazuh_running():
    result = run_command(
        'sc query Wazuh | find /I "RUNNING"'
    )
    return result.returncode == 0


def verify_existing_wazuh(computer_name):
    status_var.set("ตรวจพบ Wazuh Agent อยู่แล้ว\nกำลังตรวจสอบ Service...")
    root.update()

    if not wazuh_running():
        status_var.set("พบ Wazuh แต่ Service ยังไม่ทำงาน\nกำลัง Start...")
        root.update()

        run_command("NET START Wazuh")

    if wazuh_running():
        status_var.set(
            f"WAZUH ALREADY INSTALLED ✓\n"
            f"{computer_name}\n"
            "Wazuh Service: RUNNING"
        )

        messagebox.showinfo(
            "DTMC SPLAT",
            f"ตรวจพบ Wazuh Agent อยู่แล้ว ✓\n\n"
            f"Computer : {computer_name}\n"
            "Service  : RUNNING\n\n"
            "ไม่มีการติดตั้งซ้ำ\n"
            "กรุณาตรวจสถานะ ACTIVE ใน Omnix"
        )
        return True

    raise RuntimeError(
        "ตรวจพบ Wazuh Agent แต่ไม่สามารถ Start Service ได้"
    )


def start_splat():
    computer_name = platform.node().upper()

    if not is_windows():
        messagebox.showerror(
            "DTMC SPLAT",
            "STOP\n\nโปรแกรมรุ่นนี้รองรับ Windows เท่านั้น"
        )
        return

    if not is_admin():
        messagebox.showerror(
            "DTMC SPLAT",
            "STOP\n\nกรุณา Run as Administrator"
        )
        return

    install_button.config(state="disabled")

    try:
        # ----- EXISTING AGENT GUARD -----
        if wazuh_exists():
            verify_existing_wazuh(computer_name)
            return

        # ----- NEW INSTALL CONFIRMATION -----
        confirm = messagebox.askyesno(
            "DTMC SPLAT",
            f"Computer Name: {computer_name}\n\n"
            "ยังไม่พบ Wazuh Agent\n"
            "ใช้ Computer Name นี้เป็น Omnix Agent Name\n\n"
            "ยืนยันติดตั้ง?"
        )

        if not confirm:
            install_button.config(state="normal")
            status_var.set("ยกเลิกการติดตั้ง")
            return

        temp_dir = os.environ.get(
            "TEMP",
            r"C:\Windows\Temp"
        )

        msi_file = os.path.join(
            temp_dir,
            f"wazuh-agent-{WAZUH_VERSION}.msi"
        )

        # ----- DOWNLOAD -----
        status_var.set("1/4  กำลังดาวน์โหลด Wazuh Agent...")
        root.update()

        result = run_command(
            f'powershell -NoProfile -Command '
            f'"Invoke-WebRequest -Uri \'{MSI_URL}\' '
            f'-OutFile \'{msi_file}\'"'
        )

        if result.returncode != 0:
            raise RuntimeError("ดาวน์โหลด Wazuh Agent ไม่สำเร็จ")

        # ----- INSTALL -----
        status_var.set("2/4  กำลังติดตั้ง Omnix Agent...")
        root.update()

        result = run_command(
            f'msiexec.exe /i "{msi_file}" /q '
            f'WAZUH_MANAGER="{MANAGER}" '
            f'WAZUH_AGENT_GROUP="{GROUP}" '
            f'WAZUH_AGENT_NAME="{computer_name}"'
        )

        if result.returncode != 0:
            raise RuntimeError(
                f"ติดตั้งไม่สำเร็จ (code {result.returncode})"
            )

        # ----- START -----
        status_var.set("3/4  กำลัง Start Wazuh...")
        root.update()

        run_command("NET START Wazuh")

        # ----- VERIFY -----
        status_var.set("4/4  กำลังตรวจสอบ Service...")
        root.update()

        if not wazuh_running():
            raise RuntimeError(
                "ติดตั้งแล้ว แต่ Wazuh Service ไม่ทำงาน"
            )

        status_var.set(
            f"SPLATTED ✓\n"
            f"{computer_name}\n"
            "Wazuh Service: RUNNING"
        )

        messagebox.showinfo(
            "DTMC SPLAT",
            f"ติดตั้งสำเร็จ ✓\n\n"
            f"Computer : {computer_name}\n"
            f"Agent    : {computer_name}\n"
            "Service  : RUNNING\n\n"
            "กรุณารอผู้ดูแลตรวจสถานะ ACTIVE ใน Omnix"
        )

    except Exception as error:
        status_var.set("FAILED ✕")

        messagebox.showerror(
            "DTMC SPLAT",
            f"ดำเนินการไม่สำเร็จ\n\n{error}\n\n"
            "กรุณาหยุดและแจ้งผู้ดูแล\n"
            "ไม่ต้องกดซ้ำ"
        )

        install_button.config(state="normal")


# =========================================================
# UI
# =========================================================

root = tk.Tk()
root.title(f"{APP_TITLE} {VERSION}")
root.geometry("520x410")
root.resizable(False, False)

tk.Label(
    root,
    text="DTMC SPLAT",
    font=("Arial", 24, "bold")
).pack(pady=(28, 5))

tk.Label(
    root,
    text="Endpoint Standardization",
    font=("Arial", 11)
).pack()

computer_name = platform.node().upper()

tk.Label(
    root,
    text="Computer Name",
    font=("Arial", 11)
).pack(pady=(23, 3))

tk.Label(
    root,
    text=computer_name,
    font=("Arial", 18, "bold")
).pack()

install_button = tk.Button(
    root,
    text="INSTALL OMNIX",
    font=("Arial", 14, "bold"),
    width=22,
    height=2,
    command=start_splat
)
install_button.pack(pady=20)

status_var = tk.StringVar(
    value="พร้อมทำงาน"
)

tk.Label(
    root,
    textvariable=status_var,
    font=("Arial", 11),
    justify="center"
).pack()

credit_frame = tk.Frame(root)
credit_frame.pack(side="bottom", pady=(0, 14))

tk.Label(
    credit_frame,
    text="👨‍💻   ×   🤖   ×   🐧   ×   🐕",
    font=("Arial", 14)
).pack()

tk.Label(
    credit_frame,
    text=f"{VERSION}  •  DTMC SPLAT  •  © 2026",
    font=("Arial", 9)
).pack(pady=(3, 0))

root.mainloop()
