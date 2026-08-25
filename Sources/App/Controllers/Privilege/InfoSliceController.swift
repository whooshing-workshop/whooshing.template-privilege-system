import PrivilegeSystemDriver
import VaporTube
import Foundation

/// 用户附加信息切片控制器：对已有用户信息（UserInfo）下的
/// 地址 / 备用邮箱 / 备用手机号切片进行单独的增删改。
///
/// 三种切片类型的路由结构完全一致：
///
///     增: PUT    /info_slice/TYPE/:infoId          （infoId 为 UserInfo 记录 ID）
///     删: DELETE /info_slice/TYPE                  （body 为切片 ID 列表）
///     改: POST   /info_slice/TYPE/:infoSliceId/value
///         POST   /info_slice/TYPE/:infoSliceId/order
///         POST   /info_slice/TYPE/:infoSliceId/summary
///
/// TYPE 取值：address / phone / alternate_email
public struct InfoSliceController: RouteCollection, Sendable {
    static let infoSlice = PrivilegeSystem.main.infoSlice

    public func boot(routes: any RoutesBuilder) throws {
        let slice = routes.grouped("info_slice")

        slice.group("address") { router in
            router.put(":infoId", use: createAddress)
            router.delete(use: deleteAddress)
            router.group(":infoSliceId") { r in
                r.post("value", use: updateAddressValue)
                r.post("order", use: updateAddressOrder)
                r.post("summary", use: updateAddressSummary)
            }
        }

        slice.group("phone") { router in
            router.put(":infoId", use: createPhone)
            router.delete(use: deletePhone)
            router.group(":infoSliceId") { r in
                r.post("value", use: updatePhoneValue)
                r.post("order", use: updatePhoneOrder)
                r.post("summary", use: updatePhoneSummary)
            }
        }

        slice.group("alternate_email") { router in
            router.put(":infoId", use: createAlternateEmail)
            router.delete(use: deleteAlternateEmail)
            router.group(":infoSliceId") { r in
                r.post("value", use: updateAlternateEmailValue)
                r.post("order", use: updateAlternateEmailOrder)
                r.post("summary", use: updateAlternateEmailSummary)
            }
        }
    }
}

// MARK: - 泛型实现

extension InfoSliceController {
    func create<T: UserInfoModel>(_ type: T.Type, req: Request) async throws -> [QInfoSlice<T>] {
        let infoId = try parameter("infoId", from: req) { UUID(uuidString: $0) }
        let slices = try req.content.decode(OrderedSet<PInfoSlice<T>>.self)
        return try await Self.infoSlice.create(for: infoId, extendedInfos: slices)
    }

    func delete<T: UserInfoModel>(_ type: T.Type, req: Request) async throws -> Bool {
        let ids = try req.content.decode(OrderedSet<UUID>.self)
        try await Self.infoSlice.delete(infoIds: ids, type: T.self)
        return true
    }

    func updateValue<T: UserInfoModel>(_ type: T.Type, req: Request) async throws -> QInfoSlice<T> {
        let infoSliceId = try parameter("infoSliceId", from: req) { UUID(uuidString: $0) }
        let value = try req.content.decode(T.Model.Value.self)
        let updater = PInfoSlice<T>.Updater(infoSliceId: infoSliceId).update(value: value)
        return try await Self.infoSlice.update(with: updater)
    }

    func updateOrder<T: UserInfoModel>(_ type: T.Type, req: Request) async throws -> QInfoSlice<T> {
        let infoSliceId = try parameter("infoSliceId", from: req) { UUID(uuidString: $0) }
        let order = try req.content.decode(Int16.self)
        let updater = PInfoSlice<T>.Updater(infoSliceId: infoSliceId).update(order: order)
        return try await Self.infoSlice.update(with: updater)
    }

    func updateSummary<T: UserInfoModel>(_ type: T.Type, req: Request) async throws -> QInfoSlice<T> {
        let infoSliceId = try parameter("infoSliceId", from: req) { UUID(uuidString: $0) }
        let summary = try req.content.decode(String?.self)
        let updater = PInfoSlice<T>.Updater(infoSliceId: infoSliceId).update(summary: summary)
        return try await Self.infoSlice.update(with: updater)
    }
}

// MARK: - 地址

public extension InfoSliceController {
    @Sendable
    func createAddress(req: Request) async throws -> [QInfoSlice<Address>] {
        try await create(Address.self, req: req)
    }

    @Sendable
    func deleteAddress(req: Request) async throws -> Bool {
        try await delete(Address.self, req: req)
    }

    @Sendable
    func updateAddressValue(req: Request) async throws -> QInfoSlice<Address> {
        try await updateValue(Address.self, req: req)
    }

    @Sendable
    func updateAddressOrder(req: Request) async throws -> QInfoSlice<Address> {
        try await updateOrder(Address.self, req: req)
    }

    @Sendable
    func updateAddressSummary(req: Request) async throws -> QInfoSlice<Address> {
        try await updateSummary(Address.self, req: req)
    }
}

// MARK: - 备用手机号

public extension InfoSliceController {
    @Sendable
    func createPhone(req: Request) async throws -> [QInfoSlice<Phone>] {
        try await create(Phone.self, req: req)
    }

    @Sendable
    func deletePhone(req: Request) async throws -> Bool {
        try await delete(Phone.self, req: req)
    }

    @Sendable
    func updatePhoneValue(req: Request) async throws -> QInfoSlice<Phone> {
        try await updateValue(Phone.self, req: req)
    }

    @Sendable
    func updatePhoneOrder(req: Request) async throws -> QInfoSlice<Phone> {
        try await updateOrder(Phone.self, req: req)
    }

    @Sendable
    func updatePhoneSummary(req: Request) async throws -> QInfoSlice<Phone> {
        try await updateSummary(Phone.self, req: req)
    }
}

// MARK: - 备用邮箱

public extension InfoSliceController {
    @Sendable
    func createAlternateEmail(req: Request) async throws -> [QInfoSlice<AlternateEmail>] {
        try await create(AlternateEmail.self, req: req)
    }

    @Sendable
    func deleteAlternateEmail(req: Request) async throws -> Bool {
        try await delete(AlternateEmail.self, req: req)
    }

    @Sendable
    func updateAlternateEmailValue(req: Request) async throws -> QInfoSlice<AlternateEmail> {
        try await updateValue(AlternateEmail.self, req: req)
    }

    @Sendable
    func updateAlternateEmailOrder(req: Request) async throws -> QInfoSlice<AlternateEmail> {
        try await updateOrder(AlternateEmail.self, req: req)
    }

    @Sendable
    func updateAlternateEmailSummary(req: Request) async throws -> QInfoSlice<AlternateEmail> {
        try await updateSummary(AlternateEmail.self, req: req)
    }
}
