pragma solidity ^0.4.24;

//library to hold the structs of the framework
library Structs {

    //struct for Professor's permission
    struct Permission {
      address hash;
      uint expiry;
      bool revoked;
      bool registered;
      }

    //struct for discipline registration
    struct Discipline {
        bool accomplished;
        bool registered;
        uint duration;
    }

    //struct for Student's registration and progress
    struct Student {
        bytes32 id;
        bool registered;
        uint accomplished;
        mapping(bytes32 => Discipline) credits;
        mapping(bytes32 => Document) docs;
    }

    //struct for conclusion certificates
    struct Document {
        address issuer;
        address receiver;
        bytes32 title;
        bytes32 description;
        uint date;
        bool status;
    }

}
