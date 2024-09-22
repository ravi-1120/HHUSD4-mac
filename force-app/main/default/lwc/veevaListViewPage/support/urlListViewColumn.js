import DefaultListViewColumn from "./defaultListViewColumn";

export default class UrlListViewColumn extends DefaultListViewColumn {

    htmlEncode = false;
    
    _renderer({ value }) {
        let link = null;
        const urlValue = value?.value;
        if (urlValue) {
            let url;
            if (urlValue.startsWith('http://') || urlValue.startsWith('https://')) {
                url = new URL(urlValue).toString();
            } else {
                url = new URL(`http://${urlValue}`).toString();
            }
            link = `<a href="${url}" target="_blank">${urlValue}</a>`; 
        }
        return link;
    }
}