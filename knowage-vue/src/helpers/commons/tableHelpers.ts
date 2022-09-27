export function setInputDataType(columnType: string) {
    switch (columnType) {
        case 'int':
        case 'float':
        case 'decimal':
        case 'long':
            return 'number'
        case 'date':
            return 'date'
        default:
            return 'text'
    }
}

export function getInputStep(dataType: string) {
    if (dataType === 'float') {
        return '.01'
    } else if (dataType === 'int') {
        return '1'
    } else {
        return 'any'
    }
}

export const numberFormatRegex = '^(####|#\.###|#\,###){1}([,.]?)(#*)$' //eslint-disable-line no-useless-escape 

export const formatNumber = (column: any) => {
    if (!column.format) return null

    const result = column.format.trim().match(numberFormatRegex)
    if (!result) return null

    const useGrouping = result[2] === '.' || result[2] === ','
    const maxFractionDigits = result[3].length
    const configuration = { useGrouping: useGrouping, minFractionDigits: maxFractionDigits, maxFractionDigits: maxFractionDigits }

    return configuration

}