// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DefiversoCertificate
 * @author Thiego Carvalho (Zeru)
 * @notice Smart contract for managing and verifying decentralized certificates.
 * @dev Optimized for privacy (LGPD) by using off-chain hashing with string identifiers.
 */
contract DefiversoCertificate {
    /// @notice The current owner of the contract.
    address public owner;

    /// @notice Indicates if the contract is currently paused.
    bool public paused;

    /// @notice Mapping of completed course IDs per student.
    mapping(address => bytes32[]) private studentCourses;

    /// @notice Auxiliary mapping for O(1) duplicate check.
    mapping(address => mapping(bytes32 => bool)) private hasCompletedCourse;

    /// @notice Mapping of authorized professors who can sign certificates.
    mapping(address => bool) public isProfessor;

    /// @notice Mapping from certificate hash to its validity status.
    mapping(bytes32 => bool) public certificateRecipient;

    // Custom Errors
    error UnauthorizedOwner();
    error UnauthorizedProfessor();
    error ArrayLengthMismatch();
    error EnforcedPause();
    error AddressZero();

    // Events
    event ProfessorRegistered(address indexed professor);
    event ProfessorUnregistered(address indexed professor);
    event CertificatesSigned(
        string indexed courseName,
        bytes32 courseId,
        uint256 count
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedOwner();
        _;
    }

    /// @dev Throws if called by any account other than an authorized professor.
    modifier onlyProfessor() {
        if (!isProfessor[msg.sender]) revert UnauthorizedProfessor();
        _;
    }

    /// @dev Throws if the contract is currently paused.
    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert AddressZero();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Pauses or unpauses all critical contract functions.
     * @param _paused True to pause, false to unpause.
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @notice Registers a new professor address.
     * @param _professor The address of the professor to register.
     */
    function registerProfessor(
        address _professor
    ) external onlyOwner whenNotPaused {
        if (_professor == address(0)) revert AddressZero();
        isProfessor[_professor] = true;
        emit ProfessorRegistered(_professor);
    }

    /**
     * @notice Unregisters an existing professor address.
     * @param _professor The address of the professor to unregister.
     */
    function unregisterProfessor(
        address _professor
    ) external onlyOwner whenNotPaused {
        isProfessor[_professor] = false;
        emit ProfessorUnregistered(_professor);
    }

    /**
     * @notice Signs certificates using pre-calculated hashes.
     * @dev The hash must be keccak256(octacode_string + studentName_string + courseName_string).
     * @param hashes Array of pre-calculated hashes.
     * @param students Array of student wallet addresses.
     * @param courseName Name of the course for logging purposes.
     */
    function signCertificates(
        bytes32[] calldata hashes,
        address[] calldata students,
        string calldata courseName
    ) external onlyProfessor whenNotPaused {
        uint256 length = hashes.length;
        if (length != students.length) revert ArrayLengthMismatch();

        bytes32 courseId = keccak256(abi.encodePacked(courseName));

        for (uint256 i = 0; i < length; ) {
            certificateRecipient[hashes[i]] = true;

            if (!hasCompletedCourse[students[i]][courseId]) {
                hasCompletedCourse[students[i]][courseId] = true;
                studentCourses[students[i]].push(courseId);
            }

            unchecked {
                ++i;
            }
        }

        emit CertificatesSigned(courseName, courseId, length);
    }

    /**
     * @notice Verifies if a certificate configuration is valid.
     * @param octacode The Octacode string.
     * @param studentFullName The full name associated with the certificate.
     * @param courseName The full name of the course.
     * @return bool True if the certificate is valid, false otherwise.
     */
    function verify(
        string calldata octacode,
        string calldata studentFullName,
        string calldata courseName
    ) external view returns (bool) {
        bytes32 computedHash = keccak256(
            abi.encode(octacode, studentFullName, courseName)
        );

        return certificateRecipient[computedHash];
    }

    /**
     * @notice Returns all completed course IDs for a student.
     * @param student The wallet address of the student.
     * @return bytes32[] Array of course IDs (keccak256 hashes).
     */
    function getStudentCourses(
        address student
    ) external view returns (bytes32[] memory) {
        return studentCourses[student];
    }

    /**
     * @notice Checks if a student has completed a specific course.
     * @param student The wallet address of the student.
     * @param courseId The keccak256 hash of the course name.
     * @return bool True if the student has completed the course.
     */
    function hasStudentCompletedCourse(
        address student,
        bytes32 courseId
    ) external view returns (bool) {
        return hasCompletedCourse[student][courseId];
    }

    /**
     * @notice Returns the number of courses completed by a student.
     * @param student The wallet address of the student.
     * @return uint256 The count of completed courses.
     */
    function getStudentCourseCount(
        address student
    ) external view returns (uint256) {
        return studentCourses[student].length;
    }

    /**
     * @notice Checks if a wallet address holds any valid certificate.
     * @param student The wallet address to investigate.
     * @return bool True if the address has been registered as a recipient.
     */
    function checkHasCertificate(address student) external view returns (bool) {
        return studentCourses[student].length > 0;
    }
}
