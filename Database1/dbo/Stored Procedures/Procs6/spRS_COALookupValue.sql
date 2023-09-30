Create Procedure dbo.spRS_COALookupValue
@WAC_Id int, 
@ID int,
@User_Id int,
@Value varchar(255) OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COALookupValue',
             Convert(varchar(10),@WAC_Id) + ','  + 
             Convert(varchar(10),@Id) + ','  + 
             @Value + ',' +
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Declare @ED_Field_Type_Id int
Select @ED_Field_Type_Id = ED_Field_Type_Id From Web_App_Criteria
Where WAC_Id = @WAC_Id
if @ED_Field_Type_Id = 35
  BEGIN
    Select @Value = Customer_Name 
      From Customer 
      Where Customer_Id = @Id
  END
else if @ED_Field_Type_Id = 36
  BEGIN
    Select @Value = Prod_Desc 
      From Products 
      Where Prod_Id = @Id
  END
else if @ED_Field_Type_Id = 37
  BEGIN
    Select @Value = Product_Grp_Desc 
      From Product_Groups 
      Where Product_Grp_Id = @Id
  END
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
