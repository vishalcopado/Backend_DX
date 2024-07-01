/**
* @description       : This is used to collect Order created from Direct sales shopping 
and send them for survey in class "CC_Med_DataForDiectSalesSurvey"                       
*                      contact William flodin/Ashford Richard before modifying any logic
* @author            : Vedprakash Kushwah
* @group             : CustomerCareTeam 
* @last modified on  : 01-19-2023
* @author            : Vedprakash Kushwah
* @group             : CustomerCareTeam 
* @last modified on  : 04-05-2023
* @last modified on  : 16-05-2023 # PBI 3334205 : Enhance the Sign-up & Shopping payload
* @last modified on  : 02-06-2023 # BUG 3436979
* @last modified on  : 02-07-2023 # PBI 3405230 Add "Retailer Code" to metadata - Experience Study/Sign-up & Shop 
* @last modified on  : 03-14-2024
* @last modified by  : Sagar Tungal 
* Modifications Log  : Add "Local Send Time" & "Time Zone" to metadata to be able to schedule send out of surveys.PBI#3469691
* Modifications Log  : By Ashish Singh on 03-25-2024
                     : 1. Added Utility class to promote reusability of common apex methods
					 : 2. Putted locTime check to avoid null value for BUG#3864864
**/
public without sharing class CC_Med_DataForDiectSalesSurvey {
    public static Id ccSurvey = SchemaUtility.getRecordTypeIdByDeveloperName('Medallia_Survey__c', 'Customer_Care');
    public static Map<Id,OrderItem> orderwithVeh = New Map<Id,OrderItem>();
    public static Map<String,String> areaCdMap;
    public static Map<String,String> timeZnFinalMap;
    
    public static Void collectDataForDirectSalesSurvey(List<Order> OrderList, Map<String,CC_Medallia_Car_Handover__mdt> carHandovrMdtMap){
        List<Medallia_Survey__c > collectedData = New List<Medallia_Survey__c >();   
        //Create Medallia Survey records from Order
        List<Order > collectedOrderData = New List<Order >();
        List<Id > collectedVehId = New List<Id >();
        //Get the volvoId from Identifier # 3334205
        Map<Id,Order> AccountWithOrder = New Map<Id,Order>();
        Map<Id,String> orderIdentifier = New Map<Id,String>();
        areaCdMap = new Map<String,String>();
        timeZnFinalMap = new Map<String,String>();
         
        for (Order ords: OrderList){
            
            AccountWithOrder.put(ords.B2B_Person_Account__c, ords);  
            collectedOrderData.add(ords);
            collectedVehId.add(ords.Vehicle__c);            
        }
        Id recordTypeIdAccountIden = Schema.SObjectType.AlternativeIdentifier__c.getRecordTypeInfosByDeveloperName().get('Volvo_Id').getRecordTypeId();
        
        for (AlternativeIdentifier__c Alte : [SELECT Account__c,Active__c,FIN_Number__c,CreatedDate,FIN_Status__c,FIN_Type__c,Id,My_Volvo_Id__c,Name,RecordTypeId,VCC_Market__c FROM AlternativeIdentifier__c WHERE Account__c =: AccountWithOrder.keySet()  AND RecordTypeId =: recordTypeIdAccountIden   ]){
            
            String Ident ; 
            if(AccountWithOrder.containsKey(Alte.Account__c) ) {
                if(!OrderIdentifier.containsKey(Alte.Account__c)){
                    Ident= Alte.My_Volvo_Id__c;
                    
                    OrderIdentifier.put(Alte.Account__c, Ident); 
                    
                }else{
                    Ident= OrderIdentifier.get(Alte.Account__c) +  ';' + Alte.My_Volvo_Id__c; 
                    OrderIdentifier.put(Alte.Account__c, Ident); 
                    
                } 
                
            }   
            OrderIdentifier.put(AccountWithOrder.get(Alte.Account__c).id, Ident); 
        }
        // To get Model code and model year from OrderItem #3334205
        // Added the filter of produc name after bug#3461166
        for (OrderItem OrdIm : [SELECT OrderId, Model_Code__c,Model_Year__c,PNO34_including_Option_Codes__c,Product2.Name FROM OrderItem  WHERE OrderId =: collectedOrderData AND Product2.Name=:SYSTEM.Label.CCCMProductName]){
            orderwithVeh.put(OrdIm.OrderId, OrdIm);
        }
        //Retriving Country Config Metadata
        areaCdMap = CCCM_Med_Utility.getAreaCodes();
        //Retriving timezoneoffset with areacode
        timeZnFinalMap = CCCM_Med_Utility.getTimeZoneOffsetsMaps(areaCdMap.values());
        for (Order ordr : OrderList){
            Medallia_Survey__c  mdDrives;
            	mdDrives = prepareInviteData(ordr,'40',carHandovrMdtMap);  
            	mdDrives.Alternative_Identifier_Id__c= orderIdentifier.get(ordr.Id);
            
            collectedData.add(mdDrives);
        }
        
        if(collectedData.size()>0){
            insert collectedData; 
        }
    }
    
    //Creation method to create Medallia Survey Record
    public static Medallia_Survey__c prepareInviteData( Order ast, String evtcode, Map<String,CC_Medallia_Car_Handover__mdt> carHandovrMdtMap){
        
        
        Medallia_Survey__c  mdSurevyRec = New Medallia_Survey__c ();
        mdSurevyRec.VIN__c = ast.Vehicle__r.VIN__c != null ? ast.Vehicle__r.VIN__c : '';
        mdSurevyRec.RecordTypeId = ccSurvey;
        //mdSurevyRec.Market_Code__c  = ast.Vehicle__r.Market__c != null ? ast.Vehicle__r.Market__c : '';
        //Get VCC market from Account based on Asset Account#3030012
        mdSurevyRec.Market_Code__c  = ast.B2B_Person_Account__r.VCC_Market__c != null ? ast.B2B_Person_Account__r.VCC_Market__c : '';
        mdSurevyRec.Event_Date__c  = CCCM_Med_Utility.doDateConversion(ast.EffectiveDate);
        // Added fields Model code, model year, Engine code and DCOM Order number # 3334205
        // Checks the model code, model year from vehicle object, if null fetches from OrderItem
        if(!orderwithVeh.isEmpty() && orderwithVeh.containsKey(ast.Id)){
            
            if(!String.isBlank(orderwithVeh.get(ast.Id).Model_Code__c) ){
                mdSurevyRec.Vehicle_Model_Code__c  =  orderwithVeh.get(ast.Id).Model_Code__c  ;
            }
            else{
                if(!String.isBlank(ast.Vehicle__r.Model_Code__c)){
                    mdSurevyRec.Vehicle_Model_Code__c  = ast.Vehicle__r.Model_Code__c ;
                }
                
            }
            if(!String.isBlank(ast.Vehicle__r.Model_Year__c)){
                mdSurevyRec.Model_Year__c = ast.Vehicle__r.Model_Year__c  ;
            }
            else{
                
                if(!String.isBlank(orderwithVeh.get(ast.Id).Model_Year__c)){
                    mdSurevyRec.Model_Year__c  =  orderwithVeh.get(ast.Id).Model_Year__c ;
                }
                
            }
            // removed substring function attached to the field PN034 when checking null condition 3436979
            if(!String.isBlank(orderwithVeh.get(ast.Id).PNO34_including_Option_Codes__c)){
                mdSurevyRec.Engine_Code__c  = orderwithVeh.get(ast.Id).PNO34_including_Option_Codes__c.SubString(3,5) ;
            }
        }
        mdSurevyRec.License_Plate__c   = !String.isBlank(ast.Vehicle__r.License_Plate__c) ? ast.Vehicle__r.License_Plate__c : '';
        mdSurevyRec.Account__c = ast.B2B_Person_Account__c;
        mdSurevyRec.Field_Set_Name__c  = 'Med_VehicleHandover_Survey';
        mdSurevyRec.Event_Code__c = evtcode; 
        mdSurevyRec.CbV_Customer__c =ast.Vehicle__r.Care_by_Volvo_Vehicle__c ; 
        mdSurevyRec.Sync_Status__c = 'New';
     //   # PBI 3405230 Add "Retailer Code" to metadata - Experience Study/Sign-up & Shop 
        if(ast.Sales_Channel__c == 'Web'){
            mdSurevyRec.Retailer_Code__c =  carHandovrMdtMap.get(ast.B2B_Person_Account__r.VCC_Market__c).CCCPA_Retailer_Code__c;
        }else{
            mdSurevyRec.Retailer_Code__c = ast.Selling_Retailer__r.DealerCodeLink__c != null ? ast.Selling_Retailer__r.DealerCodeLink__c : '';
        }
        mdSurevyRec.Survey_Triggering_Date__c = system.today();
        mdSurevyRec.Order_Type__c = ast.Type ;
        mdSurevyRec.Sales_Model__c=ast.Sales_Model__c;
        mdSurevyRec.Salesman_Id__c=ast.Retailer_Sales_Consultant__r.Name;
        mdSurevyRec.CC_Sales_Channel__c=ast.Sales_Channel__c;
        mdSurevyRec.CC_Vehicle_Type__c=ast.Car_Type__c;
        mdSurevyRec.Order_Group_Type__c=ast.Order_Group_Type__c;
        mdSurevyRec.DCOM_Order_No__c=ast.DCOM_Order_No__c;
        
        //String country_areaCode = '';
        String finalTimeZone = '';
        if(areaCdMap.containsKey(mdSurevyRec.Market_Code__c)){
            String country_areaCode = areaCdMap.get(mdSurevyRec.Market_Code__c);//get countrycode from custom metadata based upon market
            if(timeZnFinalMap.containsKey(country_areaCode)){
                finalTimeZone = timeZnFinalMap.get(country_areaCode);// get offset value
            }
        }
        
        if(carHandovrMdtMap.ContainsKey(ast.B2B_Person_Account__r.VCC_Market__c) && carHandovrMdtMap.get(ast.B2B_Person_Account__r.VCC_Market__c).Local_Send_Time__c != null){//So if there is no any value in metadta, then leave this field as blank
            mdSurevyRec.Local_Send_Time__c = string.valueOf(system.today()) + ' ' +carHandovrMdtMap.get(ast.B2B_Person_Account__r.VCC_Market__c).Local_Send_Time__c + ' '+finalTimeZone;
        }

        return mdSurevyRec;
        
    }    
}