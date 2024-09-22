import VeevaMessageService from 'c/veevaMessageService';
import VeevaSessionService from 'c/veevaSessionService';
import { flushPromises } from "c/veevaTestUtils";
import ReassignmentDataService from '../reassignmentDataService';


const vodInfo = {
    mcServer: "https://test.com", 
    mcVersion: "0", 
    sfSession: "sessionId", 
    sfEndpoint: "https://test.com/"
};

const mockXHR = {
    open: jest.fn(),
    send: jest.fn(),
    setRequestHeader: jest.fn(),
    onload: jest.fn(),
    onError: jest.fn(),
    readyState: 4,
    responseText: JSON.stringify(
      { data: {} }
    )
};

const awDomainUrl = 'https://aw-domain-url.com';

window.XMLHttpRequest = jest.fn(() => mockXHR);

describe('c-reassignment-data-service', () => {
    const sessionSvc = new VeevaSessionService();
    const sessionSvcCall = jest.spyOn(sessionSvc, 'getVodInfo').mockReturnValue(vodInfo);
    const messageSvc = new VeevaMessageService();
    const dataSvc = new ReassignmentDataService(sessionSvc, messageSvc, ['WeChat'], awDomainUrl);

    it('requests get table data', async () => {
        const response = dataSvc.getTableData();
        await flushPromises();
        expect(sessionSvcCall).toHaveBeenCalledTimes(1);
        expect(response).not.toBeUndefined();
    });

})