// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title KipuBank
 * @dev Contrato inteligente para armazenamento de ethers.
 */
contract KipuBank {
    // Mapeamento para armazenar o saldo de cada conta.
    mapping(address => uint256) public bankAccounts;

    // Limite máximo de saldo total no banco.
    uint256 public immutable i_bankCap;

    // Limite fixo para saques individuais.
    uint256 public constant WITHDRAW_LIMIT = 10 ether;

    // Eventos para registrar depósitos e saques.
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    // Erros personalizados para validações.
    error InsufficientFunds();
    error NullAmount();
    error WithdrawLimitReached();
    error BankCapIsFull();
    error InvalidBankCap();
    error TransferFailed();

    /**
     * @dev Construtor que inicializa o limite máximo de saldo do banco.
     * @param _bankCap O valor máximo permitido como saldo total do banco.
     */
    constructor(uint256 _bankCap) {
        if (_bankCap == 0) revert InvalidBankCap();
        i_bankCap = _bankCap;
    }

    /**
     * @dev Modificador que verifica se o depósito é válido.
     * Reverte se o valor for zero.
     * @param _amount O valor do depósito.
     */
    modifier DepositCheck(uint256 _amount) {
        if (_amount == 0) revert NullAmount();
        _;
    }

    /**
     * @dev Modificador que verifica se o saque é válido.
     * Reverte se o saldo for insuficiente, se o valor exceder o limite de saque, ou se o valor for zero.
     * @param _amount O valor do saque.
     * @param _account O endereço da conta que está sacando.
     */
    modifier WithdrawCheck(uint256 _amount, address _account) {
        if (_amount > bankAccounts[_account]) revert InsufficientFunds();
        if (_amount > WITHDRAW_LIMIT) revert WithdrawLimitReached();
        if (_amount == 0) revert NullAmount();
        _;
    }

    /**
     * @dev Permite que os usuários depositem fundos no banco.
     * Reverte se o depósito ultrapassar o limite total do banco.
     * Emite um evento `Deposit` ao realizar o depósito.
     */
    function deposit() public payable DepositCheck(msg.value) {
        if (msg.value + address(this).balance > i_bankCap) revert BankCapIsFull();
        bankAccounts[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Permite que os usuários saquem fundos de sua conta.
     * Reverte em caso de falha na transferência.
     * Emite um evento `Withdraw` ao realizar o saque.
     * @param _amount O valor do saque.
     */
    function withdraw(uint256 _amount)
        public
        WithdrawCheck(_amount, msg.sender)
    {
        bankAccounts[msg.sender] -= _amount;
        transferETH(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev Retorna o saldo da conta do chamador.
     * @return O saldo atual da conta do chamador.
     */
    function getAccountBalance() public view returns (uint256) {
        return bankAccounts[msg.sender];
    }

    /**
     * @dev Retorna o saldo total armazenado no contrato.
     * @return O saldo total em ETH no contrato.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Função interna para transferir ETH para um endereço especificado.
     * Reverte em caso de falha na transferência.
     * @param _to O endereço do destinatário.
     * @param _amount O valor a ser transferido.
     */
    function transferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }
}