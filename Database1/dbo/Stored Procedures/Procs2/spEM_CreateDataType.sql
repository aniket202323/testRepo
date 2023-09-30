CREATE PROCEDURE dbo.spEM_CreateDataType
  @Description  nvarchar(50),
  @User_Id int,
  @Data_Type_Id int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create data type.
  --
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateDataType',
                 @Description + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  INSERT INTO Data_Type(Data_Type_Desc) VALUES(@Description)
  SELECT @Data_Type_Id = Scope_Identity()
  IF @Data_Type_Id IS NULL
 	 BEGIN
 	    Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	    RETURN(1)
 	 END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Data_Type_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
