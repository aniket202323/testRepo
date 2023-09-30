CREATE PROCEDURE dbo.spEM_PutSpecData
  @Spec_Id        int,
  @Data_Type_Id   int,
  @Spec_Precision Tinyint_Precision,
  @TagInfo 	  	   nvarchar(50),
  @Eng_Units 	   nvarchar(50),
  @User_Id  	  	   int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSpecData',
                Convert(nVarChar(10),@Spec_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Data_Type_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Spec_Precision) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes: 0 = success.
  --
  -- Update the specification.
  --
  UPDATE Specifications
    SET Data_Type_Id = @Data_Type_Id, Spec_Precision = @Spec_Precision,Tag = @TagInfo,Eng_Units = @Eng_Units
    WHERE Spec_Id = @Spec_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
