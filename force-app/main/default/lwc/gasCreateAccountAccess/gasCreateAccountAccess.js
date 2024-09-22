export default class GasCreateAccountAccess {
  static NETWORK_CUSTOMER_MASTER_MODE_DISABLED = '0';
  static DCR_MODE_DISABLED = '0';
  static DCR_MODE_ENABLED = '1';
  static DCR_MODE_SHADOW_ACCTS = '2';
  static NON_DISABLED_DCR_MODES = [this.DCR_MODE_ENABLED, this.DCR_MODE_SHADOW_ACCTS];

  static isAccountNotCreateable(canCreateAccount, canCreateDCR, canCreateDCRLine, canQueryDCRFieldType, customSettingValues) {
    let cannotCreateRecord = true;
    const { networkCustomerMasterMode, hasNoManagedAccountTypeSettings, dcrMode } = customSettingValues;
    if (
      canCreateAccount &&
      (hasNoManagedAccountTypeSettings === 'true' || GasCreateAccountAccess.dcrDisabledAndNoNetwork(networkCustomerMasterMode, dcrMode))
    ) {
      cannotCreateRecord = false;
    } else if (this.NON_DISABLED_DCR_MODES.includes(dcrMode) && canCreateDCR && canCreateDCRLine && canQueryDCRFieldType) {
      cannotCreateRecord = false;
    }
    return cannotCreateRecord;
  }

  static dcrDisabledAndNoNetwork(networkCustomerMasterMode, dcrMode) {
    return networkCustomerMasterMode === this.NETWORK_CUSTOMER_MASTER_MODE_DISABLED && dcrMode === this.DCR_MODE_DISABLED;
  }
}