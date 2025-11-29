Hướng dẫn Cài đặt & Chạy Dự án
Đảm bảo máy bạn đã cài đặt:

Node.js (v16 trở lên)

Metamask Extension trên trình duyệt.

Bước 1: Clone dự án
Bash

git clone https://github.com/username/VehicleChain.git
cd VehicleChain
Bước 2: Triển khai Smart Contract (Blockchain Local)
Mở một terminal tại thư mục smart-contract:

Cài đặt thư viện:

Bash

cd smart-contract
npm install
Khởi chạy mạng Blockchain ảo (Local Node):

Bash

npx hardhat node
(Giữ terminal này chạy, không được tắt)

Mở một terminal mới, deploy contract lên mạng ảo:

Bash

cd smart-contract
npx hardhat ignition deploy ./ignition/modules/Lock.ts --network localhost
Lưu ý: Sau khi deploy, hãy copy địa chỉ Contract (ví dụ: 0x5FbDB...) để dùng cho Bước 3.

Bước 3: Chạy Frontend (Client)
Mở terminal tại thư mục client:

Cài đặt thư viện:

Bash

cd client
npm install
Cấu hình biến môi trường:

Tạo file .env trong thư mục client/.

Thêm nội dung sau (Thay thế bằng Key của bạn):

Đoạn mã

VITE_CONTRACT_ADDRESS=0x... (Địa chỉ vừa copy ở Bước 2)
VITE_PINATA_API_KEY=your_pinata_api_key
VITE_PINATA_SECRET_KEY=your_pinata_secret_key
Cập nhật ABI (Nếu có sửa code Solidity):

Copy file JSON từ smart-contract/artifacts/contracts/.../VehicleRegistry.json vào client/src/utils/contractABI.json.

Chạy ứng dụng:

Bash

npm run dev
Truy cập http://localhost:5173 để trải nghiệm.