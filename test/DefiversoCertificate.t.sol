// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DefiversoCertificate.sol";

contract DefiversoCertificateTest is Test {
    DefiversoCertificate public cert;
    address public owner = address(1);
    address public professor = address(2);
    address public unauthorized = address(3);
    address public student = address(0xABC);

    string public oct1 = "OCTA0001";
    string public name1 = "John Doe";
    string public course = "Solidity 101";

    function setUp() public {
        vm.prank(owner);
        cert = new DefiversoCertificate();
        
        vm.prank(owner);
        cert.registerProfessor(professor);
    }

    function test_InitialState() public {
        assertEq(cert.owner(), owner);
        assertTrue(cert.isProfessor(professor));
        assertFalse(cert.paused());
    }

    function test_SignAndVerifyCourses() public {
        bytes32 hash = keccak256(abi.encode(oct1, name1, course));
        bytes32 expectedCourseId = keccak256(abi.encodePacked(course));

        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = hash;
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        assertTrue(cert.verify(oct1, name1, course));
        assertTrue(cert.checkHasCertificate(student));

        bytes32[] memory courses = cert.getStudentCourses(student);
        assertEq(courses.length, 1);
        assertEq(courses[0], expectedCourseId);
    }

    function test_VerifyInvalidData() public {
        bytes32 hash = keccak256(abi.encode(oct1, name1, course));
        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = hash;
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        // Wrong Octacode
        assertFalse(cert.verify("WRONG", name1, course));
        // Wrong Name
        assertFalse(cert.verify(oct1, "Wrong Name", course));
        // Not signed
        assertFalse(cert.verify("X", name1, course));
    }

    function test_RegisterProfessorZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(DefiversoCertificate.AddressZero.selector);
        cert.registerProfessor(address(0));
    }

    function test_ArrayLengthMismatch() public {
        bytes32[] memory hashes = new bytes32[](2);
        address[] memory students = new address[](1);

        vm.prank(professor);
        vm.expectRevert(DefiversoCertificate.ArrayLengthMismatch.selector);
        cert.signCertificates(hashes, students, course);
    }

    function test_Governance_Ownership() public {
        address newOwner = address(4);
        
        vm.prank(owner);
        cert.transferOwnership(newOwner);
        assertEq(cert.owner(), newOwner);

        // Unauthorized ownership transfer
        vm.prank(owner);
        vm.expectRevert(DefiversoCertificate.UnauthorizedOwner.selector);
        cert.transferOwnership(owner);

        // Address zero transfer
        vm.prank(newOwner);
        vm.expectRevert(DefiversoCertificate.AddressZero.selector);
        cert.transferOwnership(address(0));
    }

    function test_Governance_Pause() public {
        vm.prank(owner);
        cert.setPaused(true);
        assertTrue(cert.paused());

        vm.prank(professor);
        vm.expectRevert(DefiversoCertificate.EnforcedPause.selector);
        cert.signCertificates(new bytes32[](0), new address[](0), course);

        vm.prank(owner);
        vm.expectRevert(DefiversoCertificate.EnforcedPause.selector);
        cert.registerProfessor(address(5));

        vm.prank(owner);
        cert.setPaused(false);
        assertFalse(cert.paused());
    }

    function test_ProfessorManagement() public {
        address newProf = address(5);
        vm.prank(owner);
        cert.registerProfessor(newProf);
        assertTrue(cert.isProfessor(newProf));

        vm.prank(owner);
        cert.unregisterProfessor(newProf);
        assertFalse(cert.isProfessor(newProf));

        // Unauthorized professor management
        vm.prank(professor);
        vm.expectRevert(DefiversoCertificate.UnauthorizedOwner.selector);
        cert.registerProfessor(address(6));
        
        vm.prank(professor);
        vm.expectRevert(DefiversoCertificate.UnauthorizedOwner.selector);
        cert.unregisterProfessor(newProf);
    }

    function test_UnauthorizedSetPaused() public {
        vm.prank(unauthorized);
        vm.expectRevert(DefiversoCertificate.UnauthorizedOwner.selector);
        cert.setPaused(true);
    }

    function test_UnregisterProfessorUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert(DefiversoCertificate.UnauthorizedOwner.selector);
        cert.unregisterProfessor(professor);
    }

    function test_UnauthorizedSign() public {
        vm.prank(unauthorized);
        vm.expectRevert(DefiversoCertificate.UnauthorizedProfessor.selector);
        cert.signCertificates(new bytes32[](0), new address[](0), course);
    }

    function test_UnregisterProfessorPaused() public {
        vm.prank(owner);
        cert.setPaused(true);
        
        vm.prank(owner);
        vm.expectRevert(DefiversoCertificate.EnforcedPause.selector);
        cert.unregisterProfessor(professor);
    }

    function test_CheckHasCertificate() public {
        assertFalse(cert.checkHasCertificate(student));
        assertEq(cert.getStudentCourses(student).length, 0);

        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = keccak256(abi.encode(oct1, name1, course));
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        assertTrue(cert.checkHasCertificate(student));
        assertEq(cert.getStudentCourses(student).length, 1);
    }

    function test_SignEmptyArrays() public {
        vm.prank(professor);
        cert.signCertificates(new bytes32[](0), new address[](0), course);
    }

    function test_GetStudentCourses_MultipleCourses() public {
        string memory course2 = "Web3 Advanced";
        bytes32 courseId1 = keccak256(abi.encodePacked(course));
        bytes32 courseId2 = keccak256(abi.encodePacked(course2));

        bytes32[] memory h1 = new bytes32[](1);
        address[] memory s1 = new address[](1);
        h1[0] = keccak256(abi.encode(oct1, name1, course));
        s1[0] = student;

        vm.prank(professor);
        cert.signCertificates(h1, s1, course);

        bytes32[] memory h2 = new bytes32[](1);
        address[] memory s2 = new address[](1);
        h2[0] = keccak256(abi.encode(oct1, name1, course2));
        s2[0] = student;

        vm.prank(professor);
        cert.signCertificates(h2, s2, course2);

        bytes32[] memory courses = cert.getStudentCourses(student);
        assertEq(courses.length, 2);
        assertEq(courses[0], courseId1);
        assertEq(courses[1], courseId2);
    }

    function test_NoDuplicateCourses() public {
        bytes32[] memory h1 = new bytes32[](1);
        address[] memory s1 = new address[](1);
        h1[0] = keccak256(abi.encode(oct1, name1, course));
        s1[0] = student;

        vm.prank(professor);
        cert.signCertificates(h1, s1, course);

        // Sign same course again with different cert data
        bytes32[] memory h2 = new bytes32[](1);
        address[] memory s2 = new address[](1);
        h2[0] = keccak256(abi.encode("OCTA0002", name1, course));
        s2[0] = student;

        vm.prank(professor);
        cert.signCertificates(h2, s2, course);

        // Student should still have only 1 course ID
        bytes32[] memory courses = cert.getStudentCourses(student);
        assertEq(courses.length, 1);
    }

    function test_MultipleCoursesDifferentStudents() public {
        address student2 = address(0xDEF);
        bytes32 courseId = keccak256(abi.encodePacked(course));

        bytes32[] memory hashes = new bytes32[](2);
        address[] memory students = new address[](2);
        hashes[0] = keccak256(abi.encode(oct1, name1, course));
        hashes[1] = keccak256(abi.encode("OCTA0002", "Jane Doe", course));
        students[0] = student;
        students[1] = student2;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        bytes32[] memory c1 = cert.getStudentCourses(student);
        bytes32[] memory c2 = cert.getStudentCourses(student2);
        assertEq(c1.length, 1);
        assertEq(c2.length, 1);
        assertEq(c1[0], courseId);
        assertEq(c2[0], courseId);
    }

    function test_HasStudentCompletedCourse() public {
        bytes32 courseId = keccak256(abi.encodePacked(course));
        assertFalse(cert.hasStudentCompletedCourse(student, courseId));

        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = keccak256(abi.encode(oct1, name1, course));
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        assertTrue(cert.hasStudentCompletedCourse(student, courseId));
        assertFalse(
            cert.hasStudentCompletedCourse(
                student,
                keccak256(abi.encodePacked("Unknown Course"))
            )
        );
    }

    function test_GetStudentCourseCount() public {
        assertEq(cert.getStudentCourseCount(student), 0);

        bytes32[] memory h1 = new bytes32[](1);
        address[] memory s1 = new address[](1);
        h1[0] = keccak256(abi.encode(oct1, name1, course));
        s1[0] = student;

        vm.prank(professor);
        cert.signCertificates(h1, s1, course);
        assertEq(cert.getStudentCourseCount(student), 1);

        string memory course2 = "Web3 Advanced";
        bytes32[] memory h2 = new bytes32[](1);
        address[] memory s2 = new address[](1);
        h2[0] = keccak256(abi.encode(oct1, name1, course2));
        s2[0] = student;

        vm.prank(professor);
        cert.signCertificates(h2, s2, course2);
        assertEq(cert.getStudentCourseCount(student), 2);
    }
}
