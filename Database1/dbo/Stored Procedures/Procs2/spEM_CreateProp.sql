CREATE PROCEDURE dbo.spEM_CreateProp
  @Prop_Desc nvarchar(50),
  @Prop_Type Int,
  @User_Id int,
  @Prop_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create property.
  --
DECLARE @Insert_Id integer
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProp',
                @Prop_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
 	 INSERT INTO Product_Properties(Prop_Desc_Local,Property_Type_Id) VALUES(@Prop_Desc,@Prop_Type)
  SELECT @Prop_Id = Prop_Id From Product_Properties Where Prop_Desc = @Prop_Desc
  IF @Prop_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Update Product_Properties set Prop_Desc_Global = Prop_Desc_Local where Prop_Id = @Prop_Id
 	   End
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Prop_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
