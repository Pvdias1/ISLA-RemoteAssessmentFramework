pragma solidity ^0.4.24;

//import of struct's library
import "./Structs.sol";

contract Registry {

    //variables declaration
    address private owner;
    address[] private revoked;

    //mapping Professor's address with permission
    mapping(address => Structs.Permission) private permissions;

    //modifier declaration for contract owner
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    //setting contract owner when contract is deployed
    constructor() public {
      owner = msg.sender;
    }

    //event to log when a permission is issued
    event professorPermission(address from, address to, uint date);

    //function to register Professor's permission in the system
    function addProfessor(address professor, address heiProfHash, uint notAfter) public onlyOwner {
      require(professor != 0x0);
      permissions[professor].hash = heiProfHash;
      permissions[professor].expiry = notAfter;
      permissions[professor].revoked = false;
      permissions[professor].registered = true;
      emit professorPermission(owner, professor, now);
    }

    //event to log when a permission is revoked
    event professorRevoked(address from, address to, uint date);

    // function to revoke Professor's permission in the system
    function revoke(address professor) public onlyOwner {
      require(professor != 0x0 && permissions[professor].registered);
      permissions[professor].revoked = true;
      revoked.push(professor);
      emit professorRevoked(owner, professor, now);
    }

    //function to verify if Professor is registered in the system
    function verify(address professor) public constant returns(bool) {
      require(professor != 0x0 && permissions[professor].registered);
      if(permissions[professor].revoked || permissions[professor].expiry < now) {
        return false;
      }
      return true;
    }

    // function to list all revoked addresses
    function revokeList() external constant returns(address[]) {
      return revoked;
    }
}

contract Grading {

  //variables declaration
  address private owner;
  Registry private registry; //importing functions from REGISTRY smart contract
  uint private workload;

  //mapping Student's info with discipline and student structs
  mapping(bytes32 => Structs.Discipline) private assessments;
  mapping(address => Structs.Student) private students;

  mapping(address => Structs.Permission) private permissions;

  //modifier declaration for setting Professor as contract owner
  modifier onlyOwner {
    require(msg.sender == owner);
    require(registry.verify(owner));
    _;
  }

  //setting contract owner, registering number of assessments, and REGISTRY address when contract is deployed
  constructor(uint min, address reg, address professor) public {
    require(reg != 0x0 && professor != 0x0);
    workload = min;
    registry = Registry(reg);
    owner = professor;
  }

  //-------------------------------------
  //for testing purpose only
  function showOwner() external constant returns(address) {
      return owner;
    }

  function verifyStudent(address student) public constant returns(bool, uint) {
    require(student != 0x0);
    if(students[student].registered) {
      return (true, students[student].accomplished);
    }
    return (false, 0);
  }

  //-------------------------------------

  //event to log when a student is registered
  event studentRegistered(address from, address to, uint date);

  //function to register Student in the system
  function addStudent(address student, bytes32 id) public onlyOwner {
    require(student != 0x0 && !students[student].registered);
    students[student].id = id;
    students[student].registered = true;
    students[student].accomplished = 0;
    emit studentRegistered(owner, student, now);
  }

  //event to log when an assessment is registered
  event assessmentRegistered(address from, address to, uint date);

  //function to register an assessment in the system
  function registerAssessment(bytes32 id, uint time) public onlyOwner {
    assessments[id].registered = true;
    assessments[id].duration = time;
  }

  //function to update Student's progress in the system
  function updateAssessment(bytes32 discipline, bool status, address student) public onlyOwner {
    require(student != 0x0 && students[student].registered && assessments[discipline].registered);
    students[student].credits[discipline].accomplished = status;
    if(status){
      students[student].accomplished += 1;
    }
    if(students[student].accomplished == workload){
      issueConclusion(student);
    }
  }

  //function to register additional info for certificates in the system
  function regCertificateInfo(bytes32 title, bytes32 description, address issuer, address student) public onlyOwner {
    require(student != 0x0 && students[student].registered && issuer != 0x0);
    require(registry.verify(issuer));
    students[student].docs[title].title = title;
    students[student].docs[description].description = description;
  }

  //internal function to call CONCLUSION when criteria is met
  function issueConclusion(address student) internal {
    require(registry.verify(owner));
    Conclusion conclusion = new Conclusion(student, owner);
    conclusion.emit();
  }

}

contract Conclusion {

    //variables declaration
    address private grantor;
    address private owner;

    //registering info in Document struct
    Structs.Document private conclusion;

    //modifier declaration for setting certificate grantor
    modifier onlyGrantor {
        require(msg.sender == grantor);
        _;
    }

    //modifier declaration for setting certificate owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //setting owner, grantor, and certificate info when contract is deployed
    constructor (address st, address inst) public {
        require(st != 0x0 && inst != 0x0);

        conclusion.receiver = st;
        conclusion.issuer = inst;
        owner = st;
        grantor = inst;
    }

    //event to log when a certificate is issued
    event Issued(address from, address to, uint date);

    //function to issue conclusion certificate in the system
    function emit() public {
        conclusion.date = now;
        conclusion.status = true;
        emit Issued(conclusion.issuer, conclusion.receiver, conclusion.date);
    }

    //event to log when a certificate is revoked
    event Revoked(address from, uint date);

    //function to revoke conclusion certificate 
    function revoked() public onlyGrantor {
        selfdestruct(grantor);
        emit Revoked(grantor, now);
    }

}
