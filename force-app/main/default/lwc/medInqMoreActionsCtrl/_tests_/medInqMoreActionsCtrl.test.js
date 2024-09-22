import MedInqMoreActionsCtrl from 'c/medInqMoreActionsCtrl';

describe('medInqMoreActionsCtrl', () => {
    it('sets more actions objects given in the constructor', () => {
        const moreActions = [
            { name: 'action1' },
            { name: 'action2' }
        ];
        const btnCtrl = new MedInqMoreActionsCtrl(moreActions, {});
        expect(btnCtrl.moreActions).toBe(moreActions);
    })

    describe('alignment', () => {
        it('sets the dropdown menu alignment correctly to the right in view mode', () => {
            const miCtrl = { action:'View' }
            const btnCtrl = new MedInqMoreActionsCtrl({}, miCtrl);

            expect(btnCtrl.alignment).toBe('right');
        });

        it('does not set the dropdown menu to the right value in edit/new mode', () => {
            const miCtrl = { action:'Edit' };
            const btnCtrl = new MedInqMoreActionsCtrl({}, miCtrl);

            const miCtrl2 = { action: 'Create'};
            const btnCtrl2 = new MedInqMoreActionsCtrl({}, miCtrl2);
            
            expect(btnCtrl.alignment).toBe(undefined);
            expect(btnCtrl2.alignment).toBe(undefined);
        });
    });  

})