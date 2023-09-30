CREATE PROCEDURE dbo.spEM_EUCreate
  @EngUnitDesc      nvarchar(50),
  @EngUnitCode      nvarchar(15),
  @User_Id        int,
  @EngUnitId        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EUCreate',
                 @EngUnitDesc  + ',' +
 	      Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  Insert into Engineering_Unit(Eng_Unit_Desc,Eng_Unit_Code) VALUES(@EngUnitDesc,@EngUnitCode)
  SELECT @EngUnitId = Eng_Unit_Id FROM Engineering_Unit WHERE Eng_Unit_Desc = @EngUnitDesc
  IF @EngUnitId IS NULL
    BEGIN
     ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@EngUnitId) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
