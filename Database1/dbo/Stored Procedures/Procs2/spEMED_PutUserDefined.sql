CREATE PROCEDURE dbo.spEMED_PutUserDefined 
  @DefaultValue 	  	   nvarchar(1000),
  @Locked 	  	  	   Bit,
  @Optional 	  	  	   Bit,
  @Field_Type_Id  	   Int,
  @Field_Desc 	  	   nvarchar(255),
  @ModelId 	  	  	   Int,
  @UserId  	  	  	   Int,
  @ED_Field_Prop_Id   int Output
  AS
DECLARE @Insert_Id integer, @OLDED_Field_Prop_Id Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMED_PutUserDefined',
 	  	 Coalesce(LTRIM(RTRIM(@DefaultValue)),'null') + ',' +
 	  	 Convert(nVarChar(1),@Locked) + ','  + 
 	  	 Convert(nVarChar(1),@Optional) + ','  + 
 	  	 Convert(nVarChar(10),@Field_Type_Id) + ','  + 
 	  	 LTRIM(RTRIM(@Field_Desc)) + ','  + 
 	  	 Convert(nVarChar(10),@ModelId) + ','  + 
 	  	 Convert(nVarChar(10),@UserId) + ',' + 
        Coalesce(Convert(nVarChar(10),@ED_Field_Prop_Id),'Null')
 	  	 , dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If @ED_Field_Prop_Id is null  -- insert
    Begin
 	   Select @OLDED_Field_Prop_Id = ED_Field_Prop_Id From ED_Field_Properties WHERE ED_Model_Id = @ModelId and  Field_Desc = @Field_Desc
 	   IF @OLDED_Field_Prop_Id is null
 	  	 Begin
 	  	   Insert Into ED_Field_Properties (ED_Model_Id,ED_Field_Type_Id,Default_Value,Field_Desc,Optional,Locked) 
 	  	     Values (@ModelId,@Field_Type_Id,@DefaultValue,@Field_Desc,@Optional,@Locked)
 	  	   Select @ED_Field_Prop_Id = Scope_Identity()
 	  	   Return (0)
 	  	 End
 	   Else
 	  	 Return (100)
    End
  SELECT @OLDED_Field_Prop_Id = ED_Field_Prop_Id From ED_Field_Properties WHERE ED_Field_Prop_Id = @ED_Field_Prop_Id
  If @OLDED_Field_Prop_Id is null
 	 return (100)
  Update ED_Field_Properties Set ED_Field_Type_Id = @Field_Type_Id,Default_Value = @DefaultValue,Field_Desc = @Field_Desc,Optional = @Optional,Locked = @Locked
 	 Where ED_Field_Prop_Id = @ED_Field_Prop_Id
  Return (0)
