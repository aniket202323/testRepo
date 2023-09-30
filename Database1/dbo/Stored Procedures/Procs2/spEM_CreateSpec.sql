CREATE PROCEDURE dbo.spEM_CreateSpec
  @Spec_Desc      nvarchar(50),
  @Prop_Id        int,
  @Data_Type_Id   int,
  @Spec_Precision Tinyint_Precision,
  @User_Id int,
  @Spec_Id        int OUTPUT,
  @Spec_Order     int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create specification.
  --
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSpec',
                @Spec_Desc + ','  + convert(nVarChar(10),@Prop_Id) + ','  + Convert(nVarChar(10), @Data_Type_Id)  + ','  + Convert(nVarChar(10),  @Spec_Precision) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  --  Add To Bottom
  --
  DECLARE @Max_Number           int
  --
  SELECT @Spec_Order = MAX(Spec_Order) + 1  FROM Specifications WHERE Prop_Id = @Prop_Id
  IF @Spec_Order IS NULL 
 	 SELECT @Spec_Order = 1
 	 INSERT INTO Specifications(Spec_Desc_Local,Prop_Id,Data_Type_Id,Spec_Precision,Spec_Order)
 	  	 VALUES(@Spec_Desc,@Prop_Id,@Data_Type_Id,@Spec_Precision,@Spec_Order)
  SELECT @Spec_Id = Spec_Id From Specifications Where Spec_Desc = @Spec_Desc And Prop_Id = @Prop_Id
  IF @Spec_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Update Specifications set Spec_Desc_Global = Spec_Desc_Local where Spec_Id = @Spec_Id
 	   End
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Spec_Id) + convert(nVarChar(10),@Spec_Order)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
