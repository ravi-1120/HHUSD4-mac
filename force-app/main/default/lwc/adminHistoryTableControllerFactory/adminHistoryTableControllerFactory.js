import EmVaultHistoryTableController from './controllers/emVaultHistoryTableController';

const EM_VAULT = 'Em_Vault';

const getAdminHistoryTableController = (type) => {
    let ctrl = {};
    if (type === EM_VAULT) {
        ctrl = new EmVaultHistoryTableController();
    }
    return ctrl;
}

export { EM_VAULT, getAdminHistoryTableController};