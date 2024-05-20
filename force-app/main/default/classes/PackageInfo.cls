@SuppressWarnings('PMD.TooManyFields, PMD.VariableNamingConventions')
public class PackageInfo {
  public Pkg pkg;
  public List<Versions> versions;

  //PUBLIC
  public static PackageInfo parse(String json) {
    return (PackageInfo) System.JSON.deserialize(json, PackageInfo.class);
  }

  //INNER
  public class Versions {
    public String Package2Id;
    public String Branch;
    public String Tag;
    public Integer MajorVersion;
    public Integer MinorVersion;
    public Integer PatchVersion;
    public Integer BuildNumber;
    public String Id;
    public String SubscriberPackageVersionId;
    public String Name;
    public String NamespacePrefix;
    public String Package2Name;
    public String Description;
    public String Version;
    public Boolean IsPasswordProtected;
    public Boolean IsReleased;
    public String CreatedDate;
    public String LastModifiedDate;
    public String InstallUrl;
    public String CodeCoverage;
    public Boolean ValidationSkipped;
    public String AncestorId;
    public String AncestorVersion;
    public String Alias;
  }

  public class Pkg {
    public String Id;
    public String SubscriberPackageId;
    public String Name;
    public String Description;
    public String NamespacePrefix;
    public String ContainerOptions;
    public String Alias;
    public String IsOrgDependent;
  }
}