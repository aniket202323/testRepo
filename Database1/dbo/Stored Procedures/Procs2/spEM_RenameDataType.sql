CREATE PROCEDURE dbo.spEM_RenameDataType
  @Data_Type_Id int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameDataType',
                Convert(nVarChar(10),@Data_Type_Id) + ','  + 
                @Description + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Data_Type SET Data_Type_Desc = @Description WHERE Data_Type_Id = @Data_Type_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
