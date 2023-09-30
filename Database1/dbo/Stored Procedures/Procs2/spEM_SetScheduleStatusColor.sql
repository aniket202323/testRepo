CREATE PROCEDURE dbo.spEM_SetScheduleStatusColor
  @PP_Status_Id int,
  @Color_Id int,
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_SetScheduleStatusColor',
                Convert(nVarChar(10),@PP_Status_Id) + ','  + 
                Convert(nVarChar(10),@Color_Id) + ','  + 
             	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Production_Plan_Statuses SET Color_Id = @Color_Id WHERE PP_Status_Id = @PP_Status_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
