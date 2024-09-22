const getNextStepsHTMLContent = async (pageCtrl) => {
    const nextStepsMessage = pageCtrl.nextSteps;
    let nextStepsText = null;
    if (nextStepsMessage) {
        const [key, category] = nextStepsMessage.split(';;');
        nextStepsText = await pageCtrl.getMessageWithDefault(key, category, null);
    }
    return nextStepsText;
}

const getNextStepsTitle = async (pageCtrl) => {
    const key = 'NEXT_STEPS';
    const category = 'EVENT_MANAGEMENT';
    const defaultMessage = 'Next Steps';
    return pageCtrl.getMessageWithDefault(key, category, defaultMessage);
}

export { getNextStepsHTMLContent, getNextStepsTitle };