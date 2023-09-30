CREATE PROCEDURE dbo.spEM_EUPut
  @EngUnitId     int,
  @EngUnitDesc   nvarchar(50),
  @EngUnitCode   nvarchar(15),
  @User_Id       int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
  DECLARE @Insert_Id integer
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EUPut',
 	  	  	  	  	  	  	  	 Isnull(convert(nVarChar(10),@EngUnitId),'Null') + ',' +
                @EngUnitDesc  + ',' + 
 	  	  	  	  	  	  	  	 @EngUnitCode + ',' +
 	       	  	  	  	  	 Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
  Update Engineering_Unit Set Eng_Unit_Desc = @EngUnitDesc,Eng_Unit_Code = @EngUnitCode Where  Eng_Unit_Id  = @EngUnitId 
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@EngUnitId) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
