# DESIGN AND IMPLEMENTATION OF A 32-BIT SINGLE-CYCLE RISC-V PROCESSOR (RV32I)

Báo cáo và tài liệu kỹ thuật về thiết kế cấu trúc phần cứng mạch điều khiển Bộ xử lý vi ba 32-bit Single-Cycle dựa trên kiến trúc tập lệnh mã nguồn mở **RISC-V (RV32I Base Integer Instruction Set)**[cite: 4]. Dự án hoàn thành việc hiện thực hóa toàn bộ luồng dữ liệu (Datapath), khối điều khiển (Control Unit), hệ thống ngoại vi ánh xạ bộ nhớ (Memory-Mapped I/O) và kiểm thử thực nghiệm thành công trên phần cứng kit FPGA Altera DE2[cite: 4].

---

## 👥 Thông tin thực hiện & Thành viên nhóm
* **Tác giả / Đại diện báo cáo:** Nguyễn Duy Tuyên (NGUYEN DUY TUYEN)[cite: 4]
* **Đơn vị phân công:** Nhóm 5 (GROUP 5)[cite: 4]
* **Ngày hoàn thành báo cáo:** 25 tháng 4 năm 2026[cite: 4]

---

## 🧭 Nội dung tổng quan dự án (Project Overview)
Dự án tập trung nghiên cứu sâu và hiện thực hóa phần cứng lớp RTL cho bộ xử lý RISC-V 32-bit thực thi đơn chu kỳ (Single-Cycle)[cite: 4]. Các mục tiêu lõi bao gồm:
1. **Thiết kế & Triển khai lõi RV32I:** Xây dựng cấu trúc xử lý đơn chu kỳ hoàn chỉnh[cite: 4].
2. **Tích hợp khối chức năng:** Hoàn thiện các thực thể cấu trúc Datapath gồm ALU, BRC, Regfile, ImmGen, và Control Unit[cite: 4].
3. **Giao tiếp ngoại vi MMIO:** Thiết lập kênh truyền nhận dữ liệu giữa CPU với các thiết bị vật lý bên ngoài thông qua khối Load-Store Unit (LSU) bằng kỹ thuật Ánh xạ bộ nhớ (Memory-Mapped I/O)[cite: 4].
4. **Xác thực phần cứng:** Tổng hợp toàn bộ hệ thống lên kit FPGA DE-2/DE2-115 và kiểm tra chức năng bằng các chương trình phần mềm viết bằng ngôn ngữ máy Assembly[cite: 4].

---

## 🏗️ Kiến trúc các khối chức năng Datapath (Core Hardware Modules)

### 1. Khối tính toán Số học & Logic (ALU - Arithmetic Logic Unit)
Khối ALU chịu trách nhiệm tính toán các phép toán số học và logic cơ bản giữa hai toán hạng đầu vào `i_a` và `i_b` dựa trên mã điều khiển `i_op` (4-bit)[cite: 4].
* **Loại bỏ toán tử Built-in:** Thiết kế tuân thủ nghiêm ngặt đặc tả tổng hợp phần cứng, loại bỏ hoàn toàn các toán tử tính toán mặc định cấu trúc sẵn của ngôn ngữ (built-in operators) nhằm tối ưu mạch mức cổng[cite: 4].
* **Gộp cấu trúc phần cứng (Resource Sharing):** Tái sử dụng module cộng song song tăng tốc `cla_adder_top` (Carry-Lookahead Adder) cho cả ba tác vụ: Phép cộng (add), Phép trừ (sub), và các phép toán so sánh[cite: 4]. Toán hạng `b_mux` đầu vào bộ cộng sẽ giữ nguyên là `i_b` nếu hệ thống thực hiện lệnh cộng, hoặc đảo bit `~i_b` kèm theo cộng bit Carry-in nếu thực hiện lệnh trừ[cite: 4].
* **Cơ chế so sánh:**
  * **So sánh có dấu (SLT):** Kết quả dựa trên biểu thức logic `Sum[31] XOR overflow`[cite: 4].
  * **So sánh không dấu (SLTU):** Kết quả tính toán bằng cách lấy đảo bit của cờ mượn/nhớ ngõ ra `c_out_adder` ($\overline{C_{out}}$)[cite: 4].
* **Khối dịch bit (Shift Unit):** Sử dụng các module chuyên biệt độc lập bao gồm `shift_left` và `shift_right` hỗ trợ đầy đủ các tập lệnh dịch logic/số học (sll, srl, sra)[cite: 4].

### 2. Khối so sánh điều kiện rẽ nhánh (BRC - Branch Comparison Unit)
Khối BRC thực hiện nhiệm vụ đánh giá các điều kiện rẽ nhánh logic trực tiếp giữa hai thanh ghi toán hạng `rs1_data` và `rs2_data`[cite: 4].
* **Thiết kế mạch trừ cứng:** Cấp phát riêng một module bộ cộng `cla_adder_top` cấu hình ở chế độ trừ phần cứng thay vì dùng các toán tử quan hệ điều kiện built-in, giúp mạch đạt tần số hoạt động cao[cite: 4].
* **Tín hiệu ngõ ra `o_equal`:** Được tạo thành bằng cách áp dụng cổng Logic Reduction NOR dịch trên toàn bộ 32-bit dữ liệu của kết quả hiệu số `a_sub_b`[cite: 4]. Nếu hiệu bằng 0, tín hiệu `o_equal` sẽ tích cực lên mức 1[cite: 4].
* **Xử lý linh hoạt:** Sử dụng bộ dồn kênh Multiplexer điều khiển bằng tín hiệu chọn kiểu so sánh `i_br_un` để quyết định xuất kết quả so sánh nhỏ hơn (`o_less`) theo chế độ có dấu hoặc không dấu[cite: 4].

### 3. Tập thanh ghi cấu trúc (Register File - Regfile)
* **Cấu trúc lưu trữ:** Thiết kế bao gồm tổ hợp lặp lại của 32 thanh ghi lưu trữ dữ liệu 32-bit (đánh địa chỉ từ `x0` đến `x31`)[cite: 4].
* **Cơ chế đọc bất đồng bộ:** Hỗ trợ song song hai cổng đọc hoàn toàn độc lập, cho phép truy xuất đồng thời giá trị toán hạng từ hai thanh ghi nguồn `rs1` và `rs2` thông qua cấu trúc mạch tổ hợp[cite: 4].
* **Cơ chế ghi đồng bộ:** Tiến hành cập nhật dữ liệu ghi vào thanh ghi đích `rd` đồng bộ theo sườn lên (rising edge) của xung nhịp hệ thống `i_clk`, với điều kiện tín hiệu cho phép ghi `i_reg_wen` được khối điều khiển kích hoạt[cite: 4].
* **Thanh ghi nối cứng `x0`:** Thanh ghi `x0` được thiết kế nối cứng xuống mức logic nền 0[cite: 4]. Mọi hành vi cố tình thực hiện thao tác ghi dữ liệu vào `x0` đều bị phần cứng bỏ qua, và thao tác đọc từ `x0` luôn trả về giá trị cố định `32'h00000000`[cite: 4].

### 4. Khối điều khiển trung tâm (Control Unit)
* Khối điều khiển tiếp nhận mã lệnh 32-bit từ bộ nhớ chương trình (Instruction Memory / IS) tiến hành giải mã các trường dữ liệu `opcode`, `funct3`, và `funct7`[cite: 4].
* Thực hiện phân loại định dạng tập lệnh (R-type, I-type, I-Load, I-JALR, S-type, B-type, J-type, LUI, AUIPC) để điều khiển khối `Immediate Generator` trích xuất chính xác giá trị hằng số mở rộng bit tương ứng[cite: 4].
* Phối hợp tạo ra tập hợp các tín hiệu bus điều khiển (`o_pc_sel`, `o_asel`, `o_bsel`, `o_imm_sel`, `o_reg_write_en`, `o_mem_write_en`, `o_wb_sel`, `o_alu_sel`, `o_br_un`) để định tuyến dòng dữ liệu đi qua các bộ dồn kênh Multiplexer, dẫn cấu trúc Datapath thực thi lệnh chuẩn xác trong một chu kỳ xung nhịp[cite: 4].

---

## 📇 Khối Load-Store Unit (LSU) & Không gian ánh xạ bộ nhớ (MMIO)

Khối LSU đóng vai trò làm cầu nối trung gian điều phối luồng dữ liệu trao đổi giữa lõi CPU xử lý bên trong với bộ nhớ trong và các tài nguyên phần cứng ngoại vi bên ngoài thông qua kiến trúc Ánh xạ bộ nhớ (Memory-Mapped I/O)[cite: 4].

### 1. Cơ chế định dạng dữ liệu (Data Alignment)
* **Tác vụ Store:** Dựa vào 2 bit địa chỉ thấp, khối LSU tự động khởi tạo ma trận mặt nạ chọn byte 4-bit (`i_bmask`), cho phép CPU ghi chọn lọc chính xác theo từng phân rã kích thước hình học: Byte, Half-word (16-bit) hoặc Word (32-bit) vào ô nhớ đích[cite: 4].
* **Tác vụ Load:** Hỗ trợ cơ chế tự động căn lề phải dữ liệu đọc về từ ngoại vi hoặc bộ nhớ[cite: 4]. Tùy thuộc vào trường mã lệnh định nghĩa trong `i_funct3`, khối sẽ thực hiện mở rộng bit giữ nguyên dấu (Sign-Extension đối với các lệnh LB, LH) hoặc chèn thêm chuỗi số 0 (Zero-Extension đối với các lệnh LBU, LHU) để trả về từ dữ liệu chuẩn 32-bit[cite: 4].

### 2. Bản đồ giải mã phân vùng địa chỉ (Address Decoding Map)
Hệ thống sử dụng tổ hợp 20-bit cao của đường bus địa chỉ (`addr[31:12]`) để thực hiện phân đoạn thiết bị và kích hoạt các đường chọn chip (Chip Select) phần cứng tương ứng[cite: 4]:

| Địa chỉ bắt đầu (Base Address) | Địa chỉ kết thúc (Top Address) | Thiết bị ánh xạ phần cứng (Mapping Segment) |
| :---: | :---: | :--- |
| `0x1001_1000` | `0xFFFF_FFFF` | Vùng dự phòng hệ thống (Reserved)[cite: 4] |
| `0x1001_0000` | `0x1001_0FFF` | Không gian cổng vào các công tắc gạt **Switches** (Bắt buộc)[cite: 4] |
| `0x1000_5000` | `0x1000_FFFF` | Vùng dự phòng hệ thống (Reserved)[cite: 4] |
| `0x1000_4000` | `0x1000_4FFF` | Các thanh ghi điều khiển màn hình **LCD Control Registers**[cite: 4] |
| `0x1000_3000` | `0x1000_3FFF` | Cụm LED 7-đoạn hiệu năng cao **Seven-segment LEDs 7-4**[cite: 4] |
| `0x1000_2000` | `0x1000_2FFF` | Cụm LED 7-đoạn hiệu năng thấp **Seven-segment LEDs 3-0**[cite: 4] |
| `0x1000_1000` | `0x1000_1FFF` | Cụm đèn LED đơn màu xanh **Green LEDs** (Bắt buộc)[cite: 4] |
| `0x1000_0000` | `0x1000_0FFF` | Cụm đèn LED đơn màu đỏ **Red LEDs** (Bắt buộc)[cite: 4] |
| `0x0000_0800` | `0x0FFF_FFFF` | Vùng dự phòng hệ thống (Reserved)[cite: 4] |
| `0x0000_0000` | `0x0000_07FF` | Không gian bộ nhớ nội bộ RAM kích thước **Memory (2KiB)** (Bắt buộc)[cite: 4] |

---

## 💻 Kịch bản chương trình kiểm thử thực nghiệm (Hardware Validation Applications)

Bộ xử lý đã được kiểm thử chức năng thành công bằng cách nạp trực tiếp 3 kịch bản phần mềm viết bằng Assembly, biên dịch ra mã máy chạy trên kit phần cứng Altera DE2[cite: 4].

### 🎯 Ứng dụng 1: Polling đọc dữ liệu trạng thái Switches hiển thị lên Red LEDs
* **Mô tả thuật toán:** Khởi tạo địa chỉ cơ sở của vùng Switch vật lý vào thanh ghi `x30 = 0x10010000` và địa chỉ Red LED vào thanh ghi `x31 = 0x10000000` thông qua lệnh nạp hằng số `lui`[cite: 4]. Thực hiện vòng lặp Polling liên tục, CPU dùng lệnh `lw` đọc dữ liệu mức logic bật/tắt từ Switch vào thanh ghi tạm `x9`, sau đó thực hiện lệnh `sw` chuyển giá trị từ thanh ghi `x9` ghi đè vào địa chỉ của LEDR[cite: 4]. Sử dụng lệnh nhảy không điều kiện `jal x0, -8` để tạo vòng lặp vô hạn[cite: 4].
* **Kết quả thực nghiệm:** Đạt đáp ứng thời gian thực tối ưu nhờ bản chất kiến trúc Single-Cycle cho phép thực thi trọn vẹn chu kỳ đọc-ghi chỉ trong một xung nhịp[cite: 4]. Các đèn LED đỏ phản hồi đồng bộ tức thời ngay khi người dùng thay đổi trạng thái gạt các nút Switch trên kit phần cứng[cite: 4].

### 🎯 Ứng dụng 2: Chuyển đổi mã nhị phân từ Switches hiển thị số Thập phân lên LED 7-đoạn (HEX)
* **Mô tả thuật toán:**
  * **Bước 1 (Masking):** Sử dụng toán tử mặt nạ bit liên kết logic AND với hằng số 13-bit (`0x1FFF`) nhằm lọc giới hạn dải dữ liệu đầu vào từ các thanh Switch gạt, chặn ngưỡng giá trị tối đa ở mức 8191[cite: 4].
  * **Bước 2 (Tách số):** Triển khai chương trình con thuật toán `DIV10_MOD10` thực hiện chuỗi phép chia lấy phần dư liên tiếp cho cơ số 10 để bóc tách luồng nhị phân thành 6 chữ số đại diện cho hệ thập phân riêng biệt (Hàng đơn vị, hàng chục, hàng trăm, hàng ngàn, hàng chục ngàn, hàng trăm ngàn)[cite: 4].
  * **Bước 3 (Giải mã & Ánh xạ):** Gọi chương trình con `HEX_DECODE` tra bảng (Look-up Table) để biến đổi các giá trị số sang chuỗi mã điều khiển cathode/anode hiển thị LED 7-đoạn[cite: 4]. Dữ liệu được ghi vào các địa chỉ MMIO tương ứng: 4 chữ số thấp chuyển ra không gian vùng HEX 3-0 (`0x10002000`), 2 chữ số cao chuyển ra vùng HEX 5-4 (`0x10003000`)[cite: 4]. Hai đèn HEX 7-6 cao nhất được cố định mã `0x40` (hiển thị số 0) để đồng bộ độ dài hiển thị[cite: 4].
* **Kết quả thực nghiệm:** Khi người dùng thực hiện gạt thanh công tắc tạo mã nhị phân `1111`, cụm đèn LED 7-đoạn lập tức tính toán giải mã và hiển thị chính xác giá trị thập phân tương ứng là `00000015` mà không có độ trễ[cite: 4].

### 🎯 Ứng dụng 3: Bộ đếm thời gian bấm giờ (Stopwatch) có chức năng Tạm dừng (Pause)
* **Mô tả thuật toán:** Tạo lập cơ chế đếm truyền sóng (Ripple Carry Counting) lưu trữ giá trị đếm dạng số thập phân mã hóa nhị phân BCD thông qua cấu trúc 4 thanh ghi định danh từ `x12` đến `x15`[cite: 4]. Khi một hàng đếm đạt ngưỡng giá trị bằng 10, hệ thống tự động kích hoạt tràn bit và reset về 0 để tăng giá trị hàng kế tiếp[cite: 4].
* **Tính năng điều khiển vật lý:** Chương trình liên tục giám sát trạng thái logic của công tắc `SW0`[cite: 4]. Nếu phát hiện `SW0` được bật (kích hoạt chế độ Pause), CPU sẽ thực hiện lệnh rẽ nhánh bỏ qua toàn bộ khối lệnh thực thi tăng giá trị bộ đếm, giúp đóng băng thời gian đếm tại thời điểm đó[cite: 4]. Hệ thống tích hợp một chương trình trễ phần mềm `DELAY_n_100ms` tạo khoảng nghỉ 0.5 giây chính xác giữa các chu kỳ tăng biến đếm[cite: 4].
* **Kết quả thực nghiệm:** Hệ thống đếm thời gian hiển thị rõ nét trên cụm LED 7-đoạn vật lý và phản hồi chức năng dừng đếm ngay lập tức khi gạt thanh `SW0`[cite: 4]. Hình ảnh thực tế ghi nhận bộ đếm dừng hiển thị chính xác tại giá trị số 6 khi kích hoạt công tắc[cite: 4]. Hệ thống tự động reset toàn bộ chuỗi đếm về giá trị 0 chuẩn xác khi biến đếm chạm mốc giới hạn thiết lập (1000)[cite: 4].

---

## 📌 Kết luận
Đồ án đã chứng minh tính đúng đắn và hiệu quả cao của kiến trúc Single-Cycle trong việc thiết kế bộ vi xử lý RISC-V RV32I[cite: 4]. Phần cứng được tối ưu hóa tốt diện tích và tài nguyên cổng logic nhờ việc loại bỏ toán tử mặc định và chia sẻ tài nguyên bộ cộng[cite: 4]. Khối giao tiếp LSU phối hợp giải mã địa chỉ chính xác giúp CPU kiểm soát hoàn hảo hệ thống thiết bị ngoại vi đa dạng trên kit phát triển[cite: 4].
