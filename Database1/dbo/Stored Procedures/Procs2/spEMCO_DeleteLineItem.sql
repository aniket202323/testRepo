Create Procedure dbo.spEMCO_DeleteLineItem
@ID int,
@User_Id int
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEMCO_DeleteLineItem' ,
                convert(nVarChar(10), @ID) +  "," + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
Declare @Comment_Id int
Select @Comment_Id = Comment_Id from Customer_Order_Line_Items where Order_Line_Id = @ID
exec spCSS_InsertDeleteComment @ID, 29, 1, 1, null,@Comment_Id
update Comments
set ShouldDelete = 1
where Comment_Id = @Comment_Id
delete from Customer_Order_Line_Specs
where Order_Line_Id = @ID
delete from Customer_Order_Line_Items 
where Order_Line_Id = @ID
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
