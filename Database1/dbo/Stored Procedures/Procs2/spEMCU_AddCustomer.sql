Create Procedure dbo.spEMCU_AddCustomer
@Customer_Code nvarchar(50),
@Customer_Name nVarChar(100),
@Consignee_Code nvarchar(50),
@Consignee_Name nVarChar(100),
@Address_1 nvarchar(255),
@Address_2 nvarchar(255),
@Contact_Name nVarChar(100),
@Contact_Phone nvarchar(50),
@Is_Active bit,
@Customer_General_1 nVarChar(25),
@Customer_General_2 nVarChar(25),
@Customer_General_3 nVarChar(25),
@Customer_General_4 nVarChar(25),
@Customer_General_5 nVarChar(25),
@Customer_Type int,
@Address_3 nvarchar(255),
@Address_4 nvarchar(255),
@City nvarchar(50),
@County nvarchar(50),
@State nvarchar(50),
@Country nvarchar(50),
@Zip nVarChar(25),
@User_Id int,
@Customer_Id int OUTPUT
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMCU_AddCustomer',
                @Customer_Code +  "," + @Customer_Name +  "," + @Consignee_Code +  "," + @Consignee_Name +  "," + @Address_1 +  "," + @Address_2 +  "," + @Contact_Name +  "," + @Contact_Phone +  "," + convert(varchar(5), @Is_Active) +  "," + @Customer_General_1+
 	    "," + @Customer_General_2 +  "," + @Customer_General_3 +  "," + @Customer_General_4 +  "," + @Customer_General_5 +  "," + convert(nVarChar(10), @Customer_Type) +  "," + @Address_3 +  "," + @Address_4 +  "," + @City +  "," + @County +  "," + @State +  "," + @Country + "," + 
                @Zip +  "," + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
insert into Customer
(
Customer_Code,
Customer_Name,
Consignee_Code,
Consignee_Name,
Address_1,
Address_2,
Address_3,
Address_4,
Contact_Name,
Contact_Phone,
Is_Active,
Customer_General_1,
Customer_General_2,
Customer_General_3,
Customer_General_4,
Customer_General_5,
Customer_Type,
City,
County,
State,
Country,
ZIP
)
values 	 (@Customer_Code,
 	 @Customer_Name,
 	 @Consignee_Code,
 	 @Consignee_Name,
 	 @Address_1,
 	 @Address_2,
 	 @Address_3,
 	 @Address_4,
 	 @Contact_Name,
 	 @Contact_Phone,
 	 @Is_Active,
 	 @Customer_General_1,
 	 @Customer_General_2,
 	 @Customer_General_3,
 	 @Customer_General_4,
 	 @Customer_General_5,
 	 @Customer_Type,
 	 @City,
 	 @County,
 	 @State,
 	 @Country,
 	 @Zip)
SELECT @Customer_Id = Scope_Identity()
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
