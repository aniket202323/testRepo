Create Procedure dbo.spRS_COALookupField
@WAC_Id int, 
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COALookupField',
             Convert(varchar(10),@WAC_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Declare @ED_Field_Type_Id int
Select @ED_Field_Type_Id = ED_Field_Type_Id From Web_App_Criteria
Where WAC_Id = @WAC_Id
if @ED_Field_Type_Id = 35
  BEGIN
    Select Customer_Id AS ID, Customer_Name AS "Customers" 
      From Customer
      Order By Customer_Name ASC
  END
else if @ED_Field_Type_Id = 36
  BEGIN
    Select Prod_Id AS ID, Prod_Desc AS "Products" 
      From Products
      Order By Prod_Desc ASC
  END
else if @ED_Field_Type_Id = 37
  BEGIN
    Select Product_Grp_Id AS ID, Product_Grp_Desc AS "Product Groups" 
      From Product_Groups
      Order By Product_Grp_Desc ASC
  END
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id 
