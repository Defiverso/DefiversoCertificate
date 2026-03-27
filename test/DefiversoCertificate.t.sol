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

    function test_SignAndVerifyBool() public {
        // Hashing using abi.encode
        bytes32 hash = keccak256(abi.encode(oct1, name1, course));
        
        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = hash;
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);

        assertTrue(cert.verify(oct1, name1, course));
        assertTrue(cert.checkHasCertificate(student));
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
        
        bytes32[] memory hashes = new bytes32[](1);
        address[] memory students = new address[](1);
        hashes[0] = keccak256(abi.encode(oct1, name1, course));
        students[0] = student;

        vm.prank(professor);
        cert.signCertificates(hashes, students, course);
        
        assertTrue(cert.checkHasCertificate(student));
    }

    function test_SignEmptyArrays() public {
        vm.prank(professor);
        cert.signCertificates(new bytes32[](0), new address[](0), course);
    }
}
