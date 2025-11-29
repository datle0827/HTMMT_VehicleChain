// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VehicleRegistry {
    
    // 1. Cấu trúc dữ liệu
    enum Status { KHONG_TON_TAI, CHO_DUYET_CAP_MOI, DA_CAP, CHO_DUYET_SANG_TEN, BI_TU_CHOI }

    struct Vehicle {
        string vin;             // Số khung (Khóa chính)
        string ipfsHash;        // Ảnh/Giấy tờ trên IPFS
        string plateNumber;     // Biển số
        string brand;           // Nhãn hiệu xe
        address owner;          // Chủ hiện tại
        address pendingBuyer;   // Người mua đang chờ (nếu có)
        Status status;          // Trạng thái
        string rejectReason;    // Lý do từ chối
        uint256 timestamp;      // Ngày cập nhật cuối
    }

    address public authority; // Địa chỉ Cơ quan (Admin)
    
    // Lưu trữ xe theo số khung
    mapping(string => Vehicle) public vehicles;
    
    // Danh sách VIN của một người (Để hiển thị Kho xe)
    mapping(address => string[]) public ownerVehicles;

    // Danh sách tất cả VIN (Để Admin tra cứu)
    string[] public allVINs;

    // Events (Để Frontend bắt sự kiện)
    event YeuCauMoi(string vin, address indexed owner);
    event DaDuyetCapMoi(string vin, address indexed owner);
    event YeuCauSangTen(string vin, address indexed from, address indexed to);
    event DaDuyetSangTen(string vin, address indexed from, address indexed to);

    // Modifier
    modifier onlyAuthority() {
        require(msg.sender == authority, "Chi danh cho Co quan chuc nang");
        _;
    }

    constructor() {
        authority = msg.sender; // Người deploy là Admin
    }

    // --- CHỨC NĂNG NGƯỜI DÂN ---

    // 1. Đăng ký xe mới
    function requestRegistration(string memory _vin, string memory _ipfsHash, string memory _plate, string memory _brand) public {
        require(vehicles[_vin].status == Status.KHONG_TON_TAI, "Xe da ton tai hoac dang cho duyet");

        vehicles[_vin] = Vehicle({
            vin: _vin,
            ipfsHash: _ipfsHash,
            plateNumber: _plate,
            brand: _brand,
            owner: msg.sender,
            pendingBuyer: address(0),
            status: Status.CHO_DUYET_CAP_MOI,
            rejectReason: "",
            timestamp: block.timestamp
        });

        // Thêm vào danh sách quản lý
        ownerVehicles[msg.sender].push(_vin);
        allVINs.push(_vin);

        emit YeuCauMoi(_vin, msg.sender);
    }

    // 2. Yêu cầu chuyển nhượng (Bán xe)
    function requestTransfer(string memory _vin, address _buyer) public {
        require(vehicles[_vin].owner == msg.sender, "Khong phai xe chinh chu");
        require(vehicles[_vin].status == Status.DA_CAP, "Xe khong o trang thai hop le de ban");
        require(_buyer != address(0), "Dia chi nguoi mua khong hop le");

        vehicles[_vin].status = Status.CHO_DUYET_SANG_TEN;
        vehicles[_vin].pendingBuyer = _buyer;

        emit YeuCauSangTen(_vin, msg.sender, _buyer);
    }

    // --- CHỨC NĂNG CƠ QUAN (ADMIN) ---

    // 3. Duyệt cấp mới
    function approveRegistration(string memory _vin) public onlyAuthority {
        require(vehicles[_vin].status == Status.CHO_DUYET_CAP_MOI, "Trang thai khong phai cho duyet");
        
        vehicles[_vin].status = Status.DA_CAP;
        vehicles[_vin].timestamp = block.timestamp;
        
        emit DaDuyetCapMoi(_vin, vehicles[_vin].owner);
    }

    // 4. Duyệt sang tên
    function approveTransfer(string memory _vin) public onlyAuthority {
        require(vehicles[_vin].status == Status.CHO_DUYET_SANG_TEN, "Khong co yeu cau sang ten");

        address oldOwner = vehicles[_vin].owner;
        address newOwner = vehicles[_vin].pendingBuyer;

        // Xóa xe khỏi chủ cũ (Kỹ thuật Swap and Pop để tiết kiệm gas)
        removeVehicleFromOwner(oldOwner, _vin);

        // Thêm xe vào chủ mới
        ownerVehicles[newOwner].push(_vin);

        // Cập nhật thông tin xe
        vehicles[_vin].owner = newOwner;
        vehicles[_vin].pendingBuyer = address(0);
        vehicles[_vin].status = Status.DA_CAP;
        vehicles[_vin].timestamp = block.timestamp;

        emit DaDuyetSangTen(_vin, oldOwner, newOwner);
    }

    // 5. Từ chối hồ sơ
    function rejectVehicle(string memory _vin, string memory _reason) public onlyAuthority {
        vehicles[_vin].status = Status.BI_TU_CHOI;
        vehicles[_vin].rejectReason = _reason;
        vehicles[_vin].pendingBuyer = address(0);
    }

    // --- HÀM HỖ TRỢ (INTERNAL & VIEW) ---

    // Hàm xóa phần tử khỏi mảng (Internal)
    function removeVehicleFromOwner(address _owner, string memory _vin) internal {
        string[] storage myCars = ownerVehicles[_owner];
        for (uint i = 0; i < myCars.length; i++) {
            if (keccak256(bytes(myCars[i])) == keccak256(bytes(_vin))) {
                myCars[i] = myCars[myCars.length - 1]; // Đưa phần tử cuối lên
                myCars.pop(); // Xóa đuôi
                break;
            }
        }
    }

    // Hàm lấy danh sách xe của User (Trả về mảng Object đầy đủ cho Frontend đỡ phải gọi nhiều lần)
    function getMyVehicles(address _user) public view returns (Vehicle[] memory) {
        string[] memory vins = ownerVehicles[_user];
        Vehicle[] memory myCars = new Vehicle[](vins.length);
        
        for(uint i = 0; i < vins.length; i++) {
            myCars[i] = vehicles[vins[i]];
        }
        return myCars;
    }

    // Hàm lấy tất cả xe (Cho Admin Dashboard)
    function getAllVehicles() public view returns (Vehicle[] memory) {
        Vehicle[] memory allCars = new Vehicle[](allVINs.length);
        for(uint i = 0; i < allVINs.length; i++) {
            allCars[i] = vehicles[allVINs[i]];
        }
        return allCars;
    }
}