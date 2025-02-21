pragma solidity ^0.8.0;

import {ChainlinkClient, ChainlinkRequestInterface, LinkTokenInterface} from "../../../../ChainlinkClient.sol";
import {Chainlink} from "../../../../Chainlink.sol";

contract MultiWordConsumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  bytes32 internal s_specId;
  bytes public currentPrice;

  bytes32 public usd;
  bytes32 public eur;
  bytes32 public jpy;

  uint256 public usdInt;
  uint256 public eurInt;
  uint256 public jpyInt;

  event RequestFulfilled(
    bytes32 indexed requestId, // User-defined ID
    bytes indexed price
  );

  event RequestMultipleFulfilled(bytes32 indexed requestId, bytes32 indexed usd, bytes32 indexed eur, bytes32 jpy);

  event RequestMultipleFulfilledWithCustomURLs(
    bytes32 indexed requestId,
    uint256 indexed usd,
    uint256 indexed eur,
    uint256 jpy
  );

  constructor(address _link, address _oracle, bytes32 _specId) {
    _setChainlinkToken(_link);
    _setChainlinkOracle(_oracle);
    s_specId = _specId;
  }

  function setSpecID(bytes32 _specId) public {
    s_specId = _specId;
  }

  function requestEthereumPrice(string memory, uint256 _payment) public {
    Chainlink.Request memory req = _buildOperatorRequest(s_specId, this.fulfillBytes.selector);
    _sendOperatorRequest(req, _payment);
  }

  function requestMultipleParameters(string memory, uint256 _payment) public {
    Chainlink.Request memory req = _buildOperatorRequest(s_specId, this.fulfillMultipleParameters.selector);
    _sendOperatorRequest(req, _payment);
  }

  function requestMultipleParametersWithCustomURLs(
    string memory _urlUSD,
    string memory _pathUSD,
    string memory _urlEUR,
    string memory _pathEUR,
    string memory _urlJPY,
    string memory _pathJPY,
    uint256 _payment
  ) public {
    Chainlink.Request memory req = _buildOperatorRequest(
      s_specId,
      this.fulfillMultipleParametersWithCustomURLs.selector
    );
    req._add("urlUSD", _urlUSD);
    req._add("pathUSD", _pathUSD);
    req._add("urlEUR", _urlEUR);
    req._add("pathEUR", _pathEUR);
    req._add("urlJPY", _urlJPY);
    req._add("pathJPY", _pathJPY);
    _sendOperatorRequest(req, _payment);
  }

  function cancelRequest(
    address _oracle,
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  ) public {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(_oracle);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function withdrawLink() public {
    LinkTokenInterface _link = LinkTokenInterface(_chainlinkTokenAddress());
    require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
  }

  function addExternalRequest(address _oracle, bytes32 _requestId) external {
    _addChainlinkExternalRequest(_oracle, _requestId);
  }

  function fulfillMultipleParameters(
    bytes32 _requestId,
    bytes32 _usd,
    bytes32 _eur,
    bytes32 _jpy
  ) public recordChainlinkFulfillment(_requestId) {
    emit RequestMultipleFulfilled(_requestId, _usd, _eur, _jpy);
    usd = _usd;
    eur = _eur;
    jpy = _jpy;
  }

  function fulfillMultipleParametersWithCustomURLs(
    bytes32 _requestId,
    uint256 _usd,
    uint256 _eur,
    uint256 _jpy
  ) public recordChainlinkFulfillment(_requestId) {
    emit RequestMultipleFulfilledWithCustomURLs(_requestId, _usd, _eur, _jpy);
    usdInt = _usd;
    eurInt = _eur;
    jpyInt = _jpy;
  }

  function fulfillBytes(bytes32 _requestId, bytes memory _price) public recordChainlinkFulfillment(_requestId) {
    emit RequestFulfilled(_requestId, _price);
    currentPrice = _price;
  }

  function publicGetNextRequestCount() external view returns (uint256) {
    return _getNextRequestCount();
  }
}
