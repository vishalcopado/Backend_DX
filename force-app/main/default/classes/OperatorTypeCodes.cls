public with sharing class OperatorTypeCodes {
    public static Map<String, String> getOperatorSymbols() {
        Map<String, String> operatorSymbol = new Map<String, String>{
            '' => '--None--',
            'e' => ' = ',
            'n' => ' != ',
            's' => ' LIKE ',
            'c' => ' LIKE ',
            'k' => ' LIKE ',
            'l' => ' < ',
            'g' => ' > ',
            'm' => ' <= ',
            'h' => ' >= ',
            'u' => 'includes',
            'x' => 'excludes',
            'w' => 'within'
        };
        return operatorSymbol;
    }

    public static Map<String, String> getOperatorCodes() {
        Map<String, String> operatorCodes = new Map<String, String>{
            '' => '--None--',
            'e' => 'equals',
            'n' => 'not equal to',
            's' => 'starts with',
            'c' => 'contains',
            'k' => 'does not contain',
            'l' => 'less than',
            'g' => 'greater than',
            'm' => 'less or equal',
            'h' => 'greater or equal',
            'u' => 'includes',
            'x' => 'excludes',
            'w' => 'within'
        };
        return operatorCodes;
    }

    public static Map<String, String[]> getTypeToOps() {
        Map<String, String[]> type2ops = new Map<String, String[]>{
            'REFERENCE' => new List<String>{ 'e', 'n' },
            'ID' => new List<String>{ 'e', 'n' },
            'STRING' => new List<String>{ 'e', 'n', 's', 'c', 'k' },
            'PICKLIST' => new List<String>{ 'e', 'n', 's', 'c', 'k' },
            'PERCENT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'DOUBLE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'BOOLEAN' => new List<String>{ 'e', 'n' },
            'TEXTAREA' => new List<String>{ 'e', 'n', 's', 'c', 'k' },
            'DATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'DATETIME' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            //'MULTIPICKLIST' => new String[]{'e', 'n', 'u', 'x'},
            'ANYTYPE' => new List<String>{ 'e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w' },
            'BASE64BINARY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'INTEGER' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'INT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'TIME' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'ADDRESS' => new List<String>{ 'w', 'y' },
            'ADDRESSCOUNTRY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'ADDRESSSTATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'AUTONUMBER' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'BIRTHDAY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'BITVECTOR' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'CONTENT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'CURRENCY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'CURRENCYCODE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'DATACATEGORYGROUPREFERENCE' => new List<String>{ 'e', 'n' },
            'DATEONLY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'DIVISION' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'DUEDATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'DYNAMICENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'EMAIL' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'ENCRYPTEDTEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'ENTITYID' => new List<String>{ 'e', 'n', 's' },
            'ENUMORID' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'EXTERNALID' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'FAX' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'HTMLMULTILINETEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'HTMLSTRINGPLUSCLOB' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'INETADDRESS' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'LOCATION' => new List<String>{ 'w', 'y' },
            'MULTIENUM' => new List<String>{ 'e', 'n', 'u', 'x' },
            'MULTILINETEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'PHONE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'RECORDTYPE' => new List<String>{ 'e', 'n' },
            'SFDCENCRYPTEDTEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'SIMPLENAMESPACE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'STATICENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'STRINGPLUSCLOB' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'TEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'TEXTENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
            'TIMEONLY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
            'URL' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' }
        };
        return type2ops;
    }
}