# DFT Internship Labs — Vivado 2022.2 + Python

**Mục tiêu:** Từ Scan DFF đến Scan-based fault test, ATPG đơn giản, JTAG TAP FSM, và Tcl automation.
Đây là bài tập tự học để chuẩn bị cho DFT internship. **Không phải luồng TestMAX**, không thực hiện automatic scan insertion, DFT DRC, production ATPG, hay JTAG IEEE 1149.1 đầy đủ.

## Lộ trình

| Lab | Kỹ năng | File chính | Kết quả cần tự chạy |
|---|---|---|---|
| 01 | Scan DFF, Scan Chain, self-checking testbench | `lab01_scan_basics/` | Các bài test reset / capture / shift PASS |
| 02 | Scan-in -> functional capture -> scan-out, stuck-at-0/1, simple ATPG | `lab02_scan_atpg/` | `ALL LAB02 TESTS PASSED` và report Python |
| 03 | JTAG TAP 16 states (educational), IR/DR/BYPASS | `lab03_jtag_tap/` | `ALL LAB03 TESTS PASSED` |
| 04 | Python, Vivado Tcl automation, Linux Shell | `vivado_tcl/` | Chạy mô phỏng tự động qua Tcl console |

## Lab 02 — Bắt đầu ở đây

1. Mở Vivado 2022.2 -> Create Project -> RTL Project. Không cần FPGA thật.
2. `Add Sources > Design Sources`: `lab02_scan_atpg/rtl/scan_dff.v`, `lab02_scan_atpg/rtl/scan_logic8.v`.
3. `Add Sources > Simulation Sources`: `lab02_scan_atpg/tb/tb_scan_logic8.v`.
4. Chọn testbench `tb_scan_logic8` làm Simulation Top.
5. Run Simulation -> Run Behavioral Simulation -> Run All.
6. Quan sát các tín hiệu `scan_en`, `scan_in`, `scan_state`, `scan_out`, `fault_mode`, `functional_next`.
7. Xem transcript: case 1 mạch tốt; case 2 lỗi stuck-at-0 bị phát hiện; case 3 stuck-at-1 bị phát hiện; case 4-5 mẫu kiểm thử không phát hiện lỗi (bị mask).
8. Chạy `python lab02_scan_atpg/scripts/atpg_stuck_at.py` bằng PowerShell/Terminal. File `atpg_report.txt` được tạo cạnh script.

**Vì sao 0x0B?** Bit 0, 1, 3 bằng 1 nên n0=q0&q1=1, và q3=1 cho lỗi đi tới next_state[0]. Nếu ép n0=0, bit kết quả sẽ khác: stuck-at-0 bị phát hiện.

**Vì sao 0x08?** Bit 3 bằng 1, còn q0=q1=0 nên n0=0; nếu ép n0=1, bit kết quả đổi: stuck-at-1 bị phát hiện.

**Lưu ý:** Điểm lỗi được mô phỏng bằng `fault_mode` để học; không phải chứng minh FF vật lý hỏng, và không phải phép kiểm thử chuẩn sản xuất. 100% chỉ có nghĩa tìm được pattern cho **2 lỗi mô hình hóa** ở nút n0, không phải 100% fault coverage toàn mạch.

## Lab 03 — Sau khi hiểu Lab02

1. Tạo Vivado project mới (tránh trộn các top/testbench).
2. Design Source: `lab03_jtag_tap/rtl/jtag_tap_demo.v`.
3. Simulation Source: `lab03_jtag_tap/tb/tb_jtag_tap_demo.v`.
4. Simulation Top: `tb_jtag_tap_demo`. Chạy Behavioral Simulation.
5. Hiểu TCK (clock), TMS (FSM control), TDI (serial in), TDO (serial out).
6. Theo dõi state chuyển IDLE -> Select-DR -> Select-IR -> Capture-IR -> Shift-IR -> Update-IR -> IDLE; sau đó Capture-DR -> Shift-DR -> Update-DR.

JTAG TAP/Boundary Scan và internal scan để kiểm thử logic là hai thứ liên quan nhưng không đồng nhất. Lab03 minh họa FSM và các thanh ghi JTAG, không có boundary-scan cells chuẩn IEEE.

## Lab04 — Scripting / EDA

- Windows PowerShell: `python .\lab02_scan_atpg\scripts\atpg_stuck_at.py`
- Vivado Tcl Console: `source C:/DUONG_DAN/DFT_Internship_Labs/vivado_tcl/run_lab02.tcl`
- Run Lab03 trên một Vivado project MỚI: `source C:/DUONG_DAN/DFT_Internship_Labs/vivado_tcl/run_lab03.tcl`
- TCL chỉ chạy khi Vivado project đã mở. Đổi đường dẫn ví dụ thành đường dẫn thật. Dùng dấu `/` trên Windows.

## Đề xuất làm thêm

- Kiểm tra edge cases: all-zeros, all-ones, alternating bits.
- Viết testbench giả lập scan stuck-at input hoặc clock stuck; mô tả rõ mô hình lỗi.
- Mở RTL Schematic sau synthesis, giải thích flip-flop + MUX.
- Ôn STA: setup, hold, slack, clock uncertainty; ôn CMOS inverter, static/dynamic power.

## Minh chứng khi đưa vào CV

Chỉ ghi sau khi đã tự chạy mô phỏng thành công và có waveform/report. Không ghi là đã dùng Synopsys TestMAX/Design Compiler nếu chưa có kinh nghiệm thực tế.
