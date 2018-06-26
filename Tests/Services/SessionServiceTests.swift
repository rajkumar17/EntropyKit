@testable import EntropyKit
import OHHTTPStubs
import XCTest

class SessionServiceTests: XCTestCase {
    private var database: Database!
    private var dbPath: URL!

    override func setUp() {
        super.setUp()
        dbPath = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(type(of: self)).sqlite")
        database = try! Database(path: dbPath)
        MatrixAPI.default.baseURL = "https://entropy.kodeshack.com"
    }

    override func tearDown() {
        try! FileManager.default.removeItem(at: dbPath)
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testLogin() {
        stub(condition: pathStartsWith("/_matrix/client/r0/login")) { _ in
            let loginResp = ["user_id": "@NotBob:kodeshack", "access_token": "foo", "device_id": "bar"]
            return OHHTTPStubsResponse(jsonObject: loginResp, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "login request")
        SessionService.login(username: "NotBob", password: "psswd", database: database) { result in
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.userID, "@NotBob:kodeshack")
            XCTAssertEqual(result.value?.accessToken, "foo")
            XCTAssertEqual(result.value?.deviceID, "bar")
            exp.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testLogout() throws {
        stub(condition: pathStartsWith("/_matrix/client/r0/logout")) { _ in
            OHHTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
        }
        let exp = expectation(description: "logout request")
        let account = try Account.create(userID: "@NotBob:kodeshack", accessToken: "foo", deviceID: "bar", database: database)
        try SessionService.logout(account: account) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
