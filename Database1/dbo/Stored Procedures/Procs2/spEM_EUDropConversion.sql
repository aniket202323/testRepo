CREATE PROCEDURE dbo.spEM_EUDropConversion
  @ConvId         	 int,
  @User_Id        int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
DECLARE @Insert_Id integer
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EUDropConversion',
 	 Convert(nVarChar(10), @ConvId) + ',' +
 	 Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
Declare @OldConvId 	 Int
Select @OldConvId = @ConvId
BEGIN TRANSACTION
DELETE FROM Engineering_Unit_Conversion WHERE Eng_Unit_Conv_Id = @ConvId
SELECT @ConvId = Null
SELECT @ConvId = Eng_Unit_Conv_Id FROM Engineering_Unit_Conversion WHERE Eng_Unit_Conv_Id = @OldConvId
IF @ConvId IS Not NULL 
BEGIN
 	 ROLLBACK TRANSACTION
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	 RETURN(1)
END
COMMIT TRANSACTION
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@ConvId) where Audit_Trail_Id = @Insert_Id
RETURN(0)
