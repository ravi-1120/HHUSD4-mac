export class NoFeatureAccessError extends Error {
    constructor(message) {
        super(message);
    }
}

export class ImplicitAccessError extends Error {
    constructor(message) {
        super(message);
    }
}

export const ERROR_TYPES = {
    IMPLICIT_ACCESS: 'ImplicitAccess',
    NO_ACCESS: 'NoAccess',
};