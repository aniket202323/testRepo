CREATE PROCEDURE dbo.spEM_CreateSheet
  @Sheet_Desc nvarchar(50),
  @Sheet_Type integer,
  @Event_Type integer,
  @Sheet_GroupId integer,
  @User_Id        Integer,
  @Sheet_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create sheet.
  --
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSheet',
                 @Sheet_Desc + ','  + 
 	    Convert(nVarChar(10), @Event_Type)  + ','  + 
 	    Convert(nVarChar(10), @Sheet_Type)  + ','  + 
 	    Convert(nVarChar(10), @Sheet_GroupId)  + ','  + 
 	    Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
 	 INSERT INTO Sheets(Sheet_Desc_Local,Event_Type,Sheet_Type,Sheet_Group_Id,Max_Edit_Hours)
 	  	 VALUES(@Sheet_Desc,@Event_Type,@Sheet_Type,@Sheet_GroupId,0)
 	 SELECT @Sheet_Id = Sheet_Id From Sheets Where Sheet_Desc = @Sheet_Desc
 	 IF @Sheet_Id IS NULL
 	 BEGIN
 	  	 ROLLBACK TRANSACTION
 	  	 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	  	 RETURN(1)
 	 END
 	 If (@@Options & 512) = 0
 	 BEGIN
 	  	 Update Sheets set Sheet_Desc_Global = Sheet_Desc_Local where Sheet_Id = @Sheet_Id
 	 END
 	 COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Sheet_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
