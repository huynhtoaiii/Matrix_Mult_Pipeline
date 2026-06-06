import numpy as np
from vcdvcd import VCDVCD
from scipy import stats
import matplotlib.pyplot as plt
import random

def analyze_tvla_final(vcd_file):
    print(f"--- Bat dau phan tich chi tiet: {vcd_file} ---")
    
    # 1. Doc cau truc file (Tiet kien RAM)
    try:
        vcd = VCDVCD(vcd_file)
    except Exception as e:
        print(f"Loi khi mo file VCD: {e}")
        return

    all_signals = list(vcd.signals)
    print(f"Tong so tin hieu tim thay: {len(all_signals)}")

    # 2. CHON TIN HIEU: Lay ngau nhien 150 tin hieu noi bo de tim bien dong
    # Viec lay ngau nhien giup bieu do co nhieu 'gai' nhap nho hon la chi lay dau ra
    num_to_sample = min(150, len(all_signals))
    target_signals = random.sample(all_signals, num_to_sample)
    print(f"Dang quet {num_to_sample} tin hieu ngau nhien de tim dau vet ro ri...")

    # 3. CAU HINH THONG SO
    num_traces = 2000
    num_time_points = 2000 # Dat dung 2000 diem theo yeu cau cua ban
    time_limit = vcd.endtime
    
    # Tao mang chua dau vet cong suat (4MB RAM)
    power_traces = np.zeros((num_traces, num_time_points), dtype=np.float32)
    time_steps = np.linspace(0, time_limit, num_time_points)

    # 4. TRICH XUAT DU LIEU
    for i, sig_name in enumerate(target_signals):
        if i % 50 == 0 and i > 0:
            print(f"  > Da xu ly {i}/{num_to_sample} tin hieu...")
            
        tv = vcd[sig_name].tv
        if tv:
            for t, v in tv:
                # Xac dinh vi tri thoi gian (Sampling)
                t_idx = np.searchsorted(time_steps, t) - 1
                # Xac dinh trace hien tai (dua tren thoi gian tuyet doi)
                trace_idx = int(t // (time_limit / num_traces))
                
                if 0 <= trace_idx < num_traces and 0 <= t_idx < num_time_points:
                    # Moi lan tin hieu thay doi (0->1 hoac 1->0) coi nhu tieu ton 1 don vi nang luong
                    power_traces[trace_idx, t_idx] += 1
        
        # Giai phong tham chieu de Python tu dong don rac (thay cho lenh .clear() bi loi)
        tv = None

    # 5. TINH TOAN T-TEST
    print("Dang tinh toan Welch's T-test (Fixed vs Random)...")
    # Nhom 1: Cac trace chi so chan (Fixed), Nhom 2: Cac trace chi so le (Random)
    fixed_group = power_traces[0::2]
    random_group = power_traces[1::2]
    
    t_values, _ = stats.ttest_ind(fixed_group, random_group, axis=0, equal_var=False)
    
    # Xu ly cac gia tri khong xac dinh (NaN) do khong co bien dong
    t_values = np.nan_to_num(t_values)

    # 6. VE BIEU DO
    print("Dang hien thi bieu do...")
    plt.figure(figsize=(12, 6))
    
    # Ve duong T-value voi net manh de de quan sat 2000 diem
    plt.plot(time_steps, t_values, color='royalblue', linewidth=0.6, label='T-value')
    
    # Ve nguong an toan quoc te (+- 4.5)
    plt.axhline(y=4.5, color='red', linestyle='--', linewidth=1, label='Threshold +4.5')
    plt.axhline(y=-4.5, color='red', linestyle='--', linewidth=1, label='Threshold -4.5')
    
    # To mau vung an toan de de nhan biet
    plt.fill_between(time_steps, -4.5, 4.5, color='lightgray', alpha=0.3)

    plt.title(f'TVLA Detailed Analysis - Matrix Multiplication\n(2000 Points, 150 Random Internal Signals)')
    plt.xlabel('Time (ns)')
    plt.ylabel('T-value')
    plt.ylim(min(np.min(t_values)-1, -6), max(np.max(t_values)+1, 6)) # Tu dong gian truc Y
    plt.grid(True, which='both', linestyle=':', alpha=0.5)
    plt.legend(loc='upper right')
    
    print("Xong! Vui long kiem tra cua so Figure hien len.")
    plt.show()

if __name__ == "__main__":
    # Luu y: Dam bao file VCD nam cung thu muc voi file .py nay
    analyze_tvla_final("tvla_1000_traces.vcd")