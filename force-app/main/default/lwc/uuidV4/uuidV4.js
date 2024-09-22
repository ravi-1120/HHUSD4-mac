export default function uuidV4() {
    // Generates 16 random numbers in the range [0, 255]
    const randomDecimals = new Uint8Array(16);
    crypto.getRandomValues(randomDecimals);

    // UUIDv4 dictates that first 4 bits of 7th byte be '0100', and first 2 bits of 9th byte be '10'
    randomDecimals[6] = (randomDecimals[6] & 0x0f) | 0x40;
    randomDecimals[8] = (randomDecimals[8] & 0x3f) | 0x80;

    return randomDecimals.reduce((uuid, randomDec, index) => {
        // Convert each random number into a string of its 2 digit hex representation
        uuid += randomDec.toString(16).padStart(2, '0');

        // Insert hyphens at appropriate indices to match UUID format of XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        if (index === 3 || index === 5 || index === 7 || index === 9) {
            uuid += '-';
        }

        return uuid;
    }, '');
}