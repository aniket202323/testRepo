CREATE PROCEDURE dbo.spEM_PutTransMetricPropValues
  @Trans_Id  int,
  @Spec_Id   int,
  @Char_Id   int,
  @L_Entry   nvarchar(25),
  @L_Reject  nvarchar(25),
  @L_Warning nvarchar(25),
  @L_User    nvarchar(25),
  @Target    nvarchar(25),
  @U_User    nvarchar(25),
  @U_Warning nvarchar(25),
  @U_Reject  nvarchar(25),
  @U_Entry   nvarchar(25),
  @Sig 	  	  int,
  @As_Id 	  	  Int,
  @Effective_Date 	 DateTime,
  @User_Id int
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Id 	  	  	 int,
 	       @Insert_Id 	  	 integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTransMetricPropValues',
                SUBSTRING(Convert(nVarChar(10),@Trans_Id) + ','  + 
                Convert(nVarChar(10),@Spec_Id) + ','  + 
                Convert(nVarChar(10),@Char_Id) + ','  + 
                Convert(nVarChar(10),@As_Id) + ','  + 
                Convert(nVarChar(10),@User_Id),1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Try to find a matching transaction property.
  --
  SELECT @Id = Trans_Id FROM Trans_Metric_Properties
    WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (AS_Id = @AS_Id)
  --
  -- If a matching transaction property was found, update it. Otherwise,
  -- insert a new transaction property. In the special case where all the
  -- limits are null, delete any transaction property we find.
  --
  IF (@L_Entry IS NULL) AND (@L_Reject IS NULL) AND (@L_Warning IS NULL) AND (@L_User IS NULL) AND
     (@Target IS NULL) AND (@U_User IS NULL) AND (@U_Warning IS NULL) AND (@U_Reject IS NULL) AND
     (@U_Entry IS NULL) AND (@Sig Is Null)
    BEGIN
      IF @Id IS NOT NULL
        DELETE FROM Trans_Metric_Properties
          WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (AS_Id = @AS_Id)
    END
  ELSE IF @Id IS NULL 
    INSERT INTO Trans_Metric_Properties(Trans_Id, Spec_Id, Char_Id, Target, L_Entry, L_Reject,
      L_Warning, L_User, U_User, U_Warning, U_Reject, U_Entry, Esignature_Level,AS_Id,Effective_Date)
    VALUES(@Trans_Id, @Spec_Id, @Char_Id, @Target, @L_Entry, @L_Reject,
      @L_Warning, @L_User, @U_User, @U_Warning, @U_Reject, @U_Entry,@Sig,@AS_Id,@Effective_Date)
  ELSE
    UPDATE Trans_Metric_Properties
      SET L_Entry    = @L_Entry,
          L_Reject   = @L_Reject,
          L_Warning  = @L_Warning,
          L_User     = @L_User,
          Target     = @Target,
          U_User     = @U_User,
          U_Warning  = @U_Warning,
          U_Reject   = @U_Reject,
          U_Entry    = @U_Entry,
 	  	   Esignature_Level = @Sig,
          Effective_Date = @Effective_Date
      WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (AS_Id = @AS_Id)
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
