CREATE PROCEDURE dbo.spEM_EURenameConversion
  @ConvId   int,
  @ConvDesc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EURenameConversion',
                Convert(nVarChar(10),@ConvId) + ','  + 
                @ConvDesc + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	 Update Engineering_Unit_Conversion Set Conversion_Desc = @ConvDesc Where Eng_Unit_Conv_Id = @ConvId
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
