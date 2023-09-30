Create Procedure dbo.spEM_PutVarLookup
  @Var_Id        int,
  @Ext_Int_Key_1 int,
  @Ext_Int_Key_2 int,
  @Ext_Int_Key_3 int,
  @Ext_Str_Key_1 nvarchar(255),
  @Ext_Str_Key_2 nvarchar(255),
  @Ext_Str_Key_3 nvarchar(255),
  @User_Id int,
  @VL_Id         int OUTPUT
  AS
  --
  -- Return codes:
  --
  --   (0) Success
  --   (1) Error: Can't create variable lookup record.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutVarLookup',
                SUBSTRING(Convert(nVarChar(10),@Var_Id) + ','  + 
                Convert(nVarChar(10),@Ext_Int_Key_1) + ','  + 
                Convert(nVarChar(10),@Ext_Int_Key_2) + ','  + 
                Convert(nVarChar(10),@Ext_Int_Key_3) + ','  + 
 	    LTRIM(RTRIM(@Ext_Str_Key_1)) + ','  + 
 	    LTRIM(RTRIM(@Ext_Str_Key_2)) + ','  + 
 	    LTRIM(RTRIM(@Ext_Str_Key_3)) + ','  + 
 	    Convert(nVarChar(10),@User_Id),1,255),
              	    dbo.fnServer_CmnGetDate(getUTCdate()))
  IF (@Ext_Int_Key_1 IS NULL) AND
     (@Ext_Int_Key_2 IS NULL) AND
     (@Ext_Int_Key_3 IS NULL) AND
     (@Ext_Str_Key_1 IS NULL) AND
     (@Ext_Str_Key_2 IS NULL) AND
     (@Ext_Str_Key_3 IS NULL)
    BEGIN
      DELETE FROM Var_Lookup WHERE VL_Id = @VL_Id
      SELECT @VL_Id = NULL
    END
  ELSE IF @VL_Id IS NULL
    BEGIN
      BEGIN TRANSACTION
      INSERT INTO Var_Lookup(Var_Id,
                             Ext_Int_Key_1,
                             Ext_Int_Key_2,
                             Ext_Int_Key_3,
                             Ext_Str_Key_1,
                             Ext_Str_Key_2,
                             Ext_Str_Key_3)
        VALUES(@Var_Id,
               @Ext_Int_Key_1,
               @Ext_Int_Key_2,
               @Ext_Int_Key_3,
               @Ext_Str_Key_1,
               @Ext_Str_Key_2,
               @Ext_Str_Key_3)
      SELECT @VL_Id = Scope_Identity()
      IF @VL_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
      COMMIT TRANSACTION
    END
  ELSE
    UPDATE Var_Lookup
      SET Var_Id = @Var_Id,
          Ext_Int_Key_1 = @Ext_Int_Key_1,
          Ext_Int_Key_2 = @Ext_Int_Key_2,
          Ext_Int_Key_3 = @Ext_Int_Key_3,
          Ext_Str_Key_1 = @Ext_Str_Key_1,
          Ext_Str_Key_2 = @Ext_Str_Key_2,
          Ext_Str_Key_3 = @Ext_Str_Key_3
      WHERE VL_Id = @VL_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@VL_Id) 
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
