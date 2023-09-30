CREATE PROCEDURE dbo.spEM_CreateDataSource
  @Description  nvarchar(50),
  @User_Id int,
  @Data_Source_Id int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create data type.
  --
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateDataSource',
                 @Description + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  INSERT INTO Data_Source(Active,DS_Desc,Bulk_Import) VALUES(1,@Description,0)
  SELECT @Data_Source_Id = Scope_Identity()
  IF @Data_Source_Id IS NULL
 	 BEGIN
 	    Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	    RETURN(1)
 	 END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Data_Source_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
