Create Procedure dbo.spEM_ApproveTrans_Slave1
  @Char_Id int,
  @Spec_Id int,
  @Effective_Date datetime,
  @Expiration_Date datetime,
  @L_Entry  	  	 nvarchar(25),
  @L_Reject  	 nvarchar(25),
  @L_Warning  	 nvarchar(25),
  @L_User  	  	 nvarchar(25),
  @Target  	  	 nvarchar(25),
  @U_User  	  	 nvarchar(25),
  @U_Warning  	 nvarchar(25),
  @U_Reject  	 nvarchar(25),
  @U_Entry  	  	 nvarchar(25),
  @L_Control 	 nvarchar(25),
  @T_Control 	 nvarchar(25),
  @U_Control 	 nvarchar(25),
  @Test_Freq int,
  @Esignature_Level Int,
  @Comment_Id int,
  @IsDefined Int,
  @AS_Id int OUTPUT
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  INSERT INTO Active_Specs(Char_Id, Spec_Id, Effective_Date, Expiration_Date,
                           L_Entry, L_Reject, L_Warning, L_User, Target, U_User,
                           U_Warning, U_Reject, U_Entry, L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Is_Defined)
    VALUES(@Char_Id, @Spec_Id, @Effective_Date, @Expiration_Date,
           @L_Entry, @L_Reject, @L_Warning, @L_User, @Target, @U_User,
           @U_Warning, @U_Reject, @U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Esignature_Level,@Comment_Id,@IsDefined)
  SELECT @AS_Id = Scope_Identity()
