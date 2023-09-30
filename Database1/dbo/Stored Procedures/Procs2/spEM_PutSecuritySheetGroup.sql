CREATE PROCEDURE dbo.spEM_PutSecuritySheetGroup
  @SheetGroup_Id  int,
  @Group_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the Specerty's security group.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSecuritySheetGroup',
                Convert(nVarChar(10),@SheetGroup_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Group_Id) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  UPDATE Sheet_Groups SET Group_Id = @Group_Id WHERE Sheet_Group_Id = @SheetGroup_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
