CREATE PROCEDURE dbo.spEM_EUCreateConversion
 	 @ConversionDesc 	 nvarchar(255),
  @FromEngId      	 Int,
  @ToEngId       	 Int,
  @Slope       	  	 Float,
  @Intercept     	 Float,
  @CustSQL      	  	 nvarchar(1000),
  @User_Id        int,
  @ConvId         	 int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
  DECLARE @Insert_Id integer
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'CreateConversion',
        Convert(nVarChar(10), @FromEngId) + ',' +
        Convert(nVarChar(10), @ToEngId) + ',' +
        IsNull(Convert(nVarChar(10), @Slope),'Null') + ',' +
        IsNull(Convert(nVarChar(10), @Intercept),'Null') + ',' +
        IsNull(substring(@CustSQL,1,100),'Null') + ',' +
 	      Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
BEGIN TRANSACTION
INSERT INTO Engineering_Unit_Conversion (Conversion_Desc,From_Eng_Unit_Id,To_Eng_Unit_Id,Slope,Intercept,Custom_Conversion)
VALUES (@ConversionDesc,@FromEngId,@ToEngId, @Slope,@Intercept,@CustSQL)
Select @ConvId = Null
SELECT @ConvId = Eng_Unit_Conv_Id FROM Engineering_Unit_Conversion WHERE From_Eng_Unit_Id = @FromEngId and To_Eng_Unit_Id = @ToEngId
IF @ConvId IS NULL
BEGIN
 	 ROLLBACK TRANSACTION
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	 RETURN(1)
END
COMMIT TRANSACTION
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@ConvId) where Audit_Trail_Id = @Insert_Id
RETURN(0)
