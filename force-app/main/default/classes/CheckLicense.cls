public with sharing class CheckLicense {
    public Id userId;
    private copado.GlobalAPI.UserLicense userLicense;

    // CTOR

    public CheckLicense(Id userId) {
        this.userId = userId;
        this.userLicense = getUserLicense(userId);
    }

    // PUBLIC

    public Boolean has(String license) {
        switch on license {
            when 'Compliance Hub' {
                return userLicense.isCCHenabled;
            }
            when 'Copado User' {
                return userLicense.isCCMenabled;
            }
            when 'Copado Admin' {
                return userLicense.isCopadoEnabled;
            }
            when 'Selenium Testing' {
                return userLicense.isCSTenabled;
            }
            when else {
                return false;
            }
        }
    }

    public static Boolean areLicensesExceeded() {
       copado.GlobalAPI.CopadoLicenses licenseInformation =  getLicenseInformation();

       if(licenseInformation.usedCADLicenses > licenseInformation.totalNumberOfCADLicenses || licenseInformation.usedCCHLicenses > licenseInformation.totalNumberOfCCHLicenses || licenseInformation.usedCCMLicenses > licenseInformation.totalNumberOfCCMLicenses || licenseInformation.usedCSTLicenses > licenseInformation.totalNumberOfCSTLicenses || licenseInformation.usedCopadoLicenses > licenseInformation.totalNumberOfCopadoLicenses) {
            return true;
       }
       return false;
    }

    // PRIVATE

    private static copado.GlobalAPI.CopadoLicenses getLicenseInformation() {
       return new copado.GlobalAPI().getLicenseInformation();
    }

    private copado.GlobalAPI.UserLicense getUserLicense(Id userId) {
        copado.GlobalAPI.UserLicense result = new copado.GlobalAPI.UserLicense();

        for (copado.GlobalAPI.UserLicense userLicense : new copado.GlobalAPI().listCopadoLicenses()) {
            if (userLicense.userId == userId) {
                result = userLicense;
                break;
            }
        }

        return result;
    }
}