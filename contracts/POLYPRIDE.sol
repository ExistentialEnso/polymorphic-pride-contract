/*
*  _____   ____  _  __     ____  __  ____  _____  _____  _    _ _____ _____ 
* |  __ \ / __ \| | \ \   / /  \/  |/ __ \|  __ \|  __ \| |  | |_   _/ ____|
* | |__) | |  | | |  \ \_/ /| \  / | |  | | |__) | |__) | |__| | | || |     
* |  ___/| |  | | |   \   / | |\/| | |  | |  _  /|  ___/|  __  | | || |     
* | |    | |__| | |____| |  | |  | | |__| | | \ \| |    | |  | |_| || |____ 
* |_|___  \____/|______|_|__|_|__|_|\____/|_| _\_\_|    |_|  |_|_____\_____|
* |  __ \|  __ \|_   _|  __ \|  ____| |  ____| |        /\   / ____|/ _____| 
* | |__) | |__) | | | | |  | | |__    | |__  | |       /  \ | |  __| (___   
* |  ___/|  _  /  | | | |  | |  __|   |  __| | |      / /\ \| | |_ |\___ \  
* | |    | | \ \ _| |_| |__| | |____  | |    | |____ / ____ \ |__| |____) | 
* |_|    |_|  \_\_____|_____/|______| |_|    |______/_/    \_\_____|_____/ 
*
* 1969 fully on-chain pride flags that can be morphed between one of 12 designs
*                project by smol farm | contract by Thorne
*/

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// SPDX-License-Identifier: CC0-1.0
contract POLYPRIDE is ERC721A, ReentrancyGuard, Ownable, Pausable {
    constructor() ERC721A("Polymorphic Pride Flags", "POLYPRIDE") Ownable() {
        // Pause minting until after promoWeave()
        _pause();
    }

    uint256 public constant mintPrice = 0.03 ether;
    uint256 public constant maxTokens = 1969;

    // Match to flag #, which starts at 1; array starts at 0
    uint8[1969] currentFlag;

    // Displayed as part of the name & as a trait
    string[12] public flagNames = [
        "Rainbow",
        "Chevron Rainbow",
        "Aromantic",
        "Asexual",
        "Bigender",
        "Bisexual",
        "Genderqueer",
        "Intersex",
        "Lesbian",
        "Non-Binary",
        "Pansexual",
        "Transgender"
    ];

    // All flags start with the opening <svg> tag and the first part of a <path> tag 
    // <svg viewBox="0 0 2000 1200" xmlns="http://www.w3.org/2000/svg">
    //     <path d="
    string public constant flagPrefix = "PHN2ZyB2aWV3Qm94PSIwIDAgMjAwMCAxMjAwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPHBhdGggZD0iT";

    string[12] public flagData = [
        "TAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgMTIwMEwyMDAwIDEyMDBMMCAxMjAwTDAgMTIwMEwwIDBMMCAwWiIgZmlsbD0iIzc1MDc4NyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDBMMjAwMCAxMDAwTDIwMDAgMTAwMEwwIDEwMDBMMCAxMDAwTDAgMEwwIDBaIiBmaWxsPSIjMDA0ZGZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgMEwyMDAwIDgwMEwyMDAwIDgwMEwwIDgwMEwwIDgwMEwwIDBMMCAwWiIgZmlsbD0iIzAwODAyNiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDBMMjAwMCA2MDBMMjAwMCA2MDBMMCA2MDBMMCA2MDBMMCAwTDAgMFoiIGZpbGw9IiNmZmVkMDAiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgNDAwTDIwMDAgNDAwTDAgNDAwTDAgNDAwTDAgMEwwIDBaIiBmaWxsPSIjZmY4YzAwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgMEwyMDAwIDIwMEwyMDAwIDIwMEwwIDIwMEwwIDIwMEwwIDBMMCAwWiIgZmlsbD0iI2U0MDMwMyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4=",
        "S0wLjY2NjcyMiAwTDE5OTkgMEwxOTk5IDBMMTk5OSAxMjAwTDE5OTkgMTIwMEwtMC42NjY3MjIgMTIwMEwtMC42NjY3MjIgMTIwMEwtMC42NjY3MjIgMEwtMC42NjY3MjIgMFoiIGZpbGw9IiM3NTA3ODciIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTS0wLjY2NjcyMiAwTDE5OTkgMEwxOTk5IDBMMTk5OSAxMDAwTDE5OTkgMTAwMEwtMC42NjY3MjIgMTAwMEwtMC42NjY3MjIgMTAwMEwtMC42NjY3MjIgMEwtMC42NjY3MjIgMFoiIGZpbGw9IiMwMDRkZmYiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTS0wLjY2NjcyMiAwTDE5OTkgMEwxOTk5IDBMMTk5OSA4MDBMMTk5OSA4MDBMLTAuNjY2NzIyIDgwMEwtMC42NjY3MjIgODAwTC0wLjY2NjcyMiAwTC0wLjY2NjcyMiAwWiIgZmlsbD0iIzAwODAyNiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNLTAuNjY2NzIyIDBMMTk5OSAwTDE5OTkgMEwxOTk5IDYwMEwxOTk5IDYwMEwtMC42NjY3MjIgNjAwTC0wLjY2NjcyMiA2MDBMLTAuNjY2NzIyIDBMLTAuNjY2NzIyIDBaIiBmaWxsPSIjZmZlZDAwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0tMC42NjY3MjIgMEwxOTk5IDBMMTk5OSAwTDE5OTkgNDAwTDE5OTkgNDAwTC0wLjY2NjcyMiA0MDBMLTAuNjY2NzIyIDQwMEwtMC42NjY3MjIgMEwtMC42NjY3MjIgMFoiIGZpbGw9IiNmZjhjMDAiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTS0wLjY2NjcyMiAwTDE5OTkgMEwxOTk5IDBMMTk5OSAyMDBMMTk5OSAyMDBMLTAuNjY2NzIyIDIwMEwtMC42NjY3MjIgMjAwTC0wLjY2NjcyMiAwTC0wLjY2NjcyMiAwWiIgZmlsbD0iI2U0MDMwMyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNLTEgMzAyLjM2MkwzMTUuOTQ3IDYwMEwtMSA4OTcuNjM4TC0xIDMwMi4zNjJaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0tMSAzMDIuMzYyTC0xIDE1MS4xODFMNDcyLjU4OCA2MDBMLTEgMTA0OC44MkwtMSA4OTcuNjM4TDMxNS45NDcgNjAwTC0xIDMwMi4zNjJaIiBmaWxsPSIjZmZhZmM4IiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0tMSAxNTEuMTgxTC0xIDBMNjM2LjU2IDYwMEwtMSAxMjAwTC0xIDEwNDguODJMNDcyLjU4OCA2MDBMLTEgMTUxLjE4MVoiIGZpbGw9IiM3NGQ3ZWUiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTS0xIDBMNjM2LjU2IDYwMEwtMSAxMjAwTDE1OS4zMDcgMTIwMEw3OTMuODY4IDYwMEwxNTkuMzA3IDBMLTEgMFoiIGZpbGw9IiM2MTM5MTUiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTE1OS4zMDcgMEwzMTkuMjggMEw5NTMuODQxIDYwMEwzMTkuMjggMTIwMEwxNTkuMzA3IDEyMDBMNzkzLjg2OCA2MDBMMTU5LjMwNyAwWiIgZmlsbD0iIzAwMDAwMCIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4=",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjMDAwMDAwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgOTYwTDAgOTYwTDAgMFoiIGZpbGw9IiNhOWE5YTkiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCA3MjBMMCA3MjBMMCAwWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDQ4MEwwIDQ4MEwwIDBaIiBmaWxsPSIjYTdkMzc5IiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgMjQwTDAgMjQwTDAgMFoiIGZpbGw9IiMzZGE1NDIiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPC9zdmc+",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgMzAwTDAgMzAwTDAgMFoiIGZpbGw9IiMwMDAwMDAiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgOTAwTDIwMDAgOTAwTDIwMDAgMTIwMEwwIDEyMDBMMCA5MDBaIiBmaWxsPSIjODAwMDgwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDMwMEwyMDAwIDMwMEwyMDAwIDYwMEwwIDYwMEwwIDMwMFoiIGZpbGw9IiNhM2EzYTMiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPC9zdmc+",
        "TAgMEwyMDAwIDBMMjAwMCAxNzEuNDI5TDAgMTcxLjQyOUwwIDBaIiBmaWxsPSIjYzQ3OWEyIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDE3MS40MjlMMjAwMCAxNzEuNDI5TDIwMDAgMzQyLjg1N0wwIDM0Mi44NTdMMCAxNzEuNDI5WiIgZmlsbD0iI2VkYTVjZCIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAzNDIuODU3TDIwMDAgMzQyLjg1N0wyMDAwIDg1Ny4xNDNMMCA4NTcuMTQzTDAgMzQyLjg1N1oiIGZpbGw9IiNkNWM3ZTgiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgNTE0LjI4NkwyMDAwIDUxNC4yODZMMjAwMCA2ODUuNzE0TDAgNjg1LjcxNEwwIDUxNC4yODZaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDg1Ny4xNDNMMjAwMCA4NTcuMTQzTDIwMDAgMTAyOC41N0wwIDEwMjguNTdMMCA4NTcuMTQzWiIgZmlsbD0iIzlhYzdlOCIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAxMDI4LjU3TDIwMDAgMTAyOC41N0wyMDAwIDEyMDBMMCAxMjAwTDAgMTAyOC41N1oiIGZpbGw9IiM2ZDgyZDEiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPC9zdmc+",
        "TAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgMTIwMEwyMDAwIDEyMDBMMCAxMjAwTDAgMTIwMEwwIDBMMCAwWiIgZmlsbD0iIzAwMzhhOCIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDBMMjAwMCA3MjBMMjAwMCA3MjBMMCA3MjBMMCA3MjBMMCAwTDAgMFoiIGZpbGw9IiM5YjRmOTYiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgNDgwTDIwMDAgNDgwTDAgNDgwTDAgNDgwTDAgMEwwIDBaIiBmaWxsPSIjZDYwMjcwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjwvc3ZnPg==",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjNGE4MTIzIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgODAwTDAgODAwTDAgMFoiIGZpbGw9IiNmZmZmZmYiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCA0MDBMMCA0MDBMMCAwWiIgZmlsbD0iI2I1N2VkYyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4=",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjZmZkODAwIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik03MDAgNjAwQzcwMCA0MzQuMzE1IDgzNC4zMTUgMzAwIDEwMDAgMzAwQzExNjUuNjkgMzAwIDEzMDAgNDM0LjMxNSAxMzAwIDYwMEMxMzAwIDc2NS42ODUgMTE2NS42OSA5MDAgMTAwMCA5MDBDODM0LjMxNSA5MDAgNzAwIDc2NS42ODUgNzAwIDYwMFoiIGZpbGw9Im5vbmUiIGZpbGwtcnVsZT0iZXZlbm9kZCIgc3Ryb2tlPSIjNzkwMmFhIiBzdHJva2UtbGluZWNhcD0iYnV0dCIgc3Ryb2tlLWxpbmVqb2luPSJtaXRlciIgc3Ryb2tlLXdpZHRoPSIxMDAiLz4NCjwvc3ZnPg==",
        "TAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgMTIwMEwyMDAwIDEyMDBMMCAxMjAwTDAgMTIwMEwwIDBMMCAwWiIgZmlsbD0iI2EzMDI2MiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDBMMjAwMCA5NjBMMjAwMCA5NjBMMCA5NjBMMCA5NjBMMCAwTDAgMFoiIGZpbGw9IiNkMzYyYTQiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCAwTDIwMDAgNzIwTDIwMDAgNzIwTDAgNzIwTDAgNzIwTDAgMEwwIDBaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgMEwyMDAwIDQ4MEwyMDAwIDQ4MEwwIDQ4MEwwIDQ4MEwwIDBMMCAwWiIgZmlsbD0iI2ZmOWE1NiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDBMMjAwMCAyNDBMMjAwMCAyNDBMMCAyNDBMMCAyNDBMMCAwTDAgMFoiIGZpbGw9IiNkNTJkMDAiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPC9zdmc+",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMCIgZmlsbD0iIzJjMmMyYyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDkwMEwwIDkwMCIgZmlsbD0iIzljNTlkMSIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDYwMEwwIDYwMCIgZmlsbD0iI2ZjZmNmYyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8cGF0aCBkPSJNMCAwTDIwMDAgMEwyMDAwIDMwMEwwIDMwMCIgZmlsbD0iI2ZjZjQzNCIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4=",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjMjFiMWZmIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDBMMjAwMCAwTDIwMDAgODAwTDAgODAwTDAgMFoiIGZpbGw9IiNmZmQ4MDAiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgMEwyMDAwIDBMMjAwMCA0MDBMMCA0MDBMMCAwWiIgZmlsbD0iI2ZmMjE4YyIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4=",
        "TAgMEwyMDAwIDBMMjAwMCAxMjAwTDAgMTIwMEwwIDBaIiBmaWxsPSIjNWJjZWZhIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4NCjxwYXRoIGQ9Ik0wIDI0MEwyMDAwIDI0MEwyMDAwIDk2MEwwIDk2MEwwIDI0MFoiIGZpbGw9IiNmNWE5YjgiIGZpbGwtcnVsZT0iZXZlbm9kZCIvPg0KPHBhdGggZD0iTTAgNDgwTDIwMDAgNDgwTDIwMDAgNzIwTDAgNzIwTDAgNDgwWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJldmVub2RkIi8+DQo8L3N2Zz4="
    ];

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory trait = string(abi.encodePacked('{"trait_type":"Morph","value":"', flagNames[currentFlag[tokenId-1]], '"}'));
        string memory output = string(abi.encodePacked(flagPrefix, flagData[currentFlag[tokenId-1]]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Flag #', toString(tokenId), ' - ', flagNames[currentFlag[tokenId-1]], '", "description": "12-in-1 on-chain LGBTQ+ pride flags. Owner can morph the flag at any time.", "attributes": [', trait ,'], "image": "data:image/svg+xml;base64,', bytes(output), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function weaveFlags(uint8 qty, uint8 flagType) public payable nonReentrant {
        require(qty <= 100, 'EXCEEDS_TX_LIMIT');

        unchecked { 
            require(mintPrice * qty <= msg.value, 'LOW_ETHER');
            require(totalSupply() + qty <= maxTokens, 'MAX_REACHED');

            for(uint256 i = 0; i < qty; ++i) {
                currentFlag[totalSupply()+i] = flagType;
            }

            _safeMint(msg.sender, qty);
        }
    }

    /*
    * Morph the flag into a different design, numbered 0-11:
    *
    *  0 - Simple Rainbow
    *  1 - Chevron Rainbow
    *  2 - Aromantic
    *  3 - Asexual
    *  4 - Bigender
    *  5 - Bisexual
    *  6 - Genderqueer
    *  7 - Intersex
    *  8 - Lesbian
    *  9 - Non-Binary
    * 10 - Pansexual
    * 11 - Transgender
    */
    function morphFlag(uint256 tokenId, uint8 newFlagType) public nonReentrant {
        require(tokenId <= 1969, 'TOKEN_ID_TOO_HIGH');
        require(newFlagType <= 11, 'FLAG_ID_TOO_HIGH');

        unchecked { 
            require(tokenId <= totalSupply(), 'NOT_WOVEN_YET');
            require(ownerOf(tokenId) == msg.sender, 'FLAG_NOT_YOURS');
            currentFlag[tokenId-1] = newFlagType; 
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /*
    * Mint the first 69 flags to Thorne's wallet. Can only be run once.
    */
    function promoWeave() public onlyOwner {
        unchecked { 
            require(totalSupply() == 0, 'PROMO_RUN'); 

            for(uint256 i = 0; i < 69; ++i) {
                currentFlag[totalSupply()+i] = 11;
            }

            _safeMint(0x8aa986eB2F0D3b5001C9C2093698A4e13d646D5b, 69);
        }
        
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}