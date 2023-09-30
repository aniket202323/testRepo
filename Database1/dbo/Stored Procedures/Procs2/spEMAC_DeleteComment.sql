Create Procedure dbo.spEMAC_DeleteComment
@Comment_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_DeleteComment',
             Convert(nVarChar(10),@Comment_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
-- Delete an existing Comment from the Comments table by Comment_Id
   Update Comments
      Set Comment = '',
          ShouldDelete = 1
      Where @Comment_Id = Comment_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
