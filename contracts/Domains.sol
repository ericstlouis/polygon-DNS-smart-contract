// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";
import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

contract Domains is ERC721URIStorage {
    //VARIABLE
    mapping(string => address ) public domains;
    mapping(string => string) public records;
    mapping (uint => string) public names;


    string public tld;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public owner;

    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M24.68 24.68c-3.535 3.537-5.85 9.779-5.85 16.264 0 4.39 1.123 8.6 2.905 12.003l23.41-7.803 7.802-23.409c-3.403-1.782-7.612-2.904-12.003-2.904-6.485 0-12.727 2.314-16.263 5.85zm17.133 40.545L84.49 105.82c2.94-4.483 5.96-8.317 9.486-11.843 3.526-3.525 7.36-6.546 11.843-9.486L65.226 41.814l-5.854 17.558zm64.892 41.48c-3.067 3.067-5.818 6.763-8.872 11.806l77.446 73.667c2.645-3.307 5.214-6.216 7.948-8.95 2.735-2.735 5.644-5.304 8.951-7.949l-73.667-77.446c-5.043 3.054-8.739 5.805-11.806 8.872zm88.941 88.94c-9.114 9.115-17.08 22.447-35.67 50.598l11.092 11.092c34.16-51.62 34.647-52.106 86.267-86.267l-11.092-11.092c-28.15 18.59-41.483 26.556-50.597 35.67zm24.042 24.043c-3.998 3.997-7.577 8.54-11.858 14.661l242.865 237.584 42.474 21.236-21.236-42.474L234.349 207.83c-6.12 4.281-10.664 7.86-14.661 11.858z" fill="#fff"/><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cbeee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="3" y="240" font-size="27" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    //ERRORS
    error Unauthorized();
error AlreadyRegistered();
error InvalidName(string name);

    //EVENTS

    //MODIFERS
    modifier onlyOwner() {
      require (isOwner());
      _;
    }

    //FUNCTION
  constructor(string memory _tld) payable ERC721("Shinobi Name Services", "SNS") {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }
    //  calculate the price by measuring the string length
  function price(string calldata name) public pure returns(uint) {
      uint len = StringUtils.strlen(name);
      require(len > 0);
      if (len == 3) {
          return 5 * 10**17 ;
      } else if (len == 4) {
          return 3 * 10**17;
      } else {
          return 1 * 10**17; 
          }
  }
    //register the domain name 
    function register(string calldata name) public payable {
	if (domains[name] != address(0)) revert AlreadyRegistered();
  if (!valid(name)) revert InvalidName(name);        
  uint _price = price(name);

        require(msg.value >= _price, "not enough money");

        domains[name] = msg.sender;
        console.log("%s has registered the domain: %s", msg.sender, name);

        string memory _name = string(abi.encodePacked(name, ".", tld ));
        string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
            string memory strLen = Strings.toString(length);

            console.log("Registering %s. %s on the contract with tokenID %d", name, tld, newRecordId);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            _name,
            '", "description": "A domain on the Shinobi name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );
    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    console.log("\n-----------------------------------------------------------------");
    console.log("Final tokenURI", finalTokenUri);
    console.log("-----------------------------------------------------------------\n");

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;

    _tokenIds.increment();
    names[newRecordId] = name;

    }

    //This will gave us the domain owners' address
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns(string memory) {
        return records[name];
    }

    function withdraw() public  {
      uint amount = address(this).balance;

      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "failed to withdraw");
    }

    function getAllNames() public view returns (string[] memory) {
      console.log("getting all names");
      string[] memory allNames = new string[](_tokenIds.current());
      for (uint i = 0; i < _tokenIds.current(); i++) {
        allNames[i] = names[i];
    console.log("Name for token %d is %s", i, allNames[i]);
      }
      return allNames;
    }

    function valid(string calldata name) public pure returns(bool) {
  return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
}
}